# 使用CentOS 7镜像作为基础镜像
FROM centos:7

# 更新软件包列表并安装EPEL Repository
RUN yum update -y && \
    yum install -y epel-release && \
    yum install -y https://repo.ius.io/ius-release-el7.rpm && \
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-IUS-7

# 安装Python3.8
RUN yum install -y python38 python38-pip python38-devel

# 将工作目录设置为/app
WORKDIR /app

# 将当前目录文件加入到工作目录/app中（如果有必要的话）
# ADD . /app

# 使用pip安装 llama-cpp-python
RUN python3.8 -m pip install llama-cpp-python[server]

