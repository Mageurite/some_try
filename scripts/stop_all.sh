#!/bin/bash

# ============================================
# Virtual Tutor System - 全面停止脚本
# ============================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 解析命令行参数
FORCE_MODE=false
CLEAN_LOGS=false
QUIET_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--force)
            FORCE_MODE=true
            shift
            ;;
        -c|--clean)
            CLEAN_LOGS=true
            shift
            ;;
        -q|--quiet)
            QUIET_MODE=true
            shift
            ;;
        -h|--help)
            echo "用法: $0 [选项]"
            echo ""
            echo "选项:"
            echo "  -f, --force    强制模式：立即使用 SIGKILL 停止所有进程"
            echo "  -c, --clean    自动清理日志文件"
            echo "  -q, --quiet    静默模式：减少输出"
            echo "  -h, --help     显示此帮助信息"
            echo ""
            echo "示例:"
            echo "  $0              # 正常停止（优雅关闭）"
            echo "  $0 -f           # 强制停止"
            echo "  $0 -f -c        # 强制停止并清理日志"
            echo "  $0 -q           # 静默模式停止"
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            echo "使用 -h 或 --help 查看帮助"
            exit 1
            ;;
    esac
done

if [ "$QUIET_MODE" = false ]; then
    echo "🛑 停止 Virtual Tutor System..."
    echo "===================================="
    if [ "$FORCE_MODE" = true ]; then
        echo -e "${YELLOW}⚡ 强制模式已启用${NC}"
    fi
    echo ""
fi

# 定义所有服务
declare -A SERVICES
SERVICES=(
    ["Frontend"]="react-scripts|node.*frontend:3000"
    ["Lip-sync"]="python3.*app.py.*musetalk|pt_main_t:8615"
    ["Avatar管理"]="live_server.py:8606"
    ["Edge TTS"]="edge.*server.py|tts.*server.py:8604"
    ["CosyVoice TTS"]="cosyvoice.*server.py:8605"
    ["LLM"]="python.*api_interface.py:8610"
    ["RAG"]="python.*app.py.*rag:8602"
    ["Backend"]="python.*run.py:8203"
)

# 停止单个服务的函数
stop_service() {
    local service_name=$1
    local pattern_port=$2
    local pattern=$(echo "$pattern_port" | cut -d: -f1)
    local port=$(echo "$pattern_port" | cut -d: -f2)
    
    if [ "$QUIET_MODE" = false ]; then
        echo -n "停止 ${service_name} (端口 ${port})..."
    fi
    
    # 查找进程 - 尝试多个模式
    local pids=""
    IFS='|' read -ra PATTERNS <<< "$pattern"
    for p in "${PATTERNS[@]}"; do
        local found_pids=$(pgrep -f "$p" 2>/dev/null)
        if [ -n "$found_pids" ]; then
            pids="$pids $found_pids"
        fi
    done
    
    # 去重
    pids=$(echo "$pids" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    
    if [ -z "$pids" ]; then
        if [ "$QUIET_MODE" = false ]; then
            echo -e " ${YELLOW}未运行${NC}"
        fi
        return 0
    fi
    
    if [ "$FORCE_MODE" = true ]; then
        # 强制模式：直接 SIGKILL
        for pid in $pids; do
            kill -9 $pid 2>/dev/null
        done
        sleep 1
    else
        # 优雅模式：先 SIGTERM，再 SIGKILL
        for pid in $pids; do
            kill $pid 2>/dev/null
        done
        sleep 2
        
        # 检查是否还在运行
        local still_running=false
        for pid in $pids; do
            if ps -p $pid > /dev/null 2>&1; then
                still_running=true
                kill -9 $pid 2>/dev/null
            fi
        done
        
        if [ "$still_running" = true ]; then
            sleep 1
        fi
    fi
    
    # 最终检查
    local success=true
    for pid in $pids; do
        if ps -p $pid > /dev/null 2>&1; then
            success=false
            break
        fi
    done
    
    if [ "$success" = true ]; then
        if [ "$QUIET_MODE" = false ]; then
            echo -e " ${GREEN}✅ 已停止${NC}"
        fi
        return 0
    else
        if [ "$QUIET_MODE" = false ]; then
            echo -e " ${RED}❌ 停止失败${NC}"
        fi
        return 1
    fi
}

# 按顺序停止所有服务
SERVICE_ORDER=("Frontend" "Lip-sync" "Avatar管理" "Edge TTS" "CosyVoice TTS" "LLM" "RAG" "Backend")

for service in "${SERVICE_ORDER[@]}"; do
    if [ -n "${SERVICES[$service]}" ]; then
        stop_service "$service" "${SERVICES[$service]}"
    fi
done

if [ "$QUIET_MODE" = false ]; then
    echo ""
    echo "⏳ 等待端口释放..."
fi
sleep 2

# 额外清理：通过端口强制清理
if [ "$FORCE_MODE" = true ]; then
    if [ "$QUIET_MODE" = false ]; then
        echo ""
        echo "🔍 通过端口强制清理残留进程..."
    fi
    
    PORTS=(3000 8615 8606 8605 8604 8610 8602 8203)
    for port in "${PORTS[@]}"; do
        PIDS=$(lsof -ti :$port 2>/dev/null)
        if [ -n "$PIDS" ]; then
            if [ "$QUIET_MODE" = false ]; then
                echo "  强制清理端口 $port 的进程..."
            fi
            echo "$PIDS" | xargs kill -9 2>/dev/null
        fi
    done
    sleep 1
fi

# 检查最终状态
if [ "$QUIET_MODE" = false ]; then
    echo ""
    echo "===================================="
    echo "📊 端口状态检查..."
    echo ""
fi

check_port_status() {
    local port=$1
    local name=$2
    
    if lsof -i :$port 2>/dev/null | grep -q LISTEN; then
        if [ "$QUIET_MODE" = false ]; then
            echo -e "  ${RED}❌ $name (端口 $port) - 仍在使用${NC}"
            lsof -i :$port 2>/dev/null | grep LISTEN | awk '{print "     PID:", $2, "进程:", $1}'
        fi
        return 1
    else
        if [ "$QUIET_MODE" = false ]; then
            echo -e "  ${GREEN}✅ $name (端口 $port) - 已释放${NC}"
        fi
        return 0
    fi
}

ALL_CLEAR=true
check_port_status 3000 "Frontend" || ALL_CLEAR=false
check_port_status 8615 "Lip-sync" || ALL_CLEAR=false
check_port_status 8606 "Avatar管理" || ALL_CLEAR=false
check_port_status 8605 "CosyVoice TTS" || ALL_CLEAR=false
check_port_status 8604 "Edge TTS" || ALL_CLEAR=false
check_port_status 8610 "LLM" || ALL_CLEAR=false
check_port_status 8602 "RAG" || ALL_CLEAR=false
check_port_status 8203 "Backend" || ALL_CLEAR=false

if [ "$QUIET_MODE" = false ]; then
    echo ""
    echo "===================================="
fi

# 总结
if [ "$ALL_CLEAR" = true ]; then
    if [ "$QUIET_MODE" = false ]; then
        echo -e "${GREEN}✅ 所有服务已成功停止！${NC}"
    fi
else
    if [ "$QUIET_MODE" = false ]; then
        echo -e "${YELLOW}⚠️  部分服务未完全停止${NC}"
        echo ""
        echo "建议尝试："
        echo "  1. 使用强制模式: $0 -f"
        echo "  2. 手动检查进程: ps aux | grep -E 'python|node|react'"
        echo "  3. 使用 sudo: sudo $0 -f"
    fi
fi

# 日志清理
if [ "$QUIET_MODE" = false ]; then
    echo ""
    echo "🧹 日志文件："
fi

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

LOG_FILES=(
    "$SCRIPT_DIR/logs/backend.log"
    "$SCRIPT_DIR/logs/rag.log"
    "$SCRIPT_DIR/logs/llm.log"
    "$SCRIPT_DIR/logs/edge_tts.log"
    "$SCRIPT_DIR/logs/avatar_manager.log"
    "$SCRIPT_DIR/logs/frontend.log"
    "$SCRIPT_DIR/backend/error.log"
    "$SCRIPT_DIR/rag/app.log"
    "$SCRIPT_DIR/lip-sync/live_server.log"
    "$SCRIPT_DIR/lip-sync/livetalking.log"
    "$SCRIPT_DIR/livetalking.log"
)

# 显示日志文件大小
if [ "$QUIET_MODE" = false ] && [ "$CLEAN_LOGS" = false ]; then
    for log in "${LOG_FILES[@]}"; do
        if [ -f "$log" ]; then
            SIZE=$(du -h "$log" 2>/dev/null | cut -f1)
            echo "  $log ($SIZE)"
        fi
    done
fi

# 处理日志清理
if [ "$CLEAN_LOGS" = true ]; then
    # 自动清理
    for log in "${LOG_FILES[@]}"; do
        rm -f "$log" 2>/dev/null
    done
    if [ "$QUIET_MODE" = false ]; then
        echo -e "${GREEN}✅ 日志已清理${NC}"
    fi
elif [ "$QUIET_MODE" = false ]; then
    # 询问是否清理
    echo ""
    read -p "是否清理日志文件? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        for log in "${LOG_FILES[@]}"; do
            rm -f "$log" 2>/dev/null
        done
        echo -e "${GREEN}✅ 日志已清理${NC}"
    else
        echo "日志已保留"
    fi
fi

if [ "$QUIET_MODE" = false ]; then
    echo ""
    echo "===================================="
    echo ""
    echo "💡 提示："
    echo "  - 正常停止: ./stop_all.sh"
    echo "  - 强制停止: ./stop_all.sh -f"
    echo "  - 静默模式: ./stop_all.sh -q"
    echo "  - 查看帮助: ./stop_all.sh -h"
    echo ""
fi

# 返回状态码
if [ "$ALL_CLEAR" = true ]; then
    exit 0
else
    exit 1
fi
