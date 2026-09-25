#!/bin/bash

set -Eeuo pipefail

echo "============================================================"
echo " Z-IMAGE TURBO + MINIMAX H3"
echo " RUNPOD / AI-DOCK PROVISIONING"
echo "============================================================"

# ------------------------------------------------------------
# AI-Dock environment
# ------------------------------------------------------------

source /opt/ai-dock/etc/environment.sh
source /opt/ai-dock/bin/venv-set.sh comfyui

COMFY="/workspace/ComfyUI"

# ------------------------------------------------------------
# Directories
# ------------------------------------------------------------

mkdir -p "$COMFY/models/diffusion_models"
mkdir -p "$COMFY/models/text_encoders"
mkdir -p "$COMFY/models/vae"
mkdir -p "$COMFY/models/loras"

echo ""
echo "ComfyUI directory:"
echo "$COMFY"

echo ""
echo "Model directories created."

# ------------------------------------------------------------
# Error handler
# ------------------------------------------------------------

trap '
echo ""
echo "============================================================"
echo " PROVISIONING FAILED"
echo " Line: $LINENO"
echo " Command: $BASH_COMMAND"
echo "============================================================"
exit 1
' ERR


# ------------------------------------------------------------
# Download function
# ------------------------------------------------------------

download_model() {

    local URL="$1"
    local DEST="$2"
    local NAME

    NAME="$(basename "$DEST")"

    mkdir -p "$(dirname "$DEST")"

    echo ""
    echo "============================================================"
    echo " MODEL: $NAME"
    echo " DEST:  $DEST"
    echo "============================================================"

    # --------------------------------------------------------
    # Completed marker
    # --------------------------------------------------------

    if [ -f "${DEST}.complete" ] && [ -s "$DEST" ]; then

        echo "STATUS: COMPLETE"
        ls -lh "$DEST"

        return 0
    fi

    # --------------------------------------------------------
    # Existing partial file
    # --------------------------------------------------------

    if [ -f "$DEST" ] && [ ! -f "${DEST}.complete" ]; then

        echo "STATUS: PARTIAL / INCOMPLETE"
        echo "Resuming download..."

    else

        echo "STATUS: NEW DOWNLOAD"

    fi

    # --------------------------------------------------------
    # Download
    # --------------------------------------------------------

    wget \
        -c \
        --tries=10 \
        --timeout=60 \
        --waitretry=5 \
        --retry-on-http-error=429,500,502,503,504 \
        --progress=bar:force:noscroll \
        "$URL" \
        -O "$DEST"

    # --------------------------------------------------------
    # Basic validation
    # --------------------------------------------------------

    if [ ! -s "$DEST" ]; then

        echo ""
        echo "ERROR: Download produced an empty file:"
        echo "$DEST"

        exit 1
    fi

    # --------------------------------------------------------
    # Mark complete ONLY after wget succeeded
    # --------------------------------------------------------

    touch "${DEST}.complete"

    echo ""
    echo "STATUS: COMPLETE"
    ls -lh "$DEST"
}


# ============================================================
# Z-IMAGE TURBO
# ============================================================

echo ""
echo "============================================================"
echo " Z-IMAGE TURBO"
echo "============================================================"

# ------------------------------------------------------------
# Z-Image Turbo diffusion model
# ------------------------------------------------------------

download_model \
"https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/diffusion_models/z_image_turbo_bf16.safetensors?download=true" \
"$COMFY/models/diffusion_models/z_image_turbo_bf16.safetensors"


# ------------------------------------------------------------
# Z-Image Turbo text encoder
# ------------------------------------------------------------

download_model \
"https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/text_encoders/qwen_3_4b.safetensors?download=true" \
"$COMFY/models/text_encoders/qwen_3_4b.safetensors"


# ------------------------------------------------------------
# Z-Image Turbo VAE
# ------------------------------------------------------------

download_model \
"https://huggingface.co/Comfy-Org/z_image_turbo/resolve/main/split_files/vae/ae.safetensors?download=true" \
"$COMFY/models/vae/ae.safetensors"


# ============================================================
# MINIMAX H3
# ============================================================

echo ""
echo "============================================================"
echo " MINIMAX H3"
echo "============================================================"

# ------------------------------------------------------------
# MiniMax H3 Ref2VA diffusion model
# ------------------------------------------------------------

download_model \
"https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors?download=true" \
"$COMFY/models/diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors"


# ------------------------------------------------------------
# MiniMax H3 Qwen3-VL 32B NVFP4 text encoder
# ------------------------------------------------------------

download_model \
"https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors?download=true" \
"$COMFY/models/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors"


# ------------------------------------------------------------
# MiniMax H3 video VAE
# ------------------------------------------------------------

download_model \
"https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_video_vae_int8_convrot.safetensors?download=true" \
"$COMFY/models/vae/minimax_h3_video_vae_int8_convrot.safetensors"


# ------------------------------------------------------------
# MiniMax H3 audio VAE
# ------------------------------------------------------------

download_model \
"https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/vae/minimax_h3_audio_vae_fp32.safetensors?download=true" \
"$COMFY/models/vae/minimax_h3_audio_vae_fp32.safetensors"


# ------------------------------------------------------------
# MiniMax H3 Ref2V Turbo LoRA
# ------------------------------------------------------------

download_model \
"https://huggingface.co/Comfy-Org/MiniMax-H3/resolve/main/loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors?download=true" \
"$COMFY/models/loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors"


# ============================================================
# FINAL VERIFICATION
# ============================================================

echo ""
echo "============================================================"
echo " FINAL MODEL CHECK"
echo "============================================================"

MODELS=(
    "$COMFY/models/diffusion_models/z_image_turbo_bf16.safetensors"
    "$COMFY/models/text_encoders/qwen_3_4b.safetensors"
    "$COMFY/models/vae/ae.safetensors"

    "$COMFY/models/diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors"
    "$COMFY/models/text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors"
    "$COMFY/models/vae/minimax_h3_video_vae_int8_convrot.safetensors"
    "$COMFY/models/vae/minimax_h3_audio_vae_fp32.safetensors"
    "$COMFY/models/loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors"
)

FAILED=0

for MODEL in "${MODELS[@]}"; do

    if [ -s "$MODEL" ] && [ -f "${MODEL}.complete" ]; then

        echo "OK      $(basename "$MODEL")"

    else

        echo "MISSING $(basename "$MODEL")"
        FAILED=1

    fi

done


if [ "$FAILED" -ne 0 ]; then

    echo ""
    echo "============================================================"
    echo " MODEL VERIFICATION FAILED"
    echo "============================================================"

    exit 1
fi


# ============================================================
# SUMMARY
# ============================================================

echo ""
echo "============================================================"
echo " ALL MODELS READY"
echo "============================================================"

echo ""
echo "Z-IMAGE TURBO:"
echo "  diffusion_models/z_image_turbo_bf16.safetensors"
echo "  text_encoders/qwen_3_4b.safetensors"
echo "  vae/ae.safetensors"

echo ""
echo "MINIMAX H3:"
echo "  diffusion_models/minimax_h3_ref2va_pruned_int8_convrot.safetensors"
echo "  text_encoders/qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors"
echo "  vae/minimax_h3_video_vae_int8_convrot.safetensors"
echo "  vae/minimax_h3_audio_vae_fp32.safetensors"
echo "  loras/minimax_h3_ref2v_turbo_4step_v0.1_comfyui_bf16.safetensors"

echo ""
echo "============================================================"
echo " PROVISIONING COMPLETE"
echo "============================================================"

provisioning_print_end
