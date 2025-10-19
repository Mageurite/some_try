# Scripts 目录

本目录包含项目的所有 Shell 脚本文件。

## 📝 脚本列表

### 启动和停止脚本

- **`start_all.sh`** - 启动所有服务（Backend, RAG, LLM, TTS, Avatar管理服务, Frontend）
- **`stop_all.sh`** - 停止所有服务
- **`docker-start.sh`** - Docker环境启动脚本

### 日志管理脚本

- **`view_logs.sh`** - 查看服务日志
- **`clear_logs.sh`** - 清理日志文件
- **`backup_logs.sh`** - 备份日志文件

### 测试和验证脚本

- **`test_tts_switch.sh`** - 测试TTS自动切换功能
- **`verify_audio_fix.sh`** - 验证音频修复

## 🚀 使用方法

### 从项目根目录运行

```bash
# 启动所有服务
./scripts/start_all.sh

# 停止所有服务
./scripts/stop_all.sh

# 查看日志
./scripts/view_logs.sh

# 清理日志
./scripts/clear_logs.sh
```

### 从scripts目录运行

```bash
cd scripts

# 启动所有服务
./start_all.sh

# 停止所有服务
./stop_all.sh
```

## 📌 注意事项

1. 运行脚本前确保有执行权限：`chmod +x scripts/*.sh`
2. 某些脚本需要在项目根目录运行才能正确找到相对路径
3. 启动脚本会检查依赖服务和端口占用情况
4. 停止脚本会安全地终止所有相关进程

## 🔧 脚本依赖

- **Conda环境**：bread, rag, avatar, edge
- **Node.js和npm**：用于Frontend服务
- **Python 3.x**：用于Backend和AI服务
- **端口要求**：8203, 8602, 8604, 8606, 8610, 8615, 3000

---

**最后更新**：2025年10月19日

