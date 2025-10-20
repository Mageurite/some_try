###############################################################################
# SSH 隧道自动监控和恢复脚本 (Windows PowerShell)
# 
# 功能：
# 1. 自动检测 SSH 隧道状态
# 2. 检测 WebRTC 服务健康状态
# 3. 自动重建失效的连接
# 
# 使用方法：
#   1. 修改下面的配置（$SERVER_IP 和 $SERVER_USER）
#   2. 在 PowerShell 中运行: .\monitor_ssh_tunnel_windows.ps1
#   3. 或后台运行: Start-Process powershell -ArgumentList "-File monitor_ssh_tunnel_windows.ps1" -WindowStyle Hidden
#   4. 停止: 在任务管理器中结束 PowerShell 进程
###############################################################################

# ==================== 配置区域 ====================
$SERVER_IP = "216.249.100.66"  # 修改为您的服务器 IP
$SERVER_USER = "root"          # 修改为您的用户名
$CHECK_INTERVAL = 5            # 检查间隔（秒）
# ==================================================

# 日志函数
function Write-Log {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# 函数：检查端口是否可访问
function Test-Port {
    param($Port)
    try {
        $connection = New-Object System.Net.Sockets.TcpClient("localhost", $Port)
        $connection.Close()
        return $true
    } catch {
        return $false
    }
}

# 函数：检查 WebRTC 服务健康状态
function Test-WebRTCHealth {
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:8615/health" -TimeoutSec 5 -ErrorAction SilentlyContinue
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

# 函数：检查 SSH 进程是否存在
function Test-SSHProcess {
    $processes = Get-Process -Name ssh -ErrorAction SilentlyContinue
    foreach ($proc in $processes) {
        try {
            $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)").CommandLine
            if ($cmdLine -like "*$SERVER_IP*" -and $cmdLine -like "*8615*") {
                return $true
            }
        } catch {
            # 忽略无法获取命令行的进程
        }
    }
    return $false
}

# 函数：停止 SSH 隧道
function Stop-SSHTunnel {
    Write-Log "停止旧的 SSH 隧道..." "INFO"
    
    $processes = Get-Process -Name ssh -ErrorAction SilentlyContinue
    foreach ($proc in $processes) {
        try {
            $cmdLine = (Get-CimInstance Win32_Process -Filter "ProcessId = $($proc.Id)").CommandLine
            if ($cmdLine -like "*$SERVER_IP*") {
                Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
            }
        } catch {
            # 忽略错误
        }
    }
    
    Start-Sleep -Seconds 1
}

# 函数：启动 SSH 隧道
function Start-SSHTunnel {
    Write-Log "启动新的 SSH 隧道..." "INFO"
    
    try {
        # 构建 SSH 命令
        $sshArgs = @(
            "-o", "ServerAliveInterval=60",
            "-o", "ServerAliveCountMax=3",
            "-o", "StrictHostKeyChecking=no",
            "-N",
            "-L", "3000:localhost:3000",
            "-L", "8203:localhost:8203",
            "-L", "8615:localhost:8615",
            "$SERVER_USER@$SERVER_IP"
        )
        
        # 启动 SSH 进程（隐藏窗口）
        $process = Start-Process ssh -ArgumentList $sshArgs -WindowStyle Hidden -PassThru
        
        if ($process) {
            Write-Log "SSH 隧道已建立 (PID: $($process.Id))" "SUCCESS"
            return $true
        } else {
            Write-Log "SSH 隧道建立失败" "ERROR"
            return $false
        }
    } catch {
        Write-Log "启动 SSH 隧道时出错: $_" "ERROR"
        return $false
    }
}

# 函数：重启 SSH 隧道
function Restart-SSHTunnel {
    param($Reason)
    
    Write-Log "检测到问题: $Reason" "WARNING"
    
    Stop-SSHTunnel
    Start-Sleep -Seconds 2
    
    if (Start-SSHTunnel) {
        Start-Sleep -Seconds 3
        
        # 验证连接
        if (Test-Port 8615) {
            Write-Log "SSH 隧道恢复成功" "SUCCESS"
            return $true
        } else {
            Write-Log "SSH 隧道恢复后端口仍不可访问" "ERROR"
            return $false
        }
    } else {
        return $false
    }
}

# 主函数
function Main {
    Write-Log "==========================================" "INFO"
    Write-Log "SSH 隧道监控脚本已启动" "INFO"
    Write-Log "服务器: $SERVER_USER@$SERVER_IP" "INFO"
    Write-Log "检查间隔: $CHECK_INTERVAL 秒" "INFO"
    Write-Log "PID: $PID" "INFO"
    Write-Log "==========================================" "INFO"
    
    # 初始化：确保 SSH 隧道正在运行
    if (-not (Test-SSHProcess)) {
        Write-Log "初始化：SSH 隧道未运行" "WARNING"
        Start-SSHTunnel
        Start-Sleep -Seconds 3
    } else {
        Write-Log "初始化：SSH 隧道已在运行" "INFO"
    }
    
    # 主循环
    $consecutiveFailures = 0
    $maxFailures = 3
    
    while ($true) {
        try {
            # 检查 1: SSH 进程是否存在
            if (-not (Test-SSHProcess)) {
                Write-Log "SSH 进程不存在" "WARNING"
                if (Restart-SSHTunnel "SSH进程丢失") {
                    $consecutiveFailures = 0
                } else {
                    $consecutiveFailures++
                }
                Start-Sleep -Seconds $CHECK_INTERVAL
                continue
            }
            
            # 检查 2: 端口是否可访问
            if (-not (Test-Port 8615)) {
                Write-Log "端口 8615 不可访问" "WARNING"
                if (Restart-SSHTunnel "端口不可访问") {
                    $consecutiveFailures = 0
                } else {
                    $consecutiveFailures++
                }
                Start-Sleep -Seconds $CHECK_INTERVAL
                continue
            }
            
            # 检查 3: WebRTC 服务健康状态
            if (-not (Test-WebRTCHealth)) {
                Write-Log "WebRTC 服务不健康" "WARNING"
                if (Restart-SSHTunnel "服务健康检查失败") {
                    $consecutiveFailures = 0
                } else {
                    $consecutiveFailures++
                }
                Start-Sleep -Seconds $CHECK_INTERVAL
                continue
            }
            
            # 所有检查通过
            if ($consecutiveFailures -gt 0) {
                Write-Log "连接已恢复正常" "SUCCESS"
                $consecutiveFailures = 0
            }
            
            # 检查连续失败次数
            if ($consecutiveFailures -ge $maxFailures) {
                Write-Log "连续失败 $consecutiveFailures 次，可能存在严重问题" "ERROR"
                Write-Log "建议手动检查：" "ERROR"
                Write-Log "  1. 服务器是否可访问: ping $SERVER_IP" "ERROR"
                Write-Log "  2. SSH 认证是否正常" "ERROR"
                Write-Log "  3. 服务器端 WebRTC 服务是否运行" "ERROR"
                Write-Log "等待 60 秒后继续尝试..." "ERROR"
                Start-Sleep -Seconds 60
                $consecutiveFailures = 0
            }
            
            # 正常等待
            Start-Sleep -Seconds $CHECK_INTERVAL
            
        } catch {
            Write-Log "监控循环中出现错误: $_" "ERROR"
            Start-Sleep -Seconds $CHECK_INTERVAL
        }
    }
}

# Ctrl+C 处理
$null = [Console]::TreatControlCAsInput = $true
trap {
    Write-Log "收到终止信号，正在退出..." "INFO"
    Stop-SSHTunnel
    exit 0
}

# 启动主循环
Main

