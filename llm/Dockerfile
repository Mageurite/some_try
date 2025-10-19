FROM python:3.10-slim

WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# 复制依赖文件
COPY requirements.txt .

# 安装Python依赖（过滤掉内置模块）
RUN grep -v "^sqlite3\|^logging\|^datetime\|^json\|^threading\|^queue" requirements.txt > /tmp/requirements_filtered.txt && \
    pip install --no-cache-dir -r /tmp/requirements_filtered.txt

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 8610

# 启动命令
CMD ["python", "api_interface.py"]






