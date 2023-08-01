# 使用CentOS 7镜像作为基础镜像
FROM centos:7

RUN yum install -y centos-release-scl && \
    yum install -y devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-binutils && \
    scl enable devtoolset-11 bash

# 安装Python3.8
RUN yum -y install openssl-devel bzip2-devel expat-devel gdbm-devel readline-devel sqlite-devel && \
    yum -y install gcc automake autoconf libtool make wget && \
    yum -y install yum-utils && \
    yum -y install libffi-devel && \
    yum-builddep -y python
RUN mkdir -p /usr/local/python/python3.8 && \
    cd /usr/local/python/python3.8 && \
    curl -O https://www.python.org/ftp/python/3.8.0/Python-3.8.0.tgz && \
    tar xf Python-3.8.0.tgz && \
    cd Python-3.8 && \
    ./configure && \
    make && make install && \
    wget https://bootstrap.pypa.io/get-pip.py && \
    /usr/local/bin/python3.8 get-pip.py

WORKDIR /app

# 将当前目录文件加入到工作目录/app中（如果有必要的话）
# ADD . /app

# 使用pip安装 llama-cpp-python
RUN python3.8 -m pip install llama-cpp-python[server]==0.1.77

