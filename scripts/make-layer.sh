#!/bin/sh

# parse inputs
for arg in "$@"
do
    case $arg in
        --python=*) PYTHON_VERSION="${arg#*=}" shift;;
        --torch=*) TORCH_VERSION="${arg#*=}" shift;;
        --torchvision=*) TORCHVISION_VERSION="${arg#*=}" shift;;
        --torchaudio=*) TORCHAUDIO_VERSION="${arg#*=}" shift;;
        *) echo "ERROR: Invalid argument ${arg}" && exit 1;;
    esac
done

# get short_python_version from input python version
case ${PYTHON_VERSION} in
    2.7) SHORT_PYTHON_VERSION="cp27";;
    3.5) SHORT_PYTHON_VERSION="cp35";;
    3.6) SHORT_PYTHON_VERSION="cp36";;
    3.7) SHORT_PYTHON_VERSION="cp37";;
    3.8) SHORT_PYTHON_VERSION="cp38";;
    3.9) SHORT_PYTHON_VERSION="cp39";;
    "") echo "ERROR: No Python version specified" && exit 1;;
    *) echo "ERROR: Invalid Python version. Expected versions include: 2.7, 3.5, 3.6, 3.7, 3.8, 3.9" && exit 1;;
esac

# build torch wheel URL
case ${TORCH_VERSION} in
    "") "ERROR: No Torch version specified" && exit 1;;
    *) TORCH_WHEEL="https://download.pytorch.org/whl/cpu/torch-${TORCH_VERSION}%2Bcpu-${SHORT_PYTHON_VERSION}-${SHORT_PYTHON_VERSION}-linux_x86_64.whl";;
esac

# build torchvision wheel URL
case ${TORCHVISION_VERSION} in
    "") TORCHVISION_WHEEL="";;
    *) TORCHVISION_WHEEL="https://download.pytorch.org/whl/cpu/torchvision-${TORCHVISION_VERSION}%2Bcpu-${SHORT_PYTHON_VERSION}-${SHORT_PYTHON_VERSION}-linux_x86_64.whl";;
esac

# build torchaudio wheel URL
case ${TORCHAUDIO_VERSION} in
    "") TORCHAUDIO_WHEEL="";;
    *) TORCHAUDIO_WHEEL="https://download.pytorch.org/whl/torchaudio-${TORCHAUDIO_VERSION}-${SHORT_PYTHON_VERSION}-${SHORT_PYTHON_VERSION}-linux_x86_64.whl";;
esac

# create directory into which packages will be installed
mkdir -p python/lib/python${PYTHON_VERSION}/site-packages

# create directory for zipped layer to be stored
mkdir layers

# build packages in Lambda Docker container
docker run -v "$PWD":/var/task "lambci/lambda:build-python${PYTHON_VERSION}" /bin/sh -c \
"pip install \
${TORCH_WHEEL} \
${TORCHVISION_WHEEL} \
${TORCHAUDIO_WHEEL} \
-t python/lib/python${PYTHON_VERSION}/site-packages; exit" || exit 1

# remove extraneous files and directories
cd "python/lib/python${PYTHON_VERSION}/site-packages" || exit 1
find . -type d -name "test*" -exec rm -rf {} +
find . -type d -name "__pycache__" -exec rm -rf {} +
rm -rf ./{caffe2,wheel,wheel-*,pkg_resources,boto*,aws*,pip,pip-*,pipenv,setuptools}
rm -rf ./{*.egg-info,*.dist-info}
find . -name \*.pyc -delete

# zip very large packages (like PyTorch or TensorFlow) individually -- these will ultimately be unzipped into Lambda's /tmp directory at runtime
zip -r9 requirements.zip torch
rm -rf torch

# add unzip_requirements module
cd "../../../.." || exit 1
cp -r unzip_requirements python/lib/python${PYTHON_VERSION}/site-packages

# zip packages
zip -r9 PyTorch.zip python

# store zipped layer in layer
mv PyTorch.zip layers

# cleanup
rm -rf python
