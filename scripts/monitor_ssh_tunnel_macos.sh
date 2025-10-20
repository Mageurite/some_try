#!/bin/bash

###############################################################################
# SSH 隧道自动监控和恢复脚本 (macOS/Linux)
# 
# 功能：
# 1. 自动检测 SSH 隧道状态
# 2. 检测 WebRTC 服务健康状态
# 3. 自动重建失效的连接
# 
# 使用方法：
#   1. 修改下面的配置（SERVER_IP 和 SERVER_USER）
#   2. 运行: nohup ./monitor_ssh_tunnel_macos.sh > ~/ssh_monitor.log 2>&1 &
#   3. 查看日志: tail -f ~/ssh_monitor.log
#   4. 停止: pkill -f monitor_ssh_tunnel_macos.sh
###############################################################################

# ==================== 配置区域 ====================
SERVER_IP="216.249.100.66"  # 修改为您的服务器 IP
SERVER_USER="root"          # 修改为您的用户名
CHECK_INTERVAL=5            # 检查间隔（秒）
# ==================================================

# 颜色代码（用于日志）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_error() {
    log "${RED}[ERROR]${NC} $1"
}

log_warning() {
    log "${YELLOW}[WARNING]${NC} $1"
}

log_info() {
    log "${BLUE}[INFO]${NC} $1"
}

log_success() {
    log "${GREEN}[SUCCESS]${NC} $1"
}

# 函数：检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "需要的命令 '$1' 未找到，请先安装"
        exit 1
    fi
}

# 检查必需的命令
check_command ssh
check_command nc
check_command curl

# 函数：检查端口是否可访问
check_port() {
    local port=$1
    nc -z localhost $port >/dev/null 2>&1
    return $?
}

# 函数：检查 WebRTC 服务健康状态
check_webrtc_health() {
    local response=$(curl -s -w "\n%{http_code}" http://localhost:8615/health 2>/dev/null)
    local http_code=$(echo "$response" | tail -n 1)
    
    if [ "$http_code" = "200" ]; then
        return 0
    else
        return 1
    fi
}

# 函数：检查 SSH 进程是否存在
check_ssh_process() {
    pgrep -f "ssh.*$SERVER_IP.*8615:localhost:8615" > /dev/null 2>&1
    return $?
}

# 函数：停止 SSH 隧道
stop_ssh_tunnel() {
    log_info "停止旧的 SSH 隧道..."
    pkill -f "ssh.*$SERVER_IP.*8615:localhost:8615" 2>/dev/null
    sleep 1
}

# 函数：启动 SSH 隧道
start_ssh_tunnel() {
    log_info "启动新的 SSH 隧道..."
    
    # 使用 -f 参数在后台运行，-N 表示不执行远程命令
    # ServerAliveInterval 保持连接活跃
    # StrictHostKeyChecking=no 自动接受主机密钥（首次连接）
    ssh -f -N \
        -o ServerAliveInterval=60 \
        -o ServerAliveCountMax=3 \
        -o StrictHostKeyChecking=no \
        -L 3000:localhost:3000 \
        -L 8203:localhost:8203 \
        -L 8615:localhost:8615 \
        $SERVER_USER@$SERVER_IP 2>/dev/null
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        log_success "SSH 隧道已建立"
        return 0
    else
        log_error "SSH 隧道建立失败（退出码: $exit_code）"
        return 1
    fi
}

# 函数：重启 SSH 隧道
restart_ssh_tunnel() {
    local reason=$1
    log_warning "检测到问题: $reason"
    
    stop_ssh_tunnel
    sleep 2
    
    if start_ssh_tunnel; then
        sleep 3
        # 验证连接
        if check_port 8615; then
            log_success "SSH 隧道恢复成功"
            return 0
        else
            log_error "SSH 隧道恢复后端口仍不可访问"
            return 1
        fi
    else
        return 1
    fi
}

# 主函数
main() {
    log_info "=========================================="
    log_info "SSH 隧道监控脚本已启动"
    log_info "服务器: $SERVER_USER@$SERVER_IP"
    log_info "检查间隔: $CHECK_INTERVAL 秒"
    log_info "PID: $$"
    log_info "=========================================="
    
    # 初始化：确保 SSH 隧道正在运行
    if ! check_ssh_process; then
        log_warning "初始化：SSH 隧道未运行"
        start_ssh_tunnel
        sleep 3
    else
        log_info "初始化：SSH 隧道已在运行"
    fi
    
    # 主循环
    local consecutive_failures=0
    local max_failures=3
    
    while true; do
        # 检查 1: SSH 进程是否存在
        if ! check_ssh_process; then
            log_warning "SSH 进程不存在"
            if restart_ssh_tunnel "SSH进程丢失"; then
                consecutive_failures=0
            else
                ((consecutive_failures++))
            fi
            sleep $CHECK_INTERVAL
            continue
        fi
        
        # 检查 2: 端口是否可访问
        if ! check_port 8615; then
            log_warning "端口 8615 不可访问"
            if restart_ssh_tunnel "端口不可访问"; then
                consecutive_failures=0
            else
                ((consecutive_failures++))
            fi
            sleep $CHECK_INTERVAL
            continue
        fi
        
        # 检查 3: WebRTC 服务健康状态
        if ! check_webrtc_health; then
            log_warning "WebRTC 服务不健康"
            if restart_ssh_tunnel "服务健康检查失败"; then
                consecutive_failures=0
            else
                ((consecutive_failures++))
            fi
            sleep $CHECK_INTERVAL
            continue
        fi
        
        # 所有检查通过
        if [ $consecutive_failures -gt 0 ]; then
            log_success "连接已恢复正常"
            consecutive_failures=0
        fi
        
        # 检查连续失败次数
        if [ $consecutive_failures -ge $max_failures ]; then
            log_error "连续失败 $consecutive_failures 次，可能存在严重问题"
            log_error "建议手动检查："
            log_error "  1. 服务器是否可访问: ping $SERVER_IP"
            log_error "  2. SSH 认证是否正常: ssh $SERVER_USER@$SERVER_IP 'echo ok'"
            log_error "  3. 服务器端 WebRTC 服务是否运行"
            log_error "等待 60 秒后继续尝试..."
            sleep 60
            consecutive_failures=0
        fi
        
        # 正常等待
        sleep $CHECK_INTERVAL
    done
}

# 信号处理
trap 'log_info "收到终止信号，正在退出..."; stop_ssh_tunnel; exit 0' SIGTERM SIGINT

# 启动主循环
main

