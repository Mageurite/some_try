# 日志目录说明

## 📁 日志文件列表

所有系统服务的日志都存储在此目录：

| 日志文件 | 服务 | 端口 | 说明 |
|---------|------|------|------|
| `backend.log` | Backend服务 | 8203 | 后端API服务 |
| `rag.log` | RAG服务 | 8602 | 知识库检索服务 |
| `llm.log` | LLM服务 | 8610 | AI对话生成服务 |
| `edge_tts.log` | Edge TTS服务 | 8604 | 语音合成服务（默认） |
| `avatar_manager.log` | Avatar管理 | 8606 | Avatar管理服务 |
| `frontend.log` | Frontend | 3000 | 前端React应用 |

## 📖 查看日志

### 查看单个服务日志（实时）
```bash
# 查看Backend日志
tail -f logs/backend.log

# 查看RAG日志
tail -f logs/rag.log

# 查看LLM日志
tail -f logs/llm.log

# 查看TTS日志
tail -f logs/edge_tts.log

# 查看Avatar管理日志
tail -f logs/avatar_manager.log

# 查看Frontend日志
tail -f logs/frontend.log
```

### 查看所有日志（实时）
```bash
tail -f logs/*.log
```

### 查看最近100行日志
```bash
tail -100 logs/backend.log
```

### 搜索日志中的错误
```bash
# 搜索所有ERROR
grep -i "error" logs/*.log

# 搜索特定服务的错误
grep -i "error" logs/backend.log

# 搜索WARNING和ERROR
grep -iE "warning|error" logs/*.log
```

## 🧹 清理日志

### 清理所有日志
```bash
rm logs/*.log
```

### 清理单个日志
```bash
rm logs/backend.log
```

### 备份后清理
```bash
# 创建备份
tar -czf logs_backup_$(date +%Y%m%d_%H%M%S).tar.gz logs/*.log

# 清理
rm logs/*.log
```

## 🔍 日志分析

### 查看日志文件大小
```bash
ls -lh logs/
```

### 统计错误数量
```bash
grep -c "ERROR" logs/backend.log
```

### 查看最近的错误
```bash
grep -i "error" logs/*.log | tail -20
```

## 📊 日志轮转（可选）

如果日志文件太大，可以手动分割：

```bash
# 分割大文件
split -l 10000 logs/backend.log logs/backend_split_

# 压缩旧日志
gzip logs/backend_split_*
```

## ⚙️ 自动日志管理

使用提供的脚本：

```bash
# 查看所有日志摘要
./view_logs.sh

# 清理所有日志
./clear_logs.sh

# 备份日志
./backup_logs.sh
```

## 📝 注意事项

1. **日志自动创建**：运行 `start_all.sh` 时自动创建日志文件
2. **日志不会自动清理**：需要手动清理或使用脚本
3. **日志位置固定**：所有日志都在项目的 `logs/` 目录下
4. **实时日志**：服务运行时持续写入日志
5. **磁盘空间**：注意监控日志文件大小，避免占满磁盘

## 🆘 常见问题

### Q: 日志文件不存在？
A: 确认服务是否已启动，运行 `./start_all.sh`

### Q: 日志太大怎么办？
A: 清理旧日志 `rm logs/*.log`，或者压缩 `gzip logs/*.log`

### Q: 如何查看历史日志？
A: 日志会持续追加，可以使用 `less` 或 `vim` 查看完整内容

### Q: 日志没有更新？
A: 检查服务是否正在运行 `ps aux | grep python`






