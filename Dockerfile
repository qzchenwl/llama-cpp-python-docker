FROM centos/python-38-centos7

WORKDIR /src

USER root
RUN yum install -y centos-release-scl && \
    yum install -y devtoolset-11-gcc devtoolset-11-gcc-c++ devtoolset-11-binutils

COPY . .

RUN pip install --upgrade pip pytest cmake scikit-build setuptools
RUN pip install wheel
RUN pip download llama-cpp-python
RUN tar xzf llama_cpp_python*.tar.gz
RUN scl enable devtoolset-11 -- cd llama_cpp_python* && python setup.py bdist_wheel
