#!/bin/bash

###############################################################################
# Virtual Tutor System 启动脚本
# 版本: 12adf7e
# 用途: 一键启动所有服务
###############################################################################

set -e  # 遇到错误立即退出

# 初始化 conda
if [ -f "/opt/miniforge3/etc/profile.d/conda.sh" ]; then
    source /opt/miniforge3/etc/profile.d/conda.sh
elif [ -f "/opt/conda/etc/profile.d/conda.sh" ]; then
    source /opt/conda/etc/profile.d/conda.sh
fi

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="/workspace/virtual-tutor"
LOG_DIR="${PROJECT_ROOT}/logs"

# 创建日志目录
mkdir -p "${LOG_DIR}"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Virtual Tutor System 启动器${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

###############################################################################
# 函数定义
###############################################################################

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查端口是否被占用
check_port() {
    local port=$1
    if lsof -Pi :${port} -sTCP:LISTEN -t >/dev/null 2>&1 ; then
        return 0  # 端口被占用
    else
        return 1  # 端口空闲
    fi
}

# 等待端口启动
wait_for_port() {
    local port=$1
    local service=$2
    local max_wait=60
    local count=0
    
    log_info "等待 ${service} 在端口 ${port} 启动..."
    
    while [ $count -lt $max_wait ]; do
        if check_port $port; then
            log_info "${service} 已启动！"
            return 0
        fi
        sleep 1
        count=$((count + 1))
    done
    
    log_error "${service} 启动超时！"
    return 1
}

# 检查 conda 环境是否存在
check_conda_env() {
    local env_name=$1
    if conda env list | grep -q "^${env_name} "; then
        return 0  # 环境存在
    else
        return 1  # 环境不存在
    fi
}

###############################################################################
# 1. 检查系统依赖
###############################################################################

log_info "检查系统依赖..."

# 检查 conda
if ! command -v conda &> /dev/null; then
    log_error "未找到 conda，请先安装 Anaconda 或 Miniconda"
    exit 1
fi

# 检查 Node.js
if ! command -v node &> /dev/null; then
    log_error "未找到 Node.js，请先安装 Node.js ≥ 18"
    exit 1
fi

# 检查 npm
if ! command -v npm &> /dev/null; then
    log_error "未找到 npm，请检查 Node.js 安装"
    exit 1
fi

# 检查 Redis (可选)
if ! command -v redis-server &> /dev/null; then
    log_warn "未找到 Redis，部分功能可能受限"
fi

# 检查 Ollama (可选)
if ! command -v ollama &> /dev/null; then
    log_warn "未找到 Ollama，LLM 服务将无法启动"
fi

log_info "系统依赖检查完成！"
echo ""

###############################################################################
# 2. 启动 Backend Service (Flask)
###############################################################################

log_info "启动 Backend Service..."

cd "${PROJECT_ROOT}/backend"

# 检查/创建 conda 环境
if ! check_conda_env "bread1"; then
    log_warn "创建 bread1 环境..."
    conda create -n bread1 python=3.10 -y
fi

# 安装依赖
if [ ! -d "venv" ]; then
    log_info "安装 Backend 依赖..."
    conda run -n bread1 pip install -r requirements.txt
fi

# 初始化数据库
log_info "初始化数据库..."
conda run -n bread1 python db/init_db.py || log_warn "数据库初始化可能已完成"

# 启动 Backend
log_info "启动 Backend 服务 (端口 8203)..."
conda run -n bread1 python run.py > "${LOG_DIR}/backend.log" 2>&1 &
BACKEND_PID=$!
echo $BACKEND_PID > "${LOG_DIR}/backend.pid"

wait_for_port 8203 "Backend"

echo ""

###############################################################################
# 3. 启动 Frontend (React)
###############################################################################

log_info "启动 Frontend..."

cd "${PROJECT_ROOT}/frontend"

# 安装依赖
if [ ! -d "node_modules" ]; then
    log_info "安装 Frontend 依赖..."
    npm install
fi

# 启动 Frontend
log_info "启动 Frontend 服务 (端口 3000)..."
PORT=3000 npm start > "${LOG_DIR}/frontend.log" 2>&1 &
FRONTEND_PID=$!
echo $FRONTEND_PID > "${LOG_DIR}/frontend.pid"

wait_for_port 3000 "Frontend"

echo ""

###############################################################################
# 4. 启动 RAG Service
###############################################################################

log_info "启动 RAG Service..."

cd "${PROJECT_ROOT}/rag"

# 检查/创建 conda 环境
if ! check_conda_env "rag"; then
    log_warn "创建 rag 环境..."
    conda create -n rag python=3.12 -y
    conda run -n rag conda install -c conda-forge poppler -y
fi

# 安装依赖
conda run -n rag pip install -r requirements.txt > /dev/null 2>&1 || true

# 启动 RAG
log_info "启动 RAG 服务 (端口 9090)..."
conda run -n rag python app.py > "${LOG_DIR}/rag.log" 2>&1 &
RAG_PID=$!
echo $RAG_PID > "${LOG_DIR}/rag.pid"

wait_for_port 9090 "RAG"

echo ""

###############################################################################
# 5. 启动 TTS Service
###############################################################################

log_info "启动 TTS Service..."

cd "${PROJECT_ROOT}/tts"

# 检查是否有可用的 TTS 模型
if [ -d "edge" ]; then
    log_info "使用 EdgeTTS (轻量级)..."
    
    # 检查/创建 conda 环境
    if ! check_conda_env "tts_base"; then
        log_warn "创建 tts_base 环境..."
        conda create -n tts_base python=3.10 -y
        conda run -n tts_base pip install fastapi uvicorn edge-tts
    fi
    
    # 启动 TTS
    log_info "启动 TTS 服务 (端口 8204)..."
    conda run -n tts_base uvicorn tts:app --host 0.0.0.0 --port 8204 > "${LOG_DIR}/tts.log" 2>&1 &
    TTS_PID=$!
    echo $TTS_PID > "${LOG_DIR}/tts.pid"
    
    wait_for_port 8204 "TTS"
else
    log_warn "未找到 TTS 模型，跳过 TTS 服务"
fi

echo ""

###############################################################################
# 6. 启动 LLM Service (可选)
###############################################################################

if command -v ollama &> /dev/null; then
    log_info "启动 LLM Service..."
    
    cd "${PROJECT_ROOT}/llm"
    
    # 检查 Ollama 是否运行
    if ! pgrep -x ollama > /dev/null; then
        log_info "启动 Ollama 服务..."
        ollama serve > "${LOG_DIR}/ollama.log" 2>&1 &
        OLLAMA_PID=$!
        echo $OLLAMA_PID > "${LOG_DIR}/ollama.pid"
        sleep 5
    fi
    
    # 检查模型
    log_info "检查 Ollama 模型..."
    if ! ollama list | grep -q "llama3.1:8b"; then
        log_warn "未找到 llama3.1:8b，请手动运行: ollama pull llama3.1:8b-instruct-q4_K_M"
    fi
    
    # 安装依赖
    conda run -n bread1 pip install -r requirements.txt > /dev/null 2>&1 || true
    
    # 启动 LLM API
    log_info "启动 LLM 服务 (端口 8100)..."
    conda run -n bread1 python api_interface.py > "${LOG_DIR}/llm.log" 2>&1 &
    LLM_PID=$!
    echo $LLM_PID > "${LOG_DIR}/llm.pid"
    
    wait_for_port 8100 "LLM"
    
    echo ""
else
    log_warn "未安装 Ollama，跳过 LLM 服务"
fi

###############################################################################
# 7. 启动 Lip-Sync Service (需要 GPU)
###############################################################################

log_warn "Lip-Sync Service 需要 GPU 和特殊模型，请参考 lip-sync/README.md 手动启动"
log_info "如需启动 Lip-Sync，请运行:"
echo -e "  ${YELLOW}cd ${PROJECT_ROOT}/lip-sync${NC}"
echo -e "  ${YELLOW}conda activate nerfstream${NC}"
echo -e "  ${YELLOW}python live_server.py${NC}"

echo ""

###############################################################################
# 完成
###############################################################################

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  所有基础服务已启动！${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo -e "访问地址:"
echo -e "  🌐 Frontend:  ${BLUE}http://localhost:3000${NC}"
echo -e "  🔧 Backend:   ${BLUE}http://localhost:8203${NC}"
echo -e "  📚 RAG:       ${BLUE}http://localhost:9090${NC}"
echo -e "  🔊 TTS:       ${BLUE}http://localhost:8204${NC}"
if command -v ollama &> /dev/null; then
    echo -e "  🤖 LLM:       ${BLUE}http://localhost:8100${NC}"
fi
echo ""
echo -e "SSH 端口映射 (远程访问):"
echo -e "  ${YELLOW}ssh -p 32537 root@49.213.134.9 \\${NC}"
echo -e "  ${YELLOW}  -L 13000:localhost:3000 \\${NC}"
echo -e "  ${YELLOW}  -L 18203:localhost:8203 \\${NC}"
echo -e "  ${YELLOW}  -L 19090:localhost:9090 \\${NC}"
echo -e "  ${YELLOW}  -L 18204:localhost:8204 \\${NC}"
echo -e "  ${YELLOW}  -L 18100:localhost:8100${NC}"
echo ""
echo -e "日志位置: ${LOG_DIR}/"
echo -e "停止服务: ${GREEN}bash 停止系统.sh${NC}"
echo ""

