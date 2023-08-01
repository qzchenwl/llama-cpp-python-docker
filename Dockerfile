# 使用CentOS 7镜像作为基础镜像
FROM centos/python-38-centos7

RUN yum install -y centos-release-scl && \
    yum install -y devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-binutils

RUN scl enable devtoolset-11 -- python3 -m pip install llama-cpp-python[server]==0.1.77

