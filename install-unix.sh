#! /bin/sh

LOCAL=false

# arguments
if [ $# -ne 0 ]; then
   if [ "$1" = "-l" ]; then
      LOCAL=true
   else
      echo "Usage: install-linux.sh {-l}"
      echo "  -l  Install locally"
      exit 1
   fi
fi

if ! $LOCAL; then
   if ! [ $USER = "root" ]; then
      echo "Cannot install globally without root privileges"
      echo "Run install-linux.sh -l to install locally"
      exit 1
   fi
fi

# check for dependencies
which crystal > /dev/null 2>&1
if [ $? -ne 0 ]; then
   abort "crystal not found, aborting installation"
fi

which shards > /dev/null 2>&1
if [ $? -ne 0 ]; then
   abort "shards not found somehow, aborting installation"
fi

if [ -d "src" ]; then
   cd src
else
   abort "src directory not found, aborting installation"
fi

# compile
echo "Installing shards..."

shards install
if [ $? -ne 0 ]; then
   abort "shards install failed, aborting installation"
fi

echo "Compiling the code"

crystal build ptts.cr
if [ $? -ne 0 ]; then
   abort "crystal build failed, aborting installation"
fi

# install
BIN_DIR="/usr/local/bin/"
DATA_DIR="/usr/local/share/ptts/"

if $LOCAL; then
   BIN_DIR="$HOME/.local/bin/"
   DATA_DIR="$HOME/.local/share/ptts/"
fi

echo "making directories"
mkdir -p $DATA_DIR

echo "copying data"
mkdir -p $BIN_DIR
cp ptts $BIN_DIR
cp -r ../data/Hack/* $DATA_DIR

echo "Done!"
printf "\033[32minstalled to: $BIN_DIR\033[0m"

which xelatex > /dev/null 2>&1
if [ $? -ne 0 ]; then
   printf "\033[31mWARNING: xelatex not found, exporting to pdf won't work!\033[0m"
fi
