# Avatar 问题修复完整指南

本文档汇总了所有 Avatar 相关问题的排查与解决方案。

---

## 📋 目录

1. [Avatar切换后视频显示问题](#1-avatar切换后视频显示问题)
2. [Avatar待机动画说明](#2-avatar待机动画说明)
3. [如何让Avatar发出声音](#3-如何让avatar发出声音)
4. [修复Avatar待机时嘴部大幅度动作](#4-修复avatar待机时嘴部大幅度动作)
5. [Avatar视频无声音问题](#5-avatar视频无声音问题)
6. [测试指南](#6-测试指南)

---

## 1. Avatar切换后视频显示问题

### 问题描述
切换Avatar时，视频无法正常显示，控制台出现以下错误：
- `Failed to load resource: net::ERR_CONNECTION_REFUSED`
- `WebRTC connection failed: TypeError: Failed to fetch`

### 根本原因
1. **WebRTC连接状态未清理**：切换Avatar时，旧的WebRTC PeerConnection对象没有被正确关闭
2. **端口冲突**：旧Avatar进程被终止后，端口8615被新Avatar占用，但前端仍保持着对旧连接的引用
3. **缺少重连机制**：切换完成后没有自动重新建立WebRTC连接

### 解决方案

#### 1.1 改进VideoAvatar组件

**文件**：`frontend/src/components/HomeChatList/index.js`

使用`React.forwardRef`并暴露控制方法：

```javascript
const VideoAvatar = React.forwardRef(({ style, switchingAvatar }, ref) => {
    // ... 组件代码
    
    // 暴露控制方法给父组件
    React.useImperativeHandle(ref, () => ({
        stopConnection,
        startConnection,
        isConnected: () => connected
    }));
});
```

#### 1.2 修改Avatar切换逻辑

在切换前断开连接，切换后自动重连：

```javascript
const handleModelSwitch = async (modelId) => {
    // 记录是否之前已连接
    const wasConnected = videoAvatarRef.current && videoAvatarRef.current.isConnected();

    // 先断开当前连接
    if (wasConnected) {
        videoAvatarRef.current.stopConnection();
        await new Promise(resolve => setTimeout(resolve, 500));
    }

    // 切换Avatar
    const result = await adminService.startAvatar(modelId);
    
    // 如果之前已连接，等待3秒后自动重新连接
    if (wasConnected && result.success) {
        setTimeout(() => {
            videoAvatarRef.current.startConnection();
        }, 3000);
    }
};
```

#### 1.3 添加视觉反馈

在切换时显示遮罩层：

```javascript
{switchingAvatar && (
    <div style={{...}}>
        <div>正在切换Avatar...</div>
        <div>请稍候，将自动重新连接</div>
    </div>
)}
```

### 修改的文件
- `frontend/src/components/HomeChatList/index.js` - VideoAvatar组件和切换逻辑
- `frontend/src/index.css` - 添加spin动画

### 工作流程

```
用户切换Avatar
    ↓
检查当前是否已连接
    ↓
如果已连接 → 断开WebRTC连接
    ↓
等待500ms
    ↓
调用后端API切换Avatar
    ↓
后端：终止旧进程 → 启动新进程
    ↓
显示"正在切换Avatar..."
    ↓
等待3秒（给新Avatar启动时间）
    ↓
自动重新连接WebRTC
    ↓
显示新Avatar视频
```

---

## 2. Avatar待机动画说明

### 问题描述
Avatar在没有输入时会自己动嘴，用户可能以为是异常。

### 根本原因
这是**正常的设计行为**：

1. **WebRTC协议要求**：
   - WebRTC连接需要持续的媒体流
   - 如果视频流中断，连接可能会断开
   - 因此Avatar必须持续生成视频帧

2. **自然性考虑**：
   - 完全静止的Avatar会显得不自然
   - 微小的嘴部动作模拟真实人类的待机状态
   - 提升用户体验

3. **技术实现**：
   - 使用参考音频文件（`silence.wav`或`complete_silence.wav`）
   - 音频特征驱动嘴部动画
   - 保持视频流连续

### 正常的Avatar行为

#### 待机状态
```
用户连接视频
    ↓
Avatar加载参考音频
    ↓
生成微小/无嘴部动作（待机动画）
    ↓
持续播放，保持视频流连续
```

**特征**：
- 嘴部闭合或微小动作
- 没有大幅度张嘴
- 类似真人的自然待机

#### 响应状态（用户发送消息后）
```
用户发送消息
    ↓
LLM生成回复
    ↓
TTS将文字转换为语音
    ↓
Avatar根据语音生成嘴部动画
    ↓
播放有明确语义的嘴部动作
```

**特征**：
- 嘴部有明显的张合动作
- 动作与语音同步
- 能看出在说话

---

## 3. 如何让Avatar发出声音

### 前提条件

✅ TTS服务运行正常（端口8604）  
✅ Avatar服务已连接（端口8615）  
✅ 视频流正常

### 让Avatar说话的方法

#### 方法1：发送聊天消息（推荐）⭐

这是让Avatar说话的正确方式！

**步骤**：

1. **确保视频已连接**
   - 打开浏览器访问系统
   - 点击视频右下角的▶️播放按钮
   - 等待视频连接成功

2. **发送一条消息**
   ```
   在聊天框输入：你好
   然后点击发送
   ```

3. **Avatar会：**
   - 🎤 LLM生成回复文字
   - 🔊 TTS将文字转换为语音
   - 👄 Avatar嘴部动作与语音同步
   - 🔉 **你会听到Avatar的声音！**

#### 完整流程
```
你输入："你好"
    ↓
LLM生成："你好！有什么可以帮到你的吗？"
    ↓
TTS生成语音（使用端口8604）
    ↓
Avatar播放语音 + 嘴部动画
    ↓
你听到声音 ✅
```

### 重要说明

**Avatar在待机时不会发出声音**

- **当前状态（待机）**：Avatar在动嘴（微小动作），没有声音（正常）
- **响应状态（发送消息后）**：Avatar明显张嘴说话，有清晰的语音

**原因**：待机动画只是为了保持视频流的自然性，不应该发出实际的语音。

### 如果发送消息后还是没有声音

#### 检查1：浏览器音频设置
1. 右键点击浏览器标签
2. 查看是否显示"🔇 静音网站"
3. 如果是静音的，点击"取消静音"

#### 检查2：video元素没有muted
打开浏览器开发者工具（F12）→ Console：
```javascript
const video = document.querySelector('video');
console.log('Video muted:', video.muted);  // 应该是 false
video.muted = false;  // 如果是true，手动取消静音
```

#### 检查3：WebRTC音频track
```javascript
const video = document.querySelector('video');
const stream = video.srcObject;
const audioTracks = stream?.getAudioTracks();
console.log('Audio tracks:', audioTracks);
console.log('Audio enabled:', audioTracks?.[0]?.enabled);
```

---

## 4. 修复Avatar待机时嘴部大幅度动作

### 问题描述
Avatar说完话后，嘴巴还在大幅度动作，看起来像在"大声说话"，而不是回到静止的待机状态。

### 解决方案

#### 4.1 创建完全静音的参考音频

```bash
ffmpeg -f lavfi -i anullsrc=channel_layout=mono:sample_rate=16000 \
  -t 10 -acodec pcm_s16le ref_audio/complete_silence.wav -y
```

这会创建一个真正的静音文件，没有任何音频变化。

#### 4.2 使用新的参考音频重启Avatar

```bash
curl -X POST "http://localhost:8606/switch_avatar?avatar_id=yongen&ref_file=ref_audio/complete_silence.wav"
```

### 用户操作步骤

1. **刷新浏览器页面**
   - 按 `Ctrl + Shift + R`（强制刷新）

2. **重新连接视频**
   - 点击视频右下角的 ▶️ 播放按钮

3. **观察效果**
   - ✅ **待机时**：嘴巴完全闭合，保持静止
   - ✅ **说话时**：正常的嘴部动作和声音
   - ✅ **说完后**：立即回到静止状态

### 技术细节

**之前的问题**：
- 使用 `silence.wav` 作为参考音频
- 该文件虽然名为"silence"，但实际包含微小的音频变化
- 这些变化被Avatar解析为嘴部动作指令
- 导致待机时嘴部持续动作

**解决方案**：
- 使用 `complete_silence.wav`（真正的静音）
- 完全无音频变化
- Avatar待机时嘴部完全静止

---

## 5. Avatar视频无声音问题

### 问题诊断

从日志发现两个问题：

#### 问题1：TTS服务未运行 ❌

**原因**：`start_all.sh` 中的路径错误

```bash
# ❌ 错误的路径
cd "${PROJECT_ROOT}/tts/edge"
nohup python edge/server.py --model_name edgeTTS --port 8604 ...
                 ↑
            重复的路径前缀
```

#### 问题2：前端音频处理不正确 ⚠️

**原因1**：video元素被设置为 `muted`

```jsx
<video
    ref={videoRef}
    autoPlay
    playsInline
    muted  // ← 静音！
/>
```

**原因2**：音频处理逻辑可能导致重复播放或丢失

### 解决方案

#### 5.1 修正TTS服务启动路径

**文件**：`start_all.sh`

```bash
# ✅ 修正后
cd "${PROJECT_ROOT}/tts/edge"
conda activate edge
nohup python server.py --model_name edgeTTS --port 8604 --use_gpu false > "${LOG_DIR}/edge_tts.log" 2>&1 &
```

**验证**：
```bash
netstat -tln | grep ':8604'
curl http://localhost:8604/health
```

#### 5.2 优化前端音频处理

**文件**：`frontend/src/components/HomeChatList/index.js`

**修改1**：移除video的muted属性

```jsx
<video
    ref={videoRef}
    autoPlay
    playsInline
    // muted 已移除
/>
```

**修改2**：改进WebRTC track处理逻辑

```javascript
// ✅ 新的逻辑
const streams = new Set();
pc.addEventListener('track', (evt) => {
    console.log(`收到 ${evt.track.kind} track`);
    
    // 收集所有stream
    evt.streams.forEach(stream => streams.add(stream));
    
    // 将完整的stream（视频+音频）设置给video元素
    if (videoRef.current && streams.size > 0) {
        const stream = Array.from(streams)[0];
        videoRef.current.srcObject = stream;
    }
});
```

**优势**：
- ✅ video元素统一处理视频和音频
- ✅ 避免创建额外的Audio对象
- ✅ 不会重复播放音频

### 立即修复步骤

#### 步骤1：启动TTS服务
```bash
cd tts/edge
conda activate edge
nohup python server.py --model_name edgeTTS --port 8604 --use_gpu false > ../../logs/edge_tts.log 2>&1 &
sleep 5
curl http://localhost:8604/health
```

#### 步骤2：重启前端服务
刷新浏览器即可，或：
```bash
cd frontend
npm start
```

#### 步骤3：测试音频
1. 打开浏览器访问系统
2. 选择Avatar并连接视频
3. 发送消息测试
4. **应该能听到声音了！** 🎉

---

## 6. 测试指南

### 测试场景1：正常切换

**步骤**：
1. 启动第一个Avatar（如'g'）
2. 点击播放按钮连接视频
3. 切换到另一个Avatar（如'yongen'）

**预期结果**：
- ✅ 视频断开 → 显示切换状态 → 3秒后自动重连 → 新Avatar视频显示

### 测试场景2：未连接时切换

**步骤**：
1. 启动Avatar但不连接视频
2. 直接切换到另一个Avatar
3. 手动点击播放按钮

**预期结果**：
- ✅ 切换完成后可以正常连接新Avatar的视频

### 测试场景3：待机动画

**步骤**：
1. 连接视频后不发送消息
2. 观察Avatar的嘴部状态

**预期结果**：
- ✅ 嘴巴闭合，保持静止（使用complete_silence.wav）
- ✅ 视频画面稳定

### 测试场景4：说话和声音

**步骤**：
1. 连接视频
2. 发送消息"你好"
3. 等待Avatar回复
4. 观察回复结束后的状态

**预期结果**：
- ✅ Avatar开始说话时有明显嘴部动作
- ✅ 能听到清晰的语音
- ✅ 说完后立即回到静止状态

### 快速诊断清单

```bash
# 1. 检查TTS服务
netstat -tln | grep ':8604'
curl http://localhost:8604/health

# 2. 检查Avatar服务
netstat -tln | grep ':8615'

# 3. 查看日志
tail -f logs/avatar_manager.log
tail -f logs/edge_tts.log

# 4. 测试TTS
curl -X POST http://localhost:8604/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "测试", "voice": "en-US-BrianNeural"}'
```

---

## 📚 关键文件说明

### 前端文件
- `frontend/src/components/HomeChatList/index.js` - VideoAvatar组件和切换逻辑
- `frontend/src/index.css` - 动画样式

### 后端文件
- `backend/routes/avatar.py` - Avatar相关API
- `lip-sync/live_server.py` - Avatar管理服务
- `lip-sync/app.py` - Avatar核心服务

### 配置文件
- `lip-sync/ref_audio/complete_silence.wav` - 完全静音参考音频
- `lip-sync/ref_audio/silence.wav` - 原始参考音频（有微小变化）

---

## 🎯 总结

### 已解决的问题

1. ✅ **Avatar切换后视频无法显示** - 自动断开和重连WebRTC
2. ✅ **待机动画说明** - 这是正常行为，保持视频流连续
3. ✅ **Avatar没有声音** - 修复TTS服务和前端音频处理
4. ✅ **说完话后嘴部大幅度动作** - 使用完全静音参考音频

### 关键改进

- 🔄 **自动化切换**：切换Avatar时自动管理WebRTC连接
- 🎨 **视觉反馈**：切换时显示进度提示
- 🔊 **音频优化**：正确处理WebRTC音频流
- 😶 **待机优化**：使用完全静音文件，嘴部完全静止

### 用户体验

**切换Avatar**：
```
选择新Avatar → 自动断开 → 显示切换中 → 自动重连 → 完成
```

**使用Avatar**：
```
待机：嘴巴闭合，静止
说话：正常动作+声音
说完：立即静止
```

---

**文档创建日期**：2025年10月19日  
**最后更新**：2025年10月19日

