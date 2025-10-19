# VSCode Remote SSH 端口转发问题修复

## 🔍 发现的问题

有多个 `app.py` 进程在运行：
- PID 944532: 旧进程（可能是之前遗留的）
- PID 965278: 当前进程（监听8615端口）

**这可能导致资源冲突，影响视频加载。**

## ✅ 解决方案

### 步骤1: 清理所有旧进程

```bash
# 杀掉所有avatar进程
pkill -9 -f "app.py"

# 等待2秒
sleep 2

# 确认已清理
ps aux | grep "app.py" | grep -v grep
```

### 步骤2: 通过API重新启动avatar

```bash
# 使用live_server API启动
curl -X POST "http://localhost:8606/switch_avatar?avatar_id=yongen&ref_file=ref_audio/silence.wav"
```

### 步骤3: 在VSCode中配置端口转发

#### 方法A: 自动端口转发
1. 在VSCode中按 `Ctrl + Shift + P` (Mac: `Cmd + Shift + P`)
2. 输入 "Forward a Port"
3. 输入端口号: `8615`
4. VSCode会自动转发这个端口

#### 方法B: 查看已转发的端口
1. 在VSCode底部状态栏，点击 "PORTS" 标签
2. 查看 8615 端口是否在列表中
3. 如果没有，点击 "Forward a Port" 添加

#### 方法C: 手动端口转发（备用方案）
如果VSCode自动转发不工作，在本地终端运行：
```bash
ssh -L 8615:localhost:8615 用户名@服务器IP
```

### 步骤4: 访问视频

在你的**本地浏览器**（不是服务器上的）访问：
```
http://localhost:8615/webrtcapi.html
```

## 🔧 立即执行的命令

运行以下脚本自动修复：






