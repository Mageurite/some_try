# VSCode Remote SSH 端口转发配置指南

## 📌 问题说明

在使用 VSCode Remote SSH 时，即使 VSCode 会自动转发端口，但当服务器端的 WebRTC 服务重启（切换 Avatar）时，端口转发的网络连接状态可能不会自动刷新，导致视频连接失败。

## ✅ 解决方案

### 方案 1：使用自动配置（已完成）

项目中已经创建了 `.vscode/settings.json` 配置文件，包含了所有必要的端口转发设置。

**配置内容**：
```json
{
    "remote.autoForwardPorts": true,
    "remote.autoForwardPortsSource": "process",
    "remote.forwardOnOpen": true,
    "remote.restoreForwardedPorts": true,
    "remote.portsAttributes": {
        "3000": { "label": "Frontend" },
        "8203": { "label": "Backend API" },
        "8615": { "label": "WebRTC Avatar", "requireLocalPort": true },
        "8606": { "label": "Avatar Manager" },
        "8604": { "label": "TTS Service" }
    }
}
```

**重要配置项说明**：
- `remote.autoForwardPorts`: 自动转发检测到的端口
- `remote.forwardOnOpen`: 打开项目时自动转发
- `remote.restoreForwardedPorts`: 重新连接时恢复端口转发
- `requireLocalPort`: 确保本地端口与远程端口相同（对 WebRTC 很重要）

### 方案 2：手动刷新端口转发（快速修复）

当切换 Avatar 后视频无法连接时，在 VSCode 中：

#### 步骤 1：打开 PORTS 面板
1. 按 `Ctrl + J`（Mac: `Cmd + J`）打开面板
2. 点击 **PORTS** 标签
3. 找到端口 **8615**（WebRTC Avatar）

#### 步骤 2：刷新端口转发
**方法 A - 重新转发**：
1. 右键点击端口 **8615**
2. 选择 **Stop Forwarding Port**
3. 等待 2 秒
4. 右键点击空白处，选择 **Forward a Port**
5. 输入 **8615**

**方法 B - 使用快捷键**（更快）：
1. 选中端口 8615
2. 按 `Delete` 键停止转发
3. 按 `Ctrl + Shift + P`（Mac: `Cmd + Shift + P`）
4. 输入并选择 **Forward a Port**
5. 输入 **8615**

#### 步骤 3：验证连接
1. 在浏览器中刷新页面
2. 点击视频连接按钮（▶ 按钮）
3. 视频应该能正常显示

### 方案 3：使用自动化脚本（在 VSCode Terminal 中运行）

即使使用 VSCode Remote，您也可以在 VSCode 的集成终端中运行监控脚本：

```bash
# 在 VSCode 的 Terminal 中运行
cd /workspace/murphy/capstone-project-25t3-9900-virtual-tutor-phase-2

# 启动监控脚本（这会监控并自动刷新连接）
nohup ./scripts/monitor_ssh_tunnel_macos.sh > ~/ssh_monitor.log 2>&1 &

# 查看日志
tail -f ~/ssh_monitor.log
```

**注意**：在 VSCode Remote 环境中，这个脚本会监控 VSCode 建立的 SSH 隧道。

### 方案 4：VSCode 扩展配置（高级）

#### 安装有用的扩展
1. **Remote - SSH**（应该已安装）
2. **Port Manager**（可选，提供更好的端口管理界面）

#### 配置 SSH 保持连接
编辑本地 SSH 配置（在本地机器上，不是远程）：

**macOS/Linux**：编辑 `~/.ssh/config`
```ssh
Host 216.249.100.66
    HostName 216.249.100.66
    User root
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
    LocalForward 3000 localhost:3000
    LocalForward 8203 localhost:8203
    LocalForward 8615 localhost:8615
    LocalForward 8606 localhost:8606
    LocalForward 8604 localhost:8604
```

**Windows**：编辑 `%USERPROFILE%\.ssh\config`（内容同上）

## 🎯 推荐工作流程（VSCode Remote 专用）

### 日常使用

1. **打开项目**
   - VSCode 自动连接到远程服务器
   - 自动转发所有配置的端口
   - 在 PORTS 面板中可以看到转发的端口

2. **切换 Avatar**
   - 在前端界面选择新的 Avatar
   - 等待 5-10 秒（切换提示会显示进度）
   - 前端会自动尝试重连（最多 4 次）

3. **如果自动重连失败**
   - 打开 PORTS 面板
   - 右键点击 8615 → Stop Forwarding Port
   - 等待 2 秒
   - 再次转发端口 8615
   - 点击视频连接按钮

### 调试模式

如果需要调试连接问题：

1. **查看端口状态**
   ```bash
   # 在 VSCode Terminal 中运行
   netstat -tln | grep "8615\|8203\|3000"
   ```

2. **测试 WebRTC 服务**
   ```bash
   curl http://localhost:8615/health
   ```

3. **查看 Avatar 服务日志**
   ```bash
   tail -f logs/avatar_manager.log
   tail -f lip-sync/livetalking.log
   ```

4. **运行诊断工具**
   ```bash
   ./scripts/diagnose_avatar_connection.sh
   ```

## 🔧 故障排查（VSCode Remote 专用）

### 问题 1：端口转发显示但无法连接

**症状**：
- PORTS 面板显示 8615 已转发
- 但浏览器无法连接

**解决方法**：
```bash
# 1. 检查远程端口是否真的在监听
ss -tln | grep 8615

# 2. 如果端口在监听，重新转发端口（方案 2）

# 3. 如果端口不在监听，检查 Avatar 服务
ps aux | grep "app.py.*8615"
```

### 问题 2：VSCode 自动转发失败

**症状**：
- PORTS 面板中没有看到 8615
- 或者显示转发失败

**解决方法**：

1. **检查配置文件**
   ```bash
   cat .vscode/settings.json
   # 确认配置已正确加载
   ```

2. **手动添加端口**
   - 在 PORTS 面板点击 **Forward a Port**
   - 输入 **8615**

3. **重启 VSCode**
   - `Ctrl + Shift + P`（Mac: `Cmd + Shift + P`）
   - 输入并选择 **Remote-SSH: Kill VS Code Server on Host**
   - 重新连接

### 问题 3：切换 Avatar 后端口变成灰色

**症状**：
- PORTS 面板中 8615 显示为灰色
- 表示没有进程在监听

**解决方法**：
```bash
# 1. 确认 Avatar 是否正在启动
tail -f logs/avatar_manager.log

# 2. 等待 10-15 秒（首次启动需要加载模型）

# 3. 检查服务状态
ps aux | grep "app.py.*8615"

# 4. 如果服务启动完成，刷新端口转发（方案 2）
```

### 问题 4：多个 VSCode 窗口冲突

**症状**：
- 打开了多个 VSCode 窗口连接到同一服务器
- 端口转发冲突

**解决方法**：
1. 关闭其他 VSCode 窗口
2. 在当前窗口的 PORTS 面板重新转发端口
3. 或者在其他窗口中停止端口转发

## 📊 VSCode Remote vs 手动 SSH 对比

| 特性 | VSCode Remote | 手动 SSH 隧道 |
|------|--------------|--------------|
| **自动连接** | ✅ 自动 | ❌ 需要手动执行命令 |
| **端口管理** | ✅ 可视化界面 | ❌ 命令行 |
| **配置保存** | ✅ 自动保存 | ❌ 每次手动 |
| **重连恢复** | ✅ 自动恢复 | ⚠️ 需要重新执行命令 |
| **调试便利** | ✅ 集成终端 + 工具 | ⚠️ 需要切换窗口 |
| **稳定性** | ⚠️ 依赖 VSCode | ✅ 独立运行 |

## 🎉 最佳实践（VSCode Remote 用户）

### 开发流程

1. **启动开发环境**
   ```bash
   # 在 VSCode Remote Terminal 中
   cd /workspace/murphy/capstone-project-25t3-9900-virtual-tutor-phase-2
   
   # 启动所有服务（如果还没启动）
   ./scripts/start_all.sh
   ```

2. **检查端口转发**
   - 打开 PORTS 面板
   - 确认所有关键端口都在转发：3000, 8203, 8615

3. **访问应用**
   - 在本地浏览器打开：`http://localhost:3000`
   - VSCode 会自动转发请求到远程服务器

4. **切换 Avatar**
   - 在界面中选择新 Avatar
   - 观察切换提示
   - 如果 10 秒后仍无法连接，按方案 2 手动刷新端口

5. **结束工作**
   - 直接关闭 VSCode（端口转发会自动停止）
   - 无需手动清理

### 调试技巧

1. **同时查看多个日志**
   ```bash
   # 在不同的 Terminal 标签中打开
   tail -f logs/avatar_manager.log
   tail -f lip-sync/livetalking.log
   tail -f backend/backend.log
   ```

2. **使用 VSCode 的搜索功能**
   - 在日志文件中搜索 "ERROR" 或 "WARNING"
   - 快速定位问题

3. **利用 VSCode 的端口面板**
   - 可以直接在 PORTS 面板中点击端口打开浏览器
   - 测试端点是否可访问

## 🚀 快速参考

### 切换 Avatar 后视频无法连接 - 快速修复

**3 步解决**：
1. 打开 PORTS 面板（`Ctrl + J` → PORTS）
2. 右键点击 8615 → Stop → Forward
3. 刷新浏览器，点击连接

**或者一行命令**（在 Terminal）：
```bash
# 运行诊断脚本
./scripts/diagnose_avatar_connection.sh
```

## 💡 提示

1. **保持 VSCode 窗口打开**
   - 关闭 VSCode 会断开所有端口转发
   - 如果需要最小化，不要关闭

2. **使用 VSCode 的重新连接功能**
   - 如果 SSH 连接断开，VSCode 会自动尝试重连
   - 端口转发也会自动恢复

3. **配置文件已提交到版本控制**
   - `.vscode/settings.json` 已配置好
   - 团队成员可以直接使用相同配置

4. **监控脚本仍然有用**
   - 即使用 VSCode Remote，运行监控脚本也能提供额外的稳定性
   - 它会在 VSCode 的 SSH 连接上运行

---

**版本**：1.0  
**更新日期**：2025-10-20  
**适用于**：VSCode Remote SSH 用户

