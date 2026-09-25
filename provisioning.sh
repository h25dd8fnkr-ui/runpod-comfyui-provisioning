#!/bin/bash

set -e

echo "=============================================="
echo " Z-IMAGE TURBO + MINIMAX H3 PROVISIONING"
echo "=============================================="

source /opt/ai-dock/etc/environment.sh
source /opt/ai-dock/bin/venv-set.sh comfyui

COMFY="/workspace/ComfyUI"

mkdir -p "$COMFY/models/diffusion_models"
mkdir -p "$COMFY/models/text_encoders"
mkdir -p "$COMFY/models/vae"
mkdir -p "$COMFY/models/loras"

download_model() {
    URL="$1"
    DEST="$2"

    if [ -f "$DEST" ]; then
        echo "EXISTS: $(basename "$DEST")"
        return
    fi

    echo "DOWNLOADING: $(basename "$DEST")"

    wget -c \
        --progress=bar:force:noscroll \
        "$URL" \
        -O "$DEST"

    echo "DONE: $(basename "$DEST")"
}

echo ""
echo "========== Z-IMAGE TURBO =========="

download_model \
"https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/diffusion_models/z_image_turbo_bf16.safetensors?download=true" \
"$COMFY/models/diffusion_models/z_image_turbo_bf16.safetensors"

download_model \
"https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/text_encoders/qwen_3_4b.safetensors?download=true" \
"$COMFY/models/text_encoders/qwen_3_4b.safetensors"

download_model \
"https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/vae/ae.safetensors?download=true" \
"$COMFY/models/vae/ae.safetensors"

echo ""
echo "========== MINIMAX H3 =========="

download_model \
"https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors?download=true" \
"$COMFY/models/diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors"

download_model \
"https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors?download=true" \
"$COMFY/models/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors"

download_model \
"https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_video_vae_int8_convrot.safetensors?download=true" \
"$COMFY/models/vae/minimax_h3_video_vae_int8_convrot.safetensors"

download_model \
"https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_audio_vae_fp32.safetensors?download=true" \
"$COMFY/models/vae/minimax_h3_audio_vae_fp32.safetensors"

download_model \
"https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors?download=true" \
"$COMFY/models/loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors"

echo ""
echo "=============================================="
echo " ALL MODELS DOWNLOADED"
echo "=============================================="

provisioning_print_end
