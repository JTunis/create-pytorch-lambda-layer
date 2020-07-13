import os
import shutil
import sys
import zipfile


pkg_dir = '/tmp/python-requirements'

# Add package_dir to our path so Python will know to look there for packages
sys.path.insert(1, pkg_dir)

if not os.path.exists(pkg_dir):
    temp_dir = '/tmp/_temp-python-requirements'
    if os.path.exists(temp_dir):
        shutil.rmtree(temp_dir)

    python_package_root = '/opt/python/lib/python3.8/site-packages'  # location of installed Python packages 
    zip_requirements = os.path.join(python_package_root, 'requirements.zip')

    zipfile.ZipFile(zip_requirements, 'r').extractall(temp_dir)
    os.rename(temp_dir, pkg_dir)
