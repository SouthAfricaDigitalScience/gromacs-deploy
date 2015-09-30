#!/bin/bash -e
# This is the build script for GROMACS
# ftp://ftp.gromacs.org/pub/gromacs
SOURCE_REPO="ftp://ftp.gromacs.org/pub/gromacs/"
# NAME and VERSION are provided by the build job.
SOURCE_FILE="${NAME}-${VERSION}.tar.gz"

module add ci
# GCC_VERSION is provided by the build job
module add gcc/${GCC_VERSION}
module add cmake
# Need to load a scheduler
module add fftw/3.3.4
module add openmpi


echo "REPO_DIR is "
echo $REPO_DIR
echo "SRC_DIR is "
echo $SRC_DIR
echo "WORKSPACE is "
echo $WORKSPACE
echo "SOFT_DIR is"
echo $SOFT_DIR

mkdir -p $WORKSPACE
mkdir -p $SRC_DIR
mkdir -p $SOFT_DIR

#  Download the source file

if [[ ! -e $SRC_DIR/$SOURCE_FILE ]] ; then
  echo "seems like this is the first build - Let's get the $SOURCE_FILE from $SOURCE_REPO and unarchive to $WORKSPACE"
  mkdir -p $SRC_DIR
  wget $SOURCE_REPO/$SOURCE_FILE -O $SRC_DIR/$SOURCE_FILE
else
  echo "continuing from previous builds, using source at " $SRC_DIR/$SOURCE_FILE
fi

tar -xzf $SRC_DIR/$SOURCE_FILE -C $WORKSPACE
cd $WORKSPACE/$NAME-$VERSION

echo "Configuring the build"
cmake -G"Unix Makefiles"

echo "Running the build"
make all
