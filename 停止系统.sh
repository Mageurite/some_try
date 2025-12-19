#!/bin/bash

###############################################################################
# Virtual Tutor System 停止脚本
###############################################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PROJECT_ROOT="/workspace/virtual-tutor"
LOG_DIR="${PROJECT_ROOT}/logs"

echo -e "${YELLOW}======================================${NC}"
echo -e "${YELLOW}  停止 Virtual Tutor System${NC}"
echo -e "${YELLOW}======================================${NC}"
echo ""

# 停止函数
stop_service() {
    local service=$1
    local pid_file="${LOG_DIR}/${service}.pid"
    
    if [ -f "$pid_file" ]; then
        local pid=$(cat "$pid_file")
        if ps -p $pid > /dev/null 2>&1; then
            echo -e "${YELLOW}停止 ${service} (PID: ${pid})...${NC}"
            kill $pid
            sleep 2
            if ps -p $pid > /dev/null 2>&1; then
                echo -e "${RED}强制停止 ${service}...${NC}"
                kill -9 $pid
            fi
            rm -f "$pid_file"
            echo -e "${GREEN}${service} 已停止${NC}"
        else
            echo -e "${YELLOW}${service} 未运行${NC}"
            rm -f "$pid_file"
        fi
    else
        echo -e "${YELLOW}未找到 ${service} PID 文件${NC}"
    fi
}

# 停止所有服务
stop_service "backend"
stop_service "frontend"
stop_service "rag"
stop_service "tts"
stop_service "llm"
stop_service "ollama"

# 额外清理
echo ""
echo -e "${YELLOW}清理残留进程...${NC}"

# 清理可能的 Node.js 进程
pkill -f "react-scripts start" 2>/dev/null || true

# 清理可能的 Python 进程
pkill -f "run.py" 2>/dev/null || true
pkill -f "app.py" 2>/dev/null || true
pkill -f "api_interface.py" 2>/dev/null || true

echo ""
echo -e "${GREEN}所有服务已停止！${NC}"

