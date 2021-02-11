BootStrap: docker
From: tensorflow/tensorflow:1.11.0-gpu-py3
# See version in requirements.txt
# Alternatively: From: nvidia/cuda:9.0-cudnn7-runtime-ubuntu18.04

%files
  ./ /opt/anonymizer

%post
  ls -d /opt/anonymizer/anonymizer
  touch /usr/bin/nvidia-smi
  echo "Compiling and installing project (including dependencies) in the image"
  apt-get update -y
  # You need the ssl packages to make the self-compiled pip work!
  DEBIAN_FRONTEND=noninteractive apt-get install -y\
    lsb-core locales zlib1g-dev wget openssl libssl-dev libffi-dev

  # Install python 3.6. I did not find an apt package, probably because of
  # Ubuntu 16.04?!
  cd /opt
  wget https://www.python.org/ftp/python/3.6.3/Python-3.6.3.tgz
  tar -xvf Python-3.6.3.tgz
  cd Python-3.6.3
  ./configure
  make
  make install
  cd /opt/anonymizer
  python3.6 -m ensurepip

  # Install requirements for the anonymizer
  python3.6 -m pip install -r requirements.txt

%environment
  export PYTHONPATH=${PYTHONPATH}:/opt/anonymizer

%help
  Use `singularity run --nv ...` on this container to run the anonymize.py
  script. Do not forget to add the --nv option!

%runscript
  python3.6 /opt/anonymizer/anonymizer/bin/anonymize.py "$@"
