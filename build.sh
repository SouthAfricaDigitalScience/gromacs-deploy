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
echo "BOOST ROOT is : ${BOOST_ROOT}"
echo "FFTW3 DIR is : ${FFTW_DIR}"
echo "OPENMPI DIR is : ${OPENMPI_DIR}"
echo "LAPACK DIR is : ${LAPACK_DIR}"
echo "LD_LIBRARY_PATH is : ${LD_LIBRARY_PATH}"
echo "CFLAGS are : ${CFLAGS}"

echo "BOOST libraries in ${BOOST_DIR}/lib are: "
ls ${BOOST_DIR}/lib
echo "MPI libraries in ${OPENMPI_DIR}/lib are :"
ls ${OPENMPI_DIR}/lib
echo "LAPACK libraries in ${LAPACK_DIR}/lib* are : "
ls ${LAPACK_DIR}/lib*
echo "FFTW libraries in ${FFTW_DIR}/lib are : "
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
# CMake needs BOOST_ROOT
export BOOST_ROOT=${BOOST_DIR}
echo "Configuring the build"
export CFLAGS="${CFLAGS} -fPIC"
cmake .. \
-G"Unix Makefiles" \
-DCMAKE_C_COMPILER=mpicc \
-DCMAKE_CXX_COMPILER=mpicxx \
-DGMX_X11=OFF \
-DGMX_FFT_LIBRARY=fftw3 \
-DFFTW_LIBRARY=${FFTW_DIR}/lib/libfftw3.so \
-DGMX_DOUBLE=ON \
-DGMX_GPU=OFF \
-DGMX_OPENMP=ON \
-DGMX_MPI=ON \
-DGMX_EXTERNAL_BLAS=on \
-DGMX_BUILD_MDRUN_ONLY=ON \
-DCMAKE_INCLUDE_PATH="${BOOST_DIR}/include/boost;${FFTW_DIR}/include;${OPENMPI_DIR}/include;${LAPACK_DIR}/include" \
-DCMAKE_LIBRARY_PATH="${BOOST_DIR}/lib/boost;${FFTW_DIR}/lib;${OPENMPI_DIR}/lib;${LAPACK_DIR}/lib" \
-DCMAKE_PREFIX_PATH="${BOOST_DIR}/boost;${LAPACK_DIR};${FFTW_DIR};${OPENMPI_DIR}" \
-DREGRESSIONTEST_DOWNLOAD=ON \
-DCMAKE_INSTALL_PREFIX=${SOFT_DIR}/${VERSION}-mpi-${OPENMPI_VERSION}-gcc-${GCC_VERSION}

echo "Running the build"
make all
