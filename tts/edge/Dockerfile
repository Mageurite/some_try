FROM python:3.10-slim

WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# 安装edge-tts和其他依赖
RUN pip install --no-cache-dir \
    edge-tts \
    fastapi \
    uvicorn \
    pydub \
    python-multipart

# 复制应用代码
COPY server.py .

# 暴露端口
EXPOSE 8604

# 启动命令
CMD ["python", "server.py", "--model_name", "edgeTTS", "--port", "8604", "--use_gpu", "false"]

