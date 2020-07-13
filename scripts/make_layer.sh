# create directory into which packages will be installed
mkdir -p python/lib/python3.8/site-packages

# create directory for zipped layer to be stored
mkdir layers

# build packages in Lambda Docker container (specify Python version properly)
docker run -v "$PWD":/var/task "lambci/lambda:build-python3.8" /bin/sh -c \ "pip install -r requirements.txt -t python/lib/python3.8/site-packages; exit"

# remove extraneous files and directories
cd "python/lib/python3.8/site-packages" || exit
find . -type d -name "test" -exec rm -rf {} +
find . -type d -name "tests" -exec rm -rf {} +
find . -type d -name "__pycache__" -exec rm -rf {} +
rm -rf ./{caffe2,wheel,wheel-*,pkg_resources,boto*,aws*,pip,pip-*,pipenv,setuptools}
rm -rf ./{*.egg-info,*.dist-info}
find . -name \*.pyc -delete

# zip very large packages (like PyTorch or TensorFlow) individually -- these will ultimately be unzipped into Lambda's /tmp directory at runtime
zip -r9 requirements.zip torch
rm -rf torch

# add unzip_requirements module
cd "../../../.." || exit
cp -r unzip_requirements python/lib/python3.8/site-packages

# zip packages
zip -r9 PyTorch.zip python

# store zipped layer in layer
mv PyTorch.zip layers

# cleanup
rm -rf python
