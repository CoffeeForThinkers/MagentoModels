#!/usr/bin/env python2.7

import os.path
import setuptools

import mm

_APP_PATH = os.path.dirname(mm.__file__)

with open(os.path.join(_APP_PATH, 'resources', 'README.rst')) as f:
      _LONG_DESCRIPTION = f.read()

with open(os.path.join(_APP_PATH, 'resources', 'requirements.txt')) as f:
      _INSTALL_REQUIRES = list(map(lambda s: s.strip(), f))

setuptools.setup(
    name='magento_models',
    version=mm.__version__,
    description="Magento DB routine interfaces",
    long_description=_LONG_DESCRIPTION,
    classifiers=[],
    keywords='',
    author='Dustin Oprea',
    author_email='dustin@randomingenuity.com',
    url='https://github.com/CoffeeForThinkers/MagentoModels',
    license='GPL3',
    packages=setuptools.find_packages(exclude=['dev']),
    include_package_data=True,
    zip_safe=False,
    install_requires=_INSTALL_REQUIRES,
    package_data={
        'mm': [
            'resources/README.rst',
            'resources/requirements.txt',
        ],
    },
    scripts=[
    ],
)
