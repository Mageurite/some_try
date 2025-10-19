#!/bin/bash

echo "🚀 Starting Virtual Tutor System..."
echo "===================================="
echo ""

# 检查必需的conda环境
check_conda_env() {
    local env_name=$1
    if ! conda env list | grep -q "^${env_name} "; then
        echo "❌ Conda环境 '${env_name}' 不存在"
        return 1
    fi
    return 0
}

# 项目根目录
PROJECT_ROOT="/workspace/murphy/capstone-project-25t3-9900-virtual-tutor-phase-2"

# 创建日志目录
LOG_DIR="${PROJECT_ROOT}/logs"
mkdir -p "${LOG_DIR}"
echo "📁 日志目录: ${LOG_DIR}"
echo ""

# 初始化conda
if [ -f /workspace/conda/etc/profile.d/conda.sh ]; then
    source /workspace/conda/etc/profile.d/conda.sh
else
    echo "❌ Conda未找到"
    exit 1
fi

echo "📋 检查Conda环境..."
REQUIRED_ENVS=("bread" "rag" "edge" "avatar")
for env in "${REQUIRED_ENVS[@]}"; do
    if check_conda_env "$env"; then
        echo "  ✅ $env"
    else
        echo "  ❌ $env (缺失)"
    fi
done
echo ""

# 1. 启动Backend服务
echo "1️⃣  启动Backend服务 (端口 8203)..."
cd "${PROJECT_ROOT}/backend"
conda activate bread
nohup python run.py > "${LOG_DIR}/backend.log" 2>&1 &
BACKEND_PID=$!
echo "   ✅ Backend启动中 (PID: $BACKEND_PID)"
sleep 2

# 2. 启动RAG服务（知识库检索）
echo "2️⃣  启动RAG服务 (端口 8602)..."
cd "${PROJECT_ROOT}/rag"
conda activate rag
nohup python app.py > "${LOG_DIR}/rag.log" 2>&1 &
RAG_PID=$!
echo "   ✅ RAG启动中 (PID: $RAG_PID)"
sleep 2

# 3. 启动LLM服务（对话生成，使用rag环境）
echo "3️⃣  启动LLM服务 (端口 8610)..."
cd "${PROJECT_ROOT}/llm"
conda activate rag
export TAVILY_API_KEY="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"
export MILVUS_API_BASE_URL="http://localhost:8601"
nohup python api_interface.py > "${LOG_DIR}/llm.log" 2>&1 &
LLM_PID=$!
echo "   ✅ LLM启动中 (PID: $LLM_PID)"
sleep 2

# 4. 启动Edge TTS服务（默认TTS，会根据Avatar自动切换）
echo "4️⃣  启动Edge TTS服务 (端口 8604)..."
echo "   ℹ️  注意：系统会根据Avatar配置自动切换TTS模型"
cd "${PROJECT_ROOT}/tts/edge"
conda activate edge
nohup python server.py --model_name edgeTTS --port 8604 --use_gpu false > "${LOG_DIR}/edge_tts.log" 2>&1 &
TTS_PID=$!
echo "   ✅ Edge TTS启动中 (PID: $TTS_PID)"
echo "   💡 教师创建Avatar时选择的TTS模型会被自动保存"
echo "   💡 学生使用Avatar时会自动切换到对应的TTS服务"
sleep 2

# 5. 启动Avatar管理服务
echo "5️⃣  启动Avatar管理服务 (端口 8606)..."
cd "${PROJECT_ROOT}/lip-sync"
conda activate avatar
nohup python live_server.py > "${LOG_DIR}/avatar_manager.log" 2>&1 &
AVATAR_MGR_PID=$!
echo "   ✅ Avatar管理服务启动中 (PID: $AVATAR_MGR_PID)"
sleep 2

# 6. 启动Lip-sync服务（需要较长时间加载模型）
echo "6️⃣  启动Lip-sync服务 (端口 8615)..."
echo "   ⚠️  注意：模型加载需要1-2分钟，请耐心等待"
echo "   💡 TTS会根据Avatar自动切换，无需手动配置"
echo "   ℹ️  不直接启动app.py，而是通过Avatar管理服务API启动"
echo "   ℹ️  这样避免多个app.py进程冲突"
# 不再直接启动 app.py，改为通过 live_server.py 的 API 启动
# nohup python3 app.py > /tmp/lipsync.log 2>&1 &
# LIPSYNC_PID=$!
echo "   ⏭️  跳过直接启动app.py，请使用Avatar管理API启动"
echo "   💡 使用方法: curl -X POST 'http://localhost:8606/switch_avatar?avatar_id=yongen&ref_file=ref_audio/silence.wav'"
sleep 1

# 7. 启动Frontend
echo "7️⃣  启动Frontend (端口 3000)..."
cd "${PROJECT_ROOT}/frontend"
npm start > "${LOG_DIR}/frontend.log" 2>&1 &
FRONTEND_PID=$!
echo "   ✅ Frontend启动中 (PID: $FRONTEND_PID)"

echo ""
echo "===================================="
echo "⏳ 等待服务启动..."
sleep 5

echo ""
echo "📊 检查服务状态..."
echo ""

# 检查端口
check_port() {
    local port=$1
    local name=$2
    if lsof -i :$port > /dev/null 2>&1; then
        echo "  ✅ $name (端口 $port)"
        return 0
    else
        echo "  ❌ $name (端口 $port) - 未运行"
        return 1
    fi
}

check_port 8203 "Backend"
check_port 8602 "RAG"
check_port 8610 "LLM"
check_port 8604 "Edge TTS"
check_port 8606 "Avatar管理"
echo "  ⏭️  Lip-sync (端口 8615) - 需要通过API手动启动"
check_port 3000 "Frontend"

echo ""
echo "===================================="
echo "🌐 服务访问地址："
echo "  Frontend:    http://localhost:3000"
echo "  Backend:     http://localhost:8203"
echo "  Avatar管理:  http://localhost:8606"
echo "===================================="
echo ""
echo "⚠️  重要：Avatar服务启动方式已改进"
echo "  ❌ 不再使用 start_all.sh 直接启动 app.py"
echo "  ✅ 改为通过 Avatar管理服务API 启动"
echo ""
echo "🚀 启动Avatar服务："
echo "  方法1: 使用API"
echo "    curl -X POST 'http://localhost:8606/switch_avatar?avatar_id=yongen&ref_file=ref_audio/silence.wav'"
echo ""
echo "  方法2: 使用前端界面"
echo "    访问 http://localhost:3000 选择Avatar"
echo ""
echo "  方法3: 使用测试脚本"
echo "    cd lip-sync && python test_switch.py yongen"
echo ""
echo "💡 TTS自动切换功能："
echo "  ✅ 教师端创建Avatar时会保存TTS配置"
echo "  ✅ 学生端使用Avatar时会自动切换TTS"
echo "  ℹ️  当前运行: Edge TTS (默认)"
echo "  ℹ️  系统会根据Avatar需求自动切换到其他TTS模型"
echo ""
echo "💡 为什么这样改？"
echo "  ❌ 旧方式：start_all.sh直接启动app.py，导致多个进程冲突"
echo "  ✅ 新方式：通过API启动，自动管理进程，避免冲突"
echo ""
echo "📝 查看日志："
echo "  所有日志位置: ${LOG_DIR}/"
echo ""
echo "  单个服务日志:"
echo "    tail -f ${LOG_DIR}/backend.log"
echo "    tail -f ${LOG_DIR}/rag.log"
echo "    tail -f ${LOG_DIR}/llm.log"
echo "    tail -f ${LOG_DIR}/edge_tts.log"
echo "    tail -f ${LOG_DIR}/avatar_manager.log"
echo "    tail -f ${LOG_DIR}/frontend.log"
echo ""
echo "  查看所有日志:"
echo "    tail -f ${LOG_DIR}/*.log"
echo ""
echo "  清理日志:"
echo "    rm ${LOG_DIR}/*.log"
echo ""
echo "🧪 测试TTS自动切换："
echo "  python3 verify_tts_auto_switch.py"
echo "  ./test_tts_switch.sh"
echo ""
echo "🛑 停止所有服务："
echo "  ./stop_all.sh"
echo ""
echo "✅ 所有服务启动完成！"
echo ""

