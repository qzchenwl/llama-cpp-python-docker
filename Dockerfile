# 使用CentOS 7镜像作为基础镜像
FROM centos:7

# 更新软件包列表并安装EPEL Repository
RUN yum install -y epel-release && \
    sed -i 's|^#baseurl=https://download.fedoraproject.org/pub/epel|baseurl=https://mirrors.aliyun.com/epel|g' /etc/yum.repos.d/epel.repo && \
    sed -i 's|^metalink|#metalink|g' /etc/yum.repos.d/epel.repo && \
    yum clean all && \
    yum makecache

# 安装Python3.8
RUN yum install -y python38 python38-pip python38-devel

# 将工作目录设置为/app
WORKDIR /app

# 将当前目录文件加入到工作目录/app中（如果有必要的话）
# ADD . /app

# 使用pip安装 llama-cpp-python
RUN python3.8 -m pip install llama-cpp-python[server]

