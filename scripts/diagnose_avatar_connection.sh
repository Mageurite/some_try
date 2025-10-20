#!/bin/bash

###############################################################################
# Avatar 连接问题诊断脚本
# 用于诊断 Avatar 切换后视频无法连接的问题
###############################################################################

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
WEBRTC_PORT=8615
BACKEND_PORT=8203
FRONTEND_PORT=3000

echo -e "${BLUE}========================================"
echo "Avatar 连接问题诊断工具"
echo "========================================${NC}"
echo ""

# 检查操作系统
OS_TYPE=$(uname -s)
echo -e "${BLUE}[1] 系统信息${NC}"
echo "操作系统: $OS_TYPE"
echo ""

# 函数：检查端口是否开放
check_port() {
    local port=$1
    local name=$2
    
    if [[ "$OS_TYPE" == "Darwin" ]] || [[ "$OS_TYPE" == "Linux" ]]; then
        if nc -z localhost $port 2>/dev/null; then
            echo -e "${GREEN}✓${NC} 端口 $port ($name) - 可访问"
            return 0
        else
            echo -e "${RED}✗${NC} 端口 $port ($name) - 不可访问"
            return 1
        fi
    else
        # Windows/其他系统
        echo -e "${YELLOW}?${NC} 端口 $port ($name) - 无法检测（请手动检查）"
        return 2
    fi
}

# 函数：检查 WebRTC 健康状态
check_webrtc_health() {
    local response=$(curl -s -w "\n%{http_code}" http://localhost:$WEBRTC_PORT/health 2>/dev/null)
    local http_code=$(echo "$response" | tail -n 1)
    local body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" = "200" ]; then
        echo -e "${GREEN}✓${NC} WebRTC 服务健康检查通过"
        echo "   响应: $body"
        return 0
    else
        echo -e "${RED}✗${NC} WebRTC 服务健康检查失败 (HTTP $http_code)"
        return 1
    fi
}

# 函数：检查 SSH 隧道
check_ssh_tunnel() {
    if [[ "$OS_TYPE" == "Darwin" ]] || [[ "$OS_TYPE" == "Linux" ]]; then
        local ssh_count=$(ps aux | grep "ssh.*$WEBRTC_PORT:localhost:$WEBRTC_PORT" | grep -v grep | wc -l)
        if [ $ssh_count -gt 0 ]; then
            echo -e "${GREEN}✓${NC} SSH 隧道运行中"
            ps aux | grep "ssh.*$WEBRTC_PORT:localhost:$WEBRTC_PORT" | grep -v grep | head -1
            return 0
        else
            echo -e "${RED}✗${NC} SSH 隧道未运行"
            return 1
        fi
    else
        echo -e "${YELLOW}?${NC} SSH 隧道状态 - 无法检测（请手动检查）"
        return 2
    fi
}

# 函数：检查服务器端进程（需要在服务器上运行）
check_server_process() {
    echo -e "${BLUE}提示:${NC} 此检查需要在服务器上运行"
    echo "远程检查命令: ps aux | grep 'app.py.*$WEBRTC_PORT' | grep -v grep"
}

# 开始诊断
echo -e "${BLUE}[2] 端口连接性检查${NC}"
check_port $FRONTEND_PORT "Frontend"
check_port $BACKEND_PORT "Backend"
WEBRTC_PORT_OK=0
check_port $WEBRTC_PORT "WebRTC" && WEBRTC_PORT_OK=1
echo ""

echo -e "${BLUE}[3] WebRTC 服务健康检查${NC}"
WEBRTC_HEALTH_OK=0
if [ $WEBRTC_PORT_OK -eq 1 ]; then
    check_webrtc_health && WEBRTC_HEALTH_OK=1
else
    echo -e "${YELLOW}⊘${NC} 跳过（端口不可访问）"
fi
echo ""

echo -e "${BLUE}[4] SSH 隧道检查${NC}"
SSH_TUNNEL_OK=0
check_ssh_tunnel && SSH_TUNNEL_OK=1
echo ""

echo -e "${BLUE}[5] 服务器端进程检查${NC}"
check_server_process
echo ""

# 诊断总结
echo -e "${BLUE}========================================"
echo "诊断总结"
echo "========================================${NC}"

ISSUE_FOUND=0

if [ $WEBRTC_PORT_OK -eq 0 ]; then
    echo -e "${RED}⊗ 问题:${NC} WebRTC 端口 ($WEBRTC_PORT) 不可访问"
    ISSUE_FOUND=1
fi

if [ $WEBRTC_PORT_OK -eq 1 ] && [ $WEBRTC_HEALTH_OK -eq 0 ]; then
    echo -e "${RED}⊗ 问题:${NC} WebRTC 服务不健康"
    ISSUE_FOUND=1
fi

if [ $SSH_TUNNEL_OK -eq 0 ]; then
    echo -e "${YELLOW}⚠ 警告:${NC} SSH 隧道未检测到"
    ISSUE_FOUND=1
fi

if [ $ISSUE_FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ 所有检查通过！${NC}"
    echo ""
    echo "如果视频仍无法显示，请尝试："
    echo "1. 刷新浏览器页面"
    echo "2. 点击视频连接按钮（▶ 按钮）"
    echo "3. 等待 10-15 秒后再试"
else
    echo ""
    echo -e "${YELLOW}建议的修复步骤:${NC}"
    echo ""
    
    if [ $SSH_TUNNEL_OK -eq 0 ] || [ $WEBRTC_PORT_OK -eq 0 ]; then
        echo -e "${BLUE}步骤 1: 重新建立 SSH 隧道${NC}"
        echo ""
        echo "在您的本地终端执行："
        echo ""
        echo -e "${GREEN}# 首先关闭旧的 SSH 连接（如果有）${NC}"
        if [[ "$OS_TYPE" == "Darwin" ]] || [[ "$OS_TYPE" == "Linux" ]]; then
            echo "pkill -f 'ssh.*8615:localhost:8615'"
        else
            echo "# Windows: 在任务管理器中结束 ssh.exe 进程"
        fi
        echo ""
        echo -e "${GREEN}# 然后重新建立连接${NC}"
        echo "ssh -o ServerAliveInterval=60 -L 3000:localhost:3000 -L 8203:localhost:8203 -L 8615:localhost:8615 root@<服务器IP>"
        echo ""
        echo -e "${YELLOW}注意:${NC} 即使提示 'Address already in use'，执行这个命令也能解决问题"
        echo ""
    fi
    
    if [ $WEBRTC_HEALTH_OK -eq 0 ] && [ $WEBRTC_PORT_OK -eq 1 ]; then
        echo -e "${BLUE}步骤 2: 检查服务器端服务${NC}"
        echo ""
        echo "SSH 到服务器并执行："
        echo ""
        echo -e "${GREEN}# 检查 WebRTC 服务进程${NC}"
        echo "ps aux | grep 'app.py.*8615' | grep -v grep"
        echo ""
        echo -e "${GREEN}# 检查端口监听${NC}"
        echo "netstat -tln | grep 8615"
        echo ""
        echo -e "${GREEN}# 查看服务日志${NC}"
        echo "tail -f /workspace/murphy/capstone-project-25t3-9900-virtual-tutor-phase-2/lip-sync/livetalking.log"
        echo ""
        echo "如果服务未运行，切换一个 Avatar 来启动服务"
        echo ""
    fi
    
    echo -e "${BLUE}步骤 3: 使用自动监控脚本（推荐）${NC}"
    echo ""
    echo "为避免每次都需要手动刷新 SSH 连接，建议使用监控脚本："
    echo "详见：SSH端口转发问题诊断和修复指南.md"
    echo ""
fi

echo -e "${BLUE}========================================"
echo "更多帮助"
echo "========================================${NC}"
echo ""
echo "完整文档: SSH端口转发问题诊断和修复指南.md"
echo "问题报告: 请提供以上诊断信息"
echo ""

# 提供快速修复命令
if [ $ISSUE_FOUND -eq 1 ]; then
    echo -e "${BLUE}快速修复（一键执行）:${NC}"
    echo ""
    read -p "是否立即尝试刷新 SSH 连接? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "请输入服务器 IP 地址:"
        read SERVER_IP
        
        echo ""
        echo -e "${YELLOW}正在关闭旧连接...${NC}"
        pkill -f "ssh.*$SERVER_IP" 2>/dev/null
        sleep 1
        
        echo -e "${YELLOW}正在建立新连接...${NC}"
        ssh -o ServerAliveInterval=60 -L 3000:localhost:3000 -L 8203:localhost:8203 -L 8615:localhost:8615 root@$SERVER_IP &
        
        echo ""
        echo -e "${GREEN}完成！${NC} 请等待 3-5 秒，然后："
        echo "1. 刷新浏览器"
        echo "2. 尝试连接视频"
    fi
fi

echo ""
echo -e "${BLUE}诊断完成${NC}"

