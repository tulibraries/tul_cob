! /usr/bin/env bash

if [ -z "$WGET_VERSION"]; then
  WGET_VERSION='1.20.3'
fi

# Install any build dependencies needed for curl
sudo apt-get build-dep

# Get latest (as of Feb 25, 2016) libcurl
mkdir ~/wget
cd ~/wget

wget "https://ftp.gnu.org/gnu/wget/wget-$WGET_VERSION.tar.gz"
tar -xvzf wget-$WGET_VERSION.tar.gz
cd wget-$WGET_VERSION

# The usual steps for building an app from source
./configure
make
sudo make install
