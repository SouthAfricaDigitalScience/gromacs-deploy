#!/bin/bash -e
. /etc/profile.d/modules.sh
# This is the build script for GROMACS
# ftp://ftp.gromacs.org/pub/gromacs
SOURCE_REPO="ftp://ftp.gromacs.org/pub/gromacs/"
# NAME and VERSION are provided by the build job.
SOURCE_FILE="${NAME}-${VERSION}.tar.gz"

module add ci
module add gmp
module add mpfr
module add mpc
# GCC_VERSION is provided by the build job
module add gcc/${GCC_VERSION}
# We need cmake to configure the build
module add cmake
# LAPACK has the external linear algebra libraries
# see http://www.gromacs.org/Documentation/Installation_Instructions_5.0#linear-algebra-libraries
module add lapack/3.6.0-gcc-${GCC_VERSION}
module add openmpi/${OPENMPI_VERSION}-gcc-${GCC_VERSION}
module add fftw/3.3.4-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
module add boost/1.59.0-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}

# check some variables

echo "BOOST DIR is : ${BOOST_DIR}"
echo "FFTW3 DIR is : ${FFTW_DIR}"
echo "OPENMPI_DIR is : ${OPENMPI_DIR}"
echo "BLAS_DIR is : ${LAPACK_DIR}"
echo "LD_LIBRARY_PATH is : ${LD_LIBRARY_PATH}"

echo "libraries are : "
ls ${BOOST_DIR}/lib
echo ""
ls ${OPENMPI_DIR}/lib
echo ""
ls ${LAPACK_DIR}/lib
echo ""
ls ${FFTW_DIR}/lib

echo "REPO_DIR is "
echo $REPO_DIR
echo "SRC_DIR is "
echo $SRC_DIR
echo "WORKSPACE is "
echo $WORKSPACE
echo "SOFT_DIR is"
echo $SOFT_DIR

mkdir -p ${WORKSPACE}
mkdir -p ${SRC_DIR}
mkdir -p ${SOFT_DIR}

#  Download the source file

if [ ! -e ${SRC_DIR}/${SOURCE_FILE}.lock ] && [ ! -s ${SRC_DIR}/${SOURCE_FILE} ] ; then
  touch  ${SRC_DIR}/${SOURCE_FILE}.lock
  echo "seems like this is the first build - Let's get the $SOURCE_FILE from $SOURCE_REPO and unarchive to $WORKSPACE"
  mkdir -p $SRC_DIR
  wget $SOURCE_REPO/$SOURCE_FILE -O $SRC_DIR/$SOURCE_FILE
  echo "releasing lock"
  rm -v ${SRC_DIR}/${SOURCE_FILE}.lock
elif [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; then
  # Someone else has the file, wait till it's released
  while [ -e ${SRC_DIR}/${SOURCE_FILE}.lock ] ; do
    echo " There seems to be a download currently under way, will check again in 5 sec"
    sleep 5
  done
else
  echo "continuing from previous builds, using source at " ${SRC_DIR}/${SOURCE_FILE}
fi


tar -xzf ${SRC_DIR}/${SOURCE_FILE} -C ${WORKSPACE} --skip-old-files
ls ${WORKSPACE}
mkdir -p ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
cd ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
echo "now in ${PWD}"
echo "Setting compilers"
export CC=mpicc
export CXX=mpicxx
echo "Configuring the build"
CFLAGS=-fPIC cmake .. \
-G"Unix Makefiles" \
-DGMX_X11=OFF \
-DFFTW_LIBRARY='${FFTW_DIR}/lib/libfftw3.so' \
-DGMX_FFT_LIBRARY=fftw3 \
-DGMX_DOUBLE=ON \
-DGMX_OPENMP=ON \
-DGMX_MPI=ON \
-DGMX_EXTERNAL_BLAS=on \
-DGMX_BUILD_MDRUN_ONLY=ON \
-DCMAKE_PREFIX_PATH="${BOOST_DIR}:${LAPACK_DIR}:${FFTW_DIR}" \
-DCMAKE_INSTALL_PREFIX=${SOFT_DIR}/${VERSION}-mpi-${OPENMPI_VERSION}-gcc-${GCC_VERSION}

echo "Running the build"
make all
