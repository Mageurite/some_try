import React, { useState, useEffect, useRef } from 'react';
import adminService from '../../services/adminService';
import config from '../../config';

// 使用配置中的 URL
const getWebRTCUrl = () => {
    return config.WEBRTC_URL;
};

const getBackendUrl = () => {
    return config.BACKEND_URL;
};

// 默认AI模型选项（作为备用）
const defaultAiModels = [
    { id: 'tutor-model-1', name: 'Tutor Model 1', description: 'Basic teaching model, suitable for beginners' },
    { id: 'tutor-model-2', name: 'Tutor Model 2', description: 'Advanced teaching model, suitable for learners with foundation' },
    { id: 'tutor-model-3', name: 'Tutor Model 3', description: 'Professional teaching model, suitable for deep learning' },
    { id: 'tutor-model-4', name: 'Tutor Model 4', description: 'Expert-level teaching model, suitable for advanced users' }
];

// WebRTC Video Avatar Component (Square, with connection button in bottom right)
const VideoAvatar = React.forwardRef(({ style, switchingAvatar, initialLoading }, ref) => {
    const videoRef = useRef(null);
    const pcRef = useRef(null);
    const [connected, setConnected] = useState(false);
    const [loading, setLoading] = useState(false);

    // 检查 WebRTC 服务是否就绪
    const checkWebRTCHealth = async () => {
        const webrtcUrl = getWebRTCUrl();
        try {
            const response = await fetch(`${webrtcUrl}/health`, {
                method: 'GET',
                timeout: 5000
            });
            return response.ok;
        } catch (error) {
            console.log('WebRTC health check failed:', error);
            return false;
        }
    };

    // 啟動 WebRTC 連接（带重试机制）
    const startConnection = async (retryCount = 0, maxRetries = 3) => {
        const retryDelay = 2000; // 重试间隔2秒
        
        setLoading(true);
        try {
            // 在尝试连接前，先检查服务是否就绪
            console.log(`尝试连接 WebRTC (尝试 ${retryCount + 1}/${maxRetries + 1})...`);
            
            // 先进行健康检查（仅在重试时）
            if (retryCount > 0) {
                console.log('正在检查 WebRTC 服务健康状态...');
                const isHealthy = await checkWebRTCHealth();
                if (!isHealthy && retryCount < maxRetries) {
                    console.log(`服务尚未就绪，${retryDelay/1000}秒后重试...`);
                    setTimeout(() => startConnection(retryCount + 1, maxRetries), retryDelay);
                    return;
                }
            }
            
            let pc;
            let stopped = false;
            const config = {
                sdpSemantics: 'unified-plan',
                iceServers: [{ urls: ['stun:stun.l.google.com:19302'] }]
            };
            pc = new window.RTCPeerConnection(config);
            pcRef.current = pc;

            pc.addTransceiver('video', { direction: 'recvonly' });
            pc.addTransceiver('audio', { direction: 'recvonly' });

            // 收集所有接收到的 stream
            const streams = new Set();
            pc.addEventListener('track', (evt) => {
                console.log(`收到 ${evt.track.kind} track`);
                
                // 将 stream 添加到集合中
                evt.streams.forEach(stream => streams.add(stream));
                
                // 当收到第一个 track 时，将 stream 设置给 video 元素
                // video 元素会自动处理其中的视频和音频
                if (videoRef.current && streams.size > 0) {
                    const stream = Array.from(streams)[0];
                    videoRef.current.srcObject = stream;
                    console.log('Stream 已设置到 video 元素，包含轨道:', 
                        stream.getTracks().map(t => t.kind).join(', '));
                }
            });

            await pc.setLocalDescription(await pc.createOffer());
            await new Promise((resolve) => {
                if (pc.iceGatheringState === 'complete') {
                    resolve();
                } else {
                    const checkState = () => {
                        if (pc.iceGatheringState === 'complete') {
                            pc.removeEventListener('icegatheringstatechange', checkState);
                            resolve();
                        }
                    };
                    pc.addEventListener('icegatheringstatechange', checkState);
                }
            });

            const offer = pc.localDescription;
            const webrtcUrl = getWebRTCUrl();
            const response = await fetch(`${webrtcUrl}/offer`, {
                body: JSON.stringify({ sdp: offer.sdp, type: offer.type }),
                headers: { 'Content-Type': 'application/json' },
                method: 'POST'
            });
            
            if (!response.ok) {
                throw new Error(`Server error: ${response.status} ${response.statusText}`);
            }
            
            const answer = await response.json();
            if (answer.sessionid) {
                const token = localStorage.getItem('token'); // 取得 token
                const backendUrl = getBackendUrl();
                await fetch(`${backendUrl}/api/sessionid`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                        'sessionid': answer.sessionid,
                        'Authorization': `Bearer ${token}` // 加入 token
                    },
                    body: JSON.stringify({ sessionid: answer.sessionid })
                });
            }
            if (!stopped) {
                await pc.setRemoteDescription(answer);
                setConnected(true);
                console.log('✅ WebRTC 连接成功！');
            }
        } catch (error) {
            console.error(`WebRTC connection failed (尝试 ${retryCount + 1}/${maxRetries + 1}):`, error);
            
            // 如果还有重试次数，自动重试
            if (retryCount < maxRetries) {
                console.log(`${retryDelay/1000}秒后自动重试...`);
                setTimeout(() => startConnection(retryCount + 1, maxRetries), retryDelay);
                return;
            }
            
            // 所有重试都失败后，显示错误信息
            const errorMsg = error.message.includes('Failed to fetch') 
                ? 'Unable to connect to video service.\n\nPossible causes:\n1. Avatar service is still starting up, please try again later\n2. Network connection issue\n3. If using SSH port forwarding, you may need to re-establish the connection\n\nSuggestion: Wait 10-15 seconds and click the connect button again'
                : `Video connection failed: ${error.message}\n\nPlease select an Avatar and wait for it to finish loading before attempting to connect.`;
                
            alert(errorMsg);
            if (pcRef.current) {
                pcRef.current.close();
                pcRef.current = null;
            }
        } finally {
            setLoading(false);
        }
    };

    // 關閉 WebRTC 連接
    const stopConnection = () => {
        if (pcRef.current) {
            pcRef.current.close();
            pcRef.current = null;
        }
        if (videoRef.current) {
            videoRef.current.srcObject = null;
        }
        setConnected(false);
    };

    // 将stopConnection方法暴露给父组件
    React.useImperativeHandle(ref, () => ({
        stopConnection,
        startConnection,
        isConnected: () => connected
    }));

    // 卸載時自動關閉
    useEffect(() => {
        return () => {
            stopConnection();
        };
    }, []);

    return (
        <div style={{
            width: '100%',
            height: '100%',
            borderRadius: 12,
            overflow: 'hidden',
            background: '#000',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            boxShadow: '0 2px 16px #4F378A22',
            position: 'relative',
            ...style
        }}>
            <video
                ref={videoRef}
                autoPlay
                playsInline
                style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: 0 }}
            />
            
            {/* Avatar switching/loading overlay */}
            {(switchingAvatar || initialLoading) && (
                <div style={{
                    position: 'absolute',
                    top: 0,
                    left: 0,
                    width: '100%',
                    height: '100%',
                    background: 'rgba(0, 0, 0, 0.7)',
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    justifyContent: 'center',
                    color: '#fff',
                    fontSize: 16,
                    fontWeight: 500,
                    zIndex: 5
                }}>
                    <div style={{
                        width: 40,
                        height: 40,
                        border: '3px solid #ffffff33',
                        borderTop: '3px solid #fff',
                        borderRadius: '50%',
                        animation: 'spin 1s linear infinite',
                        marginBottom: 16
                    }}></div>
                    <div>{initialLoading ? 'Initializing Avatar...' : 'Switching Avatar...'}</div>
                    <div style={{ fontSize: 12, color: '#ffffffaa', marginTop: 8, textAlign: 'center', lineHeight: '1.6' }}>
                        {initialLoading ? (
                            <>
                                Loading default avatar service<br/>
                                This may take 5-10 seconds, please wait<br/>
                                You can switch to another avatar anytime
                            </>
                        ) : (
                            <>
                                Stopping old service and starting new service<br/>
                                This may take 5-10 seconds, please wait<br/>
                                Video will automatically reconnect when complete
                            </>
                        )}
                    </div>
                </div>
            )}
            
            {/* 右下角連接/斷開按鈕 */}
            <button
                onClick={connected ? stopConnection : startConnection}
                disabled={loading || switchingAvatar}
                style={{
                    position: 'absolute',
                    right: 10,
                    bottom: 10,
                    width: 40,
                    height: 40,
                    borderRadius: '50%',
                    background: connected ? 'linear-gradient(135deg, #FF7E5F 0%, #FFB86C 100%)' : 'linear-gradient(135deg, #4ADE80 0%, #6EE7B7 100%)',
                    border: 'none',
                    cursor: (loading || switchingAvatar) ? 'not-allowed' : 'pointer',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    boxShadow: '0 2px 8px #0002',
                    color: '#fff',
                    fontSize: 20,
                    fontWeight: 700,
                    transition: 'all 0.2s',
                    opacity: (loading || switchingAvatar) ? 0.6 : 1,
                    zIndex: 30
                }}
                title={connected ? 'Disconnect Video' : 'Connect Video'}
            >
                {loading ? '...' : connected ? '⏹' : '▶'}
            </button>
        </div>
    );
});

function HomeChatList({ themeStyles }) {
    const [selectedModel, setSelectedModel] = useState('');
    const [availableAvatars, setAvailableAvatars] = useState([]);
    const [loadingAvatars, setLoadingAvatars] = useState(false);
    const [switchingModel, setSwitchingModel] = useState(false);
    const [initialLoading, setInitialLoading] = useState(true); // 初始加载状态
    const videoAvatarRef = useRef(null);

    // 获取可用Avatar列表
    const fetchAvailableAvatars = async () => {
        setLoadingAvatars(true);
        try {
            const result = await adminService.getAvailableAvatars();
            if (result.success && result.data) {
                // 转换API响应格式
                let avatarList = [];
                if (typeof result.data === 'object' && !Array.isArray(result.data)) {
                    avatarList = Object.entries(result.data).map(([key, avatar]) => ({
                        id: key,
                        name: key,
                        description: avatar.description || `Avatar: ${key}`,
                        status: avatar.status || 'active'
                    }));
                } else if (Array.isArray(result.data)) {
                    avatarList = result.data.map(avatar => ({
                        id: avatar.name || avatar.id,
                        name: avatar.name || avatar.id,
                        description: avatar.description || `Avatar: ${avatar.name || avatar.id}`,
                        status: avatar.status || 'active'
                    }));
                }

                setAvailableAvatars(avatarList);

                // 设置默认选中的模型并自动启动
                if (avatarList.length > 0 && !selectedModel) {
                    const defaultAvatarId = avatarList[0].id;
                    setSelectedModel(defaultAvatarId);
                    // 自动启动默认avatar
                    adminService.startAvatar(defaultAvatarId).then(result => {
                        if (result.success) {
                            console.log(`Auto-started default avatar: ${defaultAvatarId}`);
                        } else {
                            console.warn(`Failed to auto-start avatar: ${result.message}`);
                        }
                    }).catch(error => {
                        console.error(`Error auto-starting avatar:`, error);
                    }).finally(() => {
                        // 无论成功或失败，都结束初始加载状态
                        setInitialLoading(false);
                    });
                } else {
                    setInitialLoading(false);
                }
            } else {
                console.warn('Failed to fetch available avatars:', result.message);
                // 使用默认模型
                setAvailableAvatars(defaultAiModels);
                if (!selectedModel) {
                    setSelectedModel(defaultAiModels[0].id);
                }
                setInitialLoading(false);
            }
        } catch (error) {
            console.error('Error fetching available avatars:', error);
            // 使用默认模型
            setAvailableAvatars(defaultAiModels);
            if (!selectedModel) {
                setSelectedModel(defaultAiModels[0].id);
            }
            setInitialLoading(false);
        } finally {
            setLoadingAvatars(false);
        }
    };

    // 切换Avatar模型
    const handleModelSwitch = async (modelId) => {
        if (modelId === selectedModel) return;

        // 如果正在初始加载，取消初始加载状态（用户主动切换）
        if (initialLoading) {
            setInitialLoading(false);
        }

        // 记录是否之前已连接
        const wasConnected = videoAvatarRef.current && videoAvatarRef.current.isConnected();

        setSwitchingModel(true);
        try {
            // 在切换avatar前，先断开当前的WebRTC连接
            if (wasConnected) {
                console.log('Disconnecting current WebRTC connection before switching avatar...');
                videoAvatarRef.current.stopConnection();
                // 给一点时间让连接完全断开
                await new Promise(resolve => setTimeout(resolve, 500));
            }

            const result = await adminService.startAvatar(modelId);
            if (result.success) {
                setSelectedModel(modelId);
                console.log(`Successfully switched to avatar: ${modelId}`);
                
                // 如果之前已连接，等待更长时间后自动重新连接
                // 增加等待时间以确保新的 WebRTC 服务完全启动
                if (wasConnected) {
                    console.log('Avatar switched successfully. Waiting 5 seconds before auto-reconnecting...');
                    setTimeout(() => {
                        if (videoAvatarRef.current) {
                            console.log('Auto-reconnecting to new avatar...');
                            videoAvatarRef.current.startConnection();
                        }
                    }, 5000); // 从3秒增加到5秒
                }
            } else {
                console.error('Failed to switch avatar:', result.message);
                alert(`Failed to switch avatar: ${result.message}`);
            }
        } catch (error) {
            console.error('Error switching avatar:', error);
            alert(`Error switching avatar: ${error.message}`);
        } finally {
            setSwitchingModel(false);
        }
    };

    // 组件加载时获取Avatar列表
    useEffect(() => {
        fetchAvailableAvatars();
    }, []);

    return (
        <div style={{
            flex: 6,
            background: themeStyles?.chatListBackground || '#F7F9FB',
            borderRadius: 16,
            margin: 8,
            padding: 16,
            display: 'flex',
            flexDirection: 'column',
            position: 'relative',
            transition: 'all 0.3s ease'
        }}>
            {/* 左上角 AI 模型選擇 */}
            <div style={{ position: 'absolute', top: 16, left: 16, zIndex: 50 }}>
                <div style={{ position: 'relative' }}>
                    <select
                        value={selectedModel}
                        onChange={(e) => handleModelSwitch(e.target.value)}
                        disabled={loadingAvatars}
                        style={{
                            padding: '8px 12px',
                            borderRadius: 8,
                            border: `1px solid ${themeStyles?.inputBorder || '#E2E2E2'}`,
                            background: themeStyles?.inputBackground || '#fff',
                            fontSize: 14,
                            fontWeight: 500,
                            color: themeStyles?.inputColor || '#333',
                            cursor: loadingAvatars ? 'not-allowed' : 'pointer',
                            minWidth: 140,
                            boxShadow: themeStyles?.shadow || '0 2px 8px rgba(0,0,0,0.1)',
                            appearance: 'none',
                            backgroundImage: `url("data:image/svg+xml;charset=UTF-8,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='currentColor' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3e%3cpolyline points='6,9 12,15 18,9'%3e%3c/polyline%3e%3c/svg%3e")`,
                            backgroundRepeat: 'no-repeat',
                            backgroundPosition: 'right 8px center',
                            backgroundSize: '16px',
                            paddingRight: '32px',
                            transition: 'all 0.3s ease',
                            opacity: loadingAvatars ? 0.6 : 1
                        }}
                    >
                        {loadingAvatars ? (
                            <option value="">Loading avatars...</option>
                        ) : availableAvatars.length > 0 ? (
                            availableAvatars.map(model => (
                                <option key={model.id} value={model.id}>
                                    {model.name}
                                </option>
                            ))
                        ) : (
                            <option value="">No avatars available</option>
                        )}
                    </select>

                    {/* 切换状态指示器 */}
                    {switchingModel && (
                        <div style={{
                            position: 'absolute',
                            top: '50%',
                            right: '40px',
                            transform: 'translateY(-50%)',
                            width: 16,
                            height: 16,
                            border: '2px solid #e0e0e0',
                            borderTop: '2px solid #1976d2',
                            borderRadius: '50%',
                            animation: 'spin 1s linear infinite'
                        }}></div>
                    )}

                    <div style={{
                        position: 'absolute',
                        top: '100%',
                        left: 0,
                        background: themeStyles?.inputBackground || '#fff',
                        borderRadius: 8,
                        boxShadow: '0 4px 16px rgba(0,0,0,0.15)',
                        padding: '8px 0',
                        marginTop: 4,
                        minWidth: 200,
                        display: 'none'
                    }}>
                        {availableAvatars.map(model => (
                            <div key={model.id} style={{
                                padding: '8px 12px',
                                fontSize: 12,
                                color: themeStyles?.placeholderColor || '#666',
                                borderBottom: '1px solid #f0f0f0'
                            }}>
                                {model.description}
                            </div>
                        ))}
                    </div>
                </div>
            </div>



            {/* 虛擬導師大頭像（改為方形視頻流+連接按鈕） */}
            <div style={{
                flex: 1,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                minHeight: 0,
                minWidth: 0
            }}>
                <VideoAvatar ref={videoAvatarRef} switchingAvatar={switchingModel} initialLoading={initialLoading} />
            </div>
        </div>
    );
}

export default HomeChatList; 