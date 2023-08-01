# 使用已预装了Python3.8的CentOS 7镜像作为基础镜像
FROM centos:7

# 更新软件包列表并安装必要的Python3和开发工具
RUN yum update -y && \
    yum install -y https://centos7.iuscommunity.org/ius-release.rpm && \
    yum install -y python38 python38-pip python38-devel gcc

# 将工作目录设置为/app
WORKDIR /app

# 将当前目录文件加入到工作目录/app中（如果有必要的话）
# ADD . /app

# 使用pip安装 llamacpp_python
RUN python3.8 -m pip install llama-cpp-python[server]

