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

# derive short_python_version from input python version
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
    *) TORCH_WHEEL="https://download.pytorch.org/whl/cpu/torch-${TORCH_VERSION}%2Bcpu-${SHORT_PYTHON_VERSION}-${SHORT_PYTHON_VERSION}n-linux_x86_64.whl";;
esac

# build torchvision wheel URL
case ${TORCHVISION_VERSION} in
    "") TORCHVISION_WHEEL="";;
    *) TORCHVISION_WHEEL="https://download.pytorch.org/whl/cpu/torchvision-${TORCHVISION_VERSION}%2Bcpu-${SHORT_PYTHON_VERSION}-${SHORT_PYTHON_VERSION}n-linux_x86_64.whl";;
esac

# build torchaudio wheel URL
case ${TORCHAUDIO_VERSION} in
    "") TORCHAUDIO_WHEEL="";;
    *) TORCHAUDIO_WHEEL="https://download.pytorch.org/whl/torchaudio-${TORCHAUDIO_VERSION}-${SHORT_PYTHON_VERSION}-${SHORT_PYTHON_VERSION}n-linux_x86_64.whl";;
esac

# cleanup function to run if the script errors
failure_cleanup()
{
    echo "Cleaning up due to failure..."
    rm -rf python layers
    exit 1
}

# create directory into which packages will be installed
mkdir -p python/lib/python${PYTHON_VERSION}/site-packages

# create directory for zipped layer to be stored
mkdir layers

# build packages in Lambda Docker container
echo "Building Python packages with Docker...\n"
docker run -v "$PWD":/var/task "lambci/lambda:build-python${PYTHON_VERSION}" /bin/sh -c \
"pip install \
${TORCH_WHEEL} \
${TORCHVISION_WHEEL} \
${TORCHAUDIO_WHEEL} \
-t python/lib/python${PYTHON_VERSION}/site-packages; exit" || failure_cleanup

# remove extraneous files and directories
echo "Removing extraneous files/directories...\n"
cd "python/lib/python${PYTHON_VERSION}/site-packages" || failure_cleanup
find . -type d -name "tests" -exec rm -rf {} +
find . -type d -name "__pycache__" -exec rm -rf {} +
rm -rf ./{caffe2,wheel,wheel-*,pkg_resources,boto*,aws*,pip,pip-*,pipenv,setuptools}
rm -rf ./{*.egg-info,*.dist-info}
find . -name \*.pyc -delete

# zip very large packages (like PyTorch or TensorFlow) individually -- these will ultimately be unzipped into Lambda's /tmp directory at runtime
echo "Zipping torch package individually...\n"
zip -r9 -q requirements.zip torch || failure_cleanup
rm -rf torch

# add unzip_requirements module to site-packages
echo "Adding unzip_requirements module to layer...\n"
cd "../../../.." || failure_cleanup
cp -r unzip_requirements python/lib/python${PYTHON_VERSION}/site-packages || failure_cleanup

# zip packages
echo "Zipping complete layer...\n"
zip -r9 -q PyTorch.zip python || failure_cleanup

# store zipped layer in layers
echo "Storing zipped layer in layers/\n"
mv PyTorch.zip layers || failure_cleanup

# cleanup
echo "Cleaning up...\n"
rm -rf python

echo "Done!"
