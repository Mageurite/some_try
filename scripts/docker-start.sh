#!/bin/bash

# 虚拟导师系统 - Docker混合启动脚本
# 轻量级服务用Docker，重量级服务在主机运行

set -e

echo "============================================="
echo "  虚拟导师系统 - Docker混合启动"
echo "============================================="
echo ""

# 检查Docker是否运行
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker未运行，请先启动Docker"
    exit 1
fi

# 检查docker-compose是否存在
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose未安装"
    exit 1
fi

echo "📦 启动轻量级Docker服务..."
echo ""

# 启动Docker服务（Backend, Frontend, Redis, TTS）
docker-compose -f docker-compose.lite.yml up -d

echo ""
echo "✅ Docker服务启动成功！"
echo ""
echo "🐳 Docker服务状态:"
docker-compose -f docker-compose.lite.yml ps

echo ""
echo "============================================="
echo "  现在需要手动启动重量级服务"
echo "============================================="
echo ""

echo "📝 请在新终端中运行以下命令："
echo ""

echo "1️⃣  RAG服务 (端口 8602):"
echo "   cd $(pwd)/rag"
echo "   conda activate rag"
echo "   python app.py > /tmp/rag.log 2>&1 &"
echo ""

echo "2️⃣  LLM服务 (端口 8610):"
echo "   cd $(pwd)/llm"
echo "   conda activate llm"  
echo "   python api_interface.py > /tmp/llm.log 2>&1 &"
echo ""

echo "3️⃣  Lip-sync服务 (端口 8615, 需要GPU):"
echo "   cd $(pwd)/lip-sync"
echo "   conda activate avatar"
echo "   export TORCH_HOME=/workspace/temp"
echo "   export HF_HOME=/workspace/temp"
echo "   export TRANSFORMERS_CACHE=/workspace/temp"
echo "   python3 app.py --transport webrtc --model musetalk --avatar_id test_yongen \\"
echo "     --max_session 8 --listenport 8615 --tts cosyvoice \\"
echo "     --TTS_SERVER http://127.0.0.1:8604 \\"
echo "     --REF_FILE ref_audio/silence.wav \\"
echo "     --REF_TEXT 'hello this is tutorNet speaking' \\"
echo "     > /tmp/lipsync.log 2>&1 &"
echo ""

echo "============================================="
echo "  服务端口"
echo "============================================="
echo "  Frontend:   http://localhost:3002"
echo "  Backend:    http://localhost:8203"
echo "  Redis:      localhost:6379"
echo "  TTS:        http://localhost:8604"
echo "  RAG:        http://localhost:8602 (需手动启动)"
echo "  LLM:        http://localhost:8610 (需手动启动)"
echo "  Lip-sync:   http://localhost:8615 (需手动启动)"
echo "============================================="
echo ""

echo "💡 提示："
echo "   - 查看Docker日志: docker-compose -f docker-compose.lite.yml logs -f"
echo "   - 停止Docker服务: docker-compose -f docker-compose.lite.yml down"
echo "   - 查看容器状态: docker-compose -f docker-compose.lite.yml ps"
echo ""






