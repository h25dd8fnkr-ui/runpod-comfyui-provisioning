#!/usr/bin/env bash
set -euo pipefail

COMFY_DIR="${COMFY_DIR:-/workspace/ComfyUI}"
MODELS="${COMFY_DIR}/models"
export HF_HOME="${HF_HOME:-/workspace/.cache/huggingface}"
export HF_HUB_ENABLE_HF_TRANSFER="${HF_HUB_ENABLE_HF_TRANSFER:-1}"
export HF_HUB_DOWNLOAD_TIMEOUT="${HF_HUB_DOWNLOAD_TIMEOUT:-60}"
export PIP_CACHE_DIR="${PIP_CACHE_DIR:-/workspace/.cache/pip}"

mkdir -p "${COMFY_DIR}" "${MODELS}"/{diffusion_models,text_encoders,vae,loras,model_patches,embeddings} "${HF_HOME}" "${PIP_CACHE_DIR}"

echo "=== RunPod ComfyUI / Z-Image Turbo / MiniMax H3 provisioning ==="

# 1. Base ComfyUI
if [[ ! -f "${COMFY_DIR}/main.py" ]]; then
  rm -rf "${COMFY_DIR}"
  git clone --depth 1 https://github.com/Comfy-Org/ComfyUI.git "${COMFY_DIR}"
fi

cd "${COMFY_DIR}"

# Install ComfyUI dependencies without replacing the CUDA/Torch stack supplied by the image.
python3 -m pip install --upgrade pip huggingface_hub
python3 -m pip install -r requirements.txt

# Manager: useful for installing additional nodes later.
if [[ ! -d "${COMFY_DIR}/custom_nodes/comfyui-manager" ]]; then
  git clone --depth 1 https://github.com/Comfy-Org/ComfyUI-Manager \
    "${COMFY_DIR}/custom_nodes/comfyui-manager"
fi
python3 -m pip install -r "${COMFY_DIR}/custom_nodes/comfyui-manager/requirements.txt" || true

# DWPose / ControlNet preprocessors used by the user's video workflows.
if [[ ! -d "${COMFY_DIR}/custom_nodes/comfyui_controlnet_aux" ]]; then
  git clone --depth 1 https://github.com/Fannovel16/comfyui_controlnet_aux \
    "${COMFY_DIR}/custom_nodes/comfyui_controlnet_aux"
fi
python3 -m pip install -r "${COMFY_DIR}/custom_nodes/comfyui_controlnet_aux/requirements.txt" || true

# KJNodes: useful utilities for advanced video/reference workflows.
if [[ ! -d "${COMFY_DIR}/custom_nodes/ComfyUI-KJNodes" ]]; then
  git clone --depth 1 https://github.com/kijai/ComfyUI-KJNodes \
    "${COMFY_DIR}/custom_nodes/ComfyUI-KJNodes"
fi
if [[ -f "${COMFY_DIR}/custom_nodes/ComfyUI-KJNodes/requirements.txt" ]]; then
  python3 -m pip install -r "${COMFY_DIR}/custom_nodes/ComfyUI-KJNodes/requirements.txt" || true
fi

# 2. Helper: download one HF file only if the final file is missing.
hf_file() {
  local repo="$1"
  local remote="$2"
  local dest="$3"
  local parent
  parent="$(dirname "${dest}")"

  if [[ -f "${dest}" ]]; then
    echo "[SKIP] ${dest}"
    return 0
  fi

  mkdir -p "${parent}"
  echo "[GET ] ${repo}/${remote}"
  hf download "${repo}" "${remote}" \
    --local-dir "${parent}" \
    --max-workers 8

  # hf --local-dir preserves the repository path. Move the downloaded file
  # to the exact ComfyUI filename expected by the workflow.
  local downloaded="${parent}/${remote}"
  if [[ ! -f "${downloaded}" ]]; then
    echo "ERROR: expected downloaded file not found: ${downloaded}" >&2
    exit 1
  fi
  mv -f "${downloaded}" "${dest}"

  # Remove the local-dir metadata directory created by HF for this download
  # only when it is empty; model files themselves are left intact.
  find "${parent}" -type d -name ".cache" -prune -exec rm -rf {} + 2>/dev/null || true
}

# 3. Z-Image Turbo — quality baseline.
hf_file "Comfy-Org/z_image_turbo" \
  "split_files/diffusion_models/z_image_turbo_bf16.safetensors" \
  "${MODELS}/diffusion_models/z_image_turbo_bf16.safetensors"

hf_file "Comfy-Org/z_image_turbo" \
  "split_files/text_encoders/qwen_3_4b.safetensors" \
  "${MODELS}/text_encoders/qwen_3_4b.safetensors"

hf_file "Comfy-Org/z_image_turbo" \
  "split_files/vae/ae.safetensors" \
  "${MODELS}/vae/ae.safetensors"

hf_file "Comfy-Org/z_image_turbo" \
  "loras/z_image_turbo_distill_patch_lora_bf16.safetensors" \
  "${MODELS}/loras/z_image_turbo_distill_patch_lora_bf16.safetensors"

# 4. MiniMax H3 — complete practical pack:
#    FL2VA + REF2VA, quantized text encoder, audio/video VAE,
#    official turbo LoRAs, Fun ControlNet patch, all official embeddings.
H3="Comfy-Org/MiniMax-H3"

hf_file "${H3}" \
  "diffusion_models/minimax_h3_fl2va_pruned_int8_convrot.safetensors" \
  "${MODELS}/diffusion_models/minimax_h3_fl2va_pruned_int8_convrot.safetensors"

hf_file "${H3}" \
  "diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors" \
  "${MODELS}/diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors"

hf_file "${H3}" \
  "text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors" \
  "${MODELS}/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors"

hf_file "${H3}" \
  "vae/minimax_h3_video_vae_int8_convrot.safetensors" \
  "${MODELS}/vae/minimax_h3_video_vae_int8_convrot.safetensors"

hf_file "${H3}" \
  "vae/minimax_h3_audio_vae_fp32.safetensors" \
  "${MODELS}/vae/minimax_h3_audio_vae_fp32.safetensors"

hf_file "${H3}" \
  "loras/minimax_h3_fl2v_turbo_4step_v1.0_768p_comfyui_bf16.safetensors" \
  "${MODELS}/loras/minimax_h3_fl2v_turbo_4step_v1.0_768p_comfyui_bf16.safetensors"

hf_file "${H3}" \
  "loras/minimax_h3_fl2v_turbo_8step_v1.0_comfyui_bf16.safetensors" \
  "${MODELS}/loras/minimax_h3_fl2v_turbo_8step_v1.0_comfyui_bf16.safetensors"

hf_file "${H3}" \
  "loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors" \
  "${MODELS}/loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors"

hf_file "${H3}" \
  "model_patches/minimax_h3_fun_controlnet_union_pruned_int8_convrot.safetensors" \
  "${MODELS}/model_patches/minimax_h3_fun_controlnet_union_pruned_int8_convrot.safetensors"

for emb in \
  minimaxh3_art_is_explosion \
  minimaxh3_blooming_flowers \
  minimaxh3_bullet_time \
  minimaxh3_dark_magic \
  minimaxh3_fire_breath \
  minimaxh3_four_seasons \
  minimaxh3_kiss_camera \
  minimaxh3_spiral_ascent \
  minimaxh3_storm_magic \
  minimaxh3_truman_show
do
  hf_file "${H3}" \
    "embeddings/${emb}.safetensors" \
    "${MODELS}/embeddings/${emb}.safetensors"
done

# 5. Optional user LoRA directory. Put your own identity LoRAs here.
mkdir -p "${MODELS}/loras/user"

# 6. Environment report.
echo
echo "=== Environment ==="
python3 - <<'PY'
import torch
print("Torch:", torch.__version__)
print("Torch CUDA:", torch.version.cuda)
print("CUDA available:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("GPU:", torch.cuda.get_device_name(0))
    print("VRAM GiB:", round(torch.cuda.get_device_properties(0).total_memory / 1024**3, 2))
PY

echo
echo "=== Installed model files ==="
find "${MODELS}" -type f -name "*.safetensors" -printf "%p\n" | sort

echo
echo "=== Starting ComfyUI ==="
cd "${COMFY_DIR}"
exec python3 main.py --listen 0.0.0.0 --port 8188
