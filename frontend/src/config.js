// API Configuration
// 使用环境变量配置，支持通过 .env 文件自定义
const config = {
    get BACKEND_URL() {
        return process.env.REACT_APP_BACKEND_URL || 'http://localhost:8203';
    },
    get BACKEND_API_URL() {
        return `${this.BACKEND_URL}/api`;
    },
    get LIPSYNC_MANAGER_URL() {
        return process.env.REACT_APP_LIPSYNC_MANAGER_URL || 'http://localhost:8606';
    },
    get WEBRTC_URL() {
        return process.env.REACT_APP_WEBRTC_URL || 'http://localhost:8615';
    },
    get TTS_URL() {
        return process.env.REACT_APP_TTS_URL || 'http://localhost:8604';
    }
};

export default config;

