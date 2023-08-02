FROM centos/python-38-centos7

WORKDIR /src

USER root
RUN yum install -y centos-release-scl && \
    yum install -y devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-binutils

COPY . .

RUN pip install --upgrade pip pytest cmake scikit-build setuptools
RUN pip install wheel
RUN pip download llama-cpp-python==0.1.77
RUN tar xzf llama_cpp_python*.tar.gz
RUN cd llama_cpp_python-0.1.77 && ls && scl enable devtoolset-11 -- python setup.py bdist_wheel
