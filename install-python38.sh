# yum install
yum install -y make zlib zlib-dev openssl-devel libffi gcc gcc-c++
yum install -y patch libffi-devel python-devel zlib-devel ncurses-devel sqlite-devel readline-devel tk-devel gdbm-devel db4-devel libpcap-devel xz-devel bzip2-devel expat-devel

# openssl-1.1.1 or newer is necessary for python 3.10.x
cd $HOME
wget https://ftp.openssl.org/source/old/1.1.1/openssl-1.1.1m.tar.gz --no-check-certificate
tar -xzf openssl-1.1.1m.tar.gz && cd openssl-1.1.1m
./config --prefix=/usr/local/openssl shared zlib
make && make install
echo "export LD_LIBRARY_PATH=LD_LIBRARY_PATH:/usr/lib:/usr/lib64:/usr/local/lib:/usr/local/lib64" >> /etc/profile.d/openssl.sh
source /etc/profile.d/openssl.sh
ln -sf /usr/local/openssl/include/openssl /usr/include/openssl
ln -sf /usr/local/openssl/lib/libssl.so.1.1 /usr/local/lib64/libssl.so
ln -sf /usr/local/openssl/bin/openssl /usr/bin/openssl
echo "/usr/local/openssl/lib" >> /etc/ld.so.conf
ldconfig

# python3.8.x
cd $HOME
wget https://www.python.org/ftp/python/3.8.12/Python-3.8.12.tgz -O Python-3.8.12.tgz
tar xzf Python-3.8.12.tgz && cd Python-3.8.12
./configure --prefix=/usr/local/python3.8.12 --with-openssl=/usr/local/openssl --enable-shared
make && make altinstall
ln -sf /usr/local/python3.8.12/bin/python3.8 /usr/bin/python3
ln -sf /usr/local/python3.8.12/bin/pip3.8 /usr/bin/pip3
echo "/usr/local/python3.8.12/lib/" >> /etc/ld.so.conf
ldconfig

# pip install
pip3 install virtualenv
ln -sf /usr/local/python3.8.12/bin/virtualenv /usr/bin/virtualenv

# dependency collection setup
to_real(){
    if [[ $1 ]]; then
        mv $1 $1"_real"  
    fi
    echo  $1"_real"
}
python3_exist=

if command -v python2 >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
    echo "Python 2 and Python 3 are both installed."    
    python3_exist=1

elif command -v python2 >/dev/null 2>&1; then
    echo "Only Python 2 is installed."
    
elif command -v python3 >/dev/null 2>&1; then
    echo "Only Python 3 is installed."
    python3_exist=1
else
    echo "Neither Python 2 nor Python 3 is installed."
fi

if [[ python3_exist -eq 1 ]]; then
    echo "python3 configure..."
    patch_version=`python3 --version | awk '{print $2}' `
    major_version=`python3 --version | awk '{print $2}' | cut -d "." -f 1`
    minor_version=`python3 --version | awk '{print $2}' | cut -d "." -f 1,2`
fi

if [[ $major_version -eq 3 ]]; then
    echo "设置依赖收集"

    #获取原始pip，virtualenv的路径
    virtualenv_path=`which virtualenv`
    virtual_real=$(to_real $virtualenv_path)
    pip_path=`which pip`
    pip3_path=`which pip3`
    pip3x_path=`which pip${minor_version}`

    # 修改原始的pip
    _=$(to_real $pip_path)
    pip3_real=$(to_real $pip3_path)
    _=$(to_real $pip3x_path)

    # 构建新的pip
    cat <<EOF > $pip3_path
#!/usr/bin/sh 

pip3_real "\$@"
if [[ \$1 == "install" ]]; then
    echo "开始收集依赖信息"

    # 创建依赖信息存储目录
    mkdir -p \$PLUS_METADATA_DIR
    pip3_real install pipdeptree > /dev/null
    pipdeptree -j > \$PLUS_METADATA_DIR/default_python_dependency_temp.json

    # 创建依赖收集脚本
    cat << EEEE > collect.py
import json
import os


def get_map(origin: list) -> dict:
    module_map = {}
    pipdeptree_module = list()
    for module in origin:
        if module["package"]["key"] != "pipdeptree":
            module_map[module["package"]["key"]] = {}
            module_map[module["package"]["key"]]["module"] = module
            module_map[module["package"]["key"]]["used"] = False
        else:
            pipdeptree_module = module
    origin.remove(pipdeptree_module)
    return module_map


def to_module(module: dict, module_map: dict) -> dict:
    result = {}
    result[module["package"]["key"]] = {}
    result[module["package"]["key"]]["Package"] = module["package"]["key"] + "@" + module["package"][
        "installed_version"]
    result[module["package"]["key"]]["Dependencies"] = []
    for dependency in module["dependencies"]:
        module_map[dependency["key"]]["used"] = True
        result[module["package"]["key"]]["Dependencies"].append(
            to_module(module_map[dependency["key"]]["module"], module_map)[dependency["key"]])
    return result


if __name__ == "__main__":
    project_name = os.environ.get('PLUS_RELEASE_NAME')
    path = os.environ.get('PLUS_METADATA_DIR')
    with open(path+"/default_python_dependency_temp.json", "r") as f:
        raw = f.read()
        data = json.loads(raw)
        
        module_map = get_map(data)
        result = {}

        for module in data:
            ans = to_module(module, module_map)
            result[module["package"]["key"]] = ans
        project_dependency = {}
        project_dependency["ComponentType"] = "pip"
        project_dependency["Package"] = project_name
        project_dependency["Dependencies"] = []
        for k, v in result.items():
            if not module_map[k]["used"]:
                project_dependency["Dependencies"].append(v[k])
                    
        with open(path+"/"+project_name + "_python_dependency.json", "w") as f:
            f.write(json.dumps(project_dependency))
EEEE

    python3 collect.py
    rm collect.py
    rm \$PLUS_METADATA_DIR/default_python_dependency_temp.json
    echo "依赖信息收集完毕"
fi
EOF

# virtualenv configuration
    cat <<EOFF > $virtualenv_path 
#!/usr/bin/sh -x
to_real(){
    if [[ \$1 ]]; then
        mv \$1 \$1"_real"  
    fi
    echo  \$1"_real"
}

# 初始化变量
venv_path=""
venv_name=""
python_path=""
options=""

# 执行真正的virtualenv
virtualenv_real "\$@"

# 解析命令行参数
for arg in "\$@"; do
  case "\$arg" in
    -p|--python)
      # 如果碰到 -p 参数，则下一个参数是 Python 解释器的路径，必须独立判断
      python_path="\$2"
      shift 2
      ;;
    -*)
      # 将选项保存到变量 options 中
      options="\$options \$1"
      shift
      ;;
    *)
      if [[ -z "\$venv_path" ]]; then
        # 如果还没有找到虚拟环境的路径，则这个参数就是它
        venv_path="\$1"
        venv_name=\$(basename "\$venv_path")
        # 如果虚拟环境的名称中包含 Python 版本号，则去掉版本号后缀
        venv_name=\${venv_name%*-}
        shift
      else
        # 否则，虚拟环境的路径已经提前给出了
        venv_name="\$arg"
        shift
      fi
      ;;
  esac
done

# 检查虚拟环境名称是否已经指定，未指定则不是创建虚拟环境命令
if [[ \$venv_name != "" ]]; then
    _=\$(to_real \$venv_path/bin/pip)
    pip_real=\$(to_real \$venv_path/bin/pip3)
    _=\$(to_real \$venv_path/bin/pip${minor_version})
    _=\$(to_real \$venv_path/bin/pip-${minor_version})

    # 由于virtualenv会自动设置PATH环境变量，因此我们可以直接复制之前修改过的系统pip，这里必须指定是系统的pip3
    cp /usr/bin/pip3  \$venv_path/bin/pip3
    
    # 为虚拟环境的新建pip添加权限
    chmod a+rx \$venv_path/bin/pip3
    cp  \$venv_path/bin/pip3 \$venv_path/bin/pip
    cp  \$venv_path/bin/pip3 \$venv_path/bin/pip${minor_version}
    cp  \$venv_path/bin/pip3 \$venv_path/bin/pip-${minor_version}

fi
EOFF
    echo "依赖收集设置完毕"
    chmod a+rx $pip3_path 
    chmod a+rx $virtualenv_path
    if [[ $pip_path != "" ]]; then
        cp $pip3_path $pip_path 
    fi
    if [[ $pip3x_path != "" ]]; then
        cp $pip3_path $pip3x_path
    fi
    
fi
