"""
Setup script for Linux Package Installer
"""

from setuptools import setup, find_packages

with open("README.md", "r", encoding="utf-8") as fh:
    long_description = fh.read()

setup(
    name="linux-package-installer",
    version="1.0.0",
    author="Srijan-XI",
    author_email="shreejansamsung@gmail.com",
    description="A simple GUI tool to install .deb and .rpm packages on Linux",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/Srijan-XI/Linux-pi",
    packages=find_packages(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: End Users/Desktop",
        "Topic :: System :: Installation/Setup",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.6",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Operating System :: POSIX :: Linux",
        "Environment :: X11 Applications :: Qt",
    ],
    python_requires=">=3.6",
    install_requires=[
        "PyQt5>=5.15.0",
    ],
    entry_points={
        "console_scripts": [
            "linux-package-installer=main:main",
        ],
    },
    include_package_data=True,
    zip_safe=False,
)
