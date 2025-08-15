# 使用官方Nginx镜像作为基础镜像
FROM nginx:alpine

# 维护者信息
LABEL maintainer="Your Name <your.email@example.com>"

# 将本地dist目录下的所有文件复制到Nginx的默认静态文件目录
COPY dist/ /usr/share/nginx/html/

# 复制自定义的Nginx配置文件（如果需要）
# 如果不需要特殊配置，可以注释掉这一行
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# 暴露5173端口
EXPOSE 5173

# 修改Nginx配置，将默认端口从80改为5173
RUN sed -i 's/listen       80;/listen       5173;/g' /etc/nginx/conf.d/default.conf

# 启动Nginx服务
CMD ["nginx", "-g", "daemon off;"]
    