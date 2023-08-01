# 使用CentOS 7镜像作为基础镜像
FROM centos:7

RUN yum install -y centos-release-scl && \
    yum install -y devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-binutils && \
    scl enable devtoolset-11 bash

WORKDIR /app

# 将当前目录文件加入到工作目录/app中（如果有必要的话）
# ADD . /app

# 使用pip安装 llama-cpp-python
RUN bash ./install-python38.sh
RUN python3 -m pip install llama-cpp-python[server]==0.1.77

