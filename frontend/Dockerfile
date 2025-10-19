FROM node:18-alpine

WORKDIR /app

# 复制package文件
COPY package*.json ./

# 安装依赖
RUN npm install

# 复制应用代码
COPY . .

# 构建生产版本（可选）
# RUN npm run build

# 暴露端口
EXPOSE 3002

# 开发模式启动
ENV PORT=3002
ENV BROWSER=none
CMD ["npm", "start"]

# 生产模式（如果使用build）
# FROM nginx:alpine
# COPY --from=0 /app/build /usr/share/nginx/html
# EXPOSE 80
# CMD ["nginx", "-g", "daemon off;"]

