# 使用 Ubuntu 作为基础镜像
FROM ubuntu:22.04

# 设置非交互式安装，避免安装过程中的提示
ENV DEBIAN_FRONTEND=noninteractive

# 安装必要的工具：skopeo 和 jq
RUN apt-get update && apt-get install -y \
    skopeo \
    jq \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# 创建工作目录
WORKDIR /app

# 复制同步脚本到容器
COPY sync_images.sh /app/sync_images.sh

# 赋予脚本执行权限
RUN chmod +x /app/sync_images.sh

# 容器启动时运行脚本一次
CMD ["/app/sync_images.sh"]