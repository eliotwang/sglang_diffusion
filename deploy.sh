#!/bin/bash
# 遇到错误立即停止
set -e

echo "========== 1. 环境准备 =========="
SGLANG_DIR="/home/amd/heyi/dcc/git_test/sglang"
GITHUB_REPO="https://github.com/eliotwang/sglang_diffusion.git"
echo "正在清理并创建工作目录: $SGLANG_DIR"
rm -rf "$SGLANG_DIR" && mkdir -p "$SGLANG_DIR"

git clone "$GITHUB_REPO" "$SGLANG_DIR"

echo "========== 2. 容器清理 =========="
# 如果容器已存在，强行删除
if [ "$(docker ps -aq -f name=dcc_test)" ]; then
    echo "正在删除旧容器 dcc_test..."
    docker rm -f dcc_test
fi

docker run --rm \
    --ipc=host \
    --network host \
    --dns 8.8.8.8 \
    -v "$SGLANG_DIR:/workspace" \
    --device=/dev/kfd \
    --device=/dev/dri \
    --security-opt seccomp=unconfined \
    --cap-add=SYS_PTRACE \
    --group-add video \
    --name dcc_test \
    lmsysorg/sglang:v0.5.6.post2-rocm700-mi30x \
    bash -c '
        set -e
        cd /workspace
        pip install uv
        uv pip install --no-build-isolation -e "python[diffusion]" --no-deps --pre 
        pip install remote_pdb diffusers

        echo "========== 开始执行测试 =========="
        sglang generate --model-path Qwen/Qwen-Image --prompt "A cute baby sea otter"   --save-output
        echo "========== 测试完成 =========="
    '
