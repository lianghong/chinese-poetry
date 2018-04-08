#!/usr/bin/env bash

dev_install () {
    sudo yum -y update
    sudo yum -y upgrade
    sudo yum install -y \
    wget \
    gcc \
    gcc-c++ \
    python36-devel \
    python36-virtualenv \
    python36-pip \
    findutils \
    zlib-devel \
    zip
}

pip_install () {
    if [ -d lambda_env ];then 
    	rm -rf lambda_env
    fi

    python3 -m virtualenv lambda_env --python=python3
    source lambda_env/bin/activate
    pip3 install -U pip wheel
    pip3 install --use-wheel numpy -U
    pip3 install --use-wheel tensorflow -U
    # pip install --use-wheel boto3 -U
    deactivate
}


gather_pack () {
    # packing
    source lambda_env/bin/activate
    if [ -d lambda_pack ]; then
    	rm -rf lambda_pack
    fi

    mkdir lambda_pack

    cp -R lambda_env/lib/python3.6/site-packages/* lambda_pack
    cp -R lambda_env/lib64/python3.6/site-packages/* lambda_pack
    cp src/*.py lambda_pack
    echo "original size $(du -sh lambda_pack | cut -f1)"

    cd lambda_pack
    # cleaning libs
    rm -rf external
    find . -type d -name "tests" -exec rm -rf {} +

    # cleaning
    find -name "*.so" | xargs strip
    find -name "*.so.*" | xargs strip
    # find . -name tests -type d -print0|xargs -0 rm -r --
    # find . -name test -type d -print0|xargs -0 rm -r --    
    rm -rf pip
    rm -rf pip-*
    rm -rf wheel
    rm -rf wheel-*
    rm easy_install.py
    rm -rf tensorboard
    rm -rf tensorboard-1.7.0.dist-info
    rm -rf setuptools
    rm -rf setuptools-39.0.1.dist-info
    rm -rf werkzeug
    rm -rf Werkzeug-0.14.1.dist-info
    rm -rf markdown
    rm -rf Markdown-2.6.11.dist-info 
    rm -rf html5lib
    rm -rf html5lib-0.9999999.dist-info 
    rm -rf termcolor-1.1.0.dist-info
    rm -rf bleach
    rm -rf bleach-1.5.0.dist-info 
    rm -rf docutils docutils-0.14.dist-info
    rm -rf jmespath 
    rm -rf jmespath-0.9.3.dist-info/
    rm -rf six.py setuputils.py
    rm -rf termcolor.py
    rm -rf protobuf-3.5.2.post1*
    rm -rf grpc*
    rm -rf gast*
    rm -rf astor*
    find . -name \*.pyc -delete
    # find . -name \*.txt -delete
    echo "stripped size $(du -sh ../lambda_pack | cut -f1)"

    #set file permissions, at least 444  	
    chmod u=rwx,go=r *.py

    # compressing
    zip -FS -r9 ../pack.zip * > /dev/null
    echo "compressed size $(du -sh ../pack.zip | cut -f1)"

}

main () {
    dev_install
    pip_install
    gather_pack
}

main
