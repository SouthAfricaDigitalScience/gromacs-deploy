#!/bin/bash -e
. /etc/profile.d/modules.sh
# This is the build script for GROMACS
# ftp://ftp.gromacs.org/pub/gromacs
SOURCE_REPO="ftp://ftp.gromacs.org/pub/gromacs/"
# NAME and VERSION are provided by the build job.
SOURCE_FILE="${NAME}-${VERSION}.tar.gz"

module add ci
# GCC_VERSION and OPENMPI_VERSION are provided by the build job
module add gcc/${GCC_VERSION}
module add cmake
module add lapack/3.6.0-gcc-${GCC_VERSION}
module add openblas/0.2.15-gcc-${GCC_VERSION}
module add openmpi/${OPENMPI_VERSION}-gcc-${GCC_VERSION}
module add fftw/3.3.4-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
module add boost/1.62.0-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
module add gsl/2.0

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
#-DFFTW_LIBRARY="${FFTW_DIR}/lib/libfftw3l.so;${FFTW_DIR}/lib/libfftw3f.so;${FFTW_DIR}/lib/libfftw3.so;${FFTW_DIR}/lib/libfftw3f_mpi.so;${FFTW_DIR}/lib/libfftw3f_omp.so;${FFTW_DIR}/lib/libfftw3f.so;${FFTW_DIR}/lib/libfftw3f_threads.so;${FFTW_DIR}/lib/libfftw3l_mpi.so;${FFTW_DIR}/lib/libfftw3l_omp.so;${FFTW_DIR}/lib/libfftw3l.so${FFTW_DIR}/lib/libfftw3l_threads.so;${FFTW_DIR}/lib/libfftw3_mpi.so${FFTW_DIR}/lib/libfftw3.so" \
echo $BOOST_DIR
cmake ../ \
-G"Unix Makefiles" \
-DCMAKE_C_COMPILER=mpicc \
-DCMAKE_CXX_COMPILER=mpicxx \
-DGMX_X11=OFF \
-DGMX_FFT_LIBRARY=fftw3 \
-DFFTW_LIBRARY=${FFTW_DIR}/lib/libfftw3.so \
-DFFTW_INCLUDE_DIR=${FFTW_DIR}/include \
-DGMX_BLAS_USER=${OPENBLAS_DIR}/lib/libopenblas.so \
-DBoost_DIR=${BOOST_DIR} \
-DGMX_GSL=ON \
-DGMX_DOUBLE=ON \
-DGMX_GPU=OFF \
-DGMX_OPENMP=ON \
-DGMX_MPI=ON \
-DGMX_TEST_NUMBER_PROCS=1 \
-DGMX_EXTERNAL_BOOST=ON \
-DGMX_EXTERNAL_BLAS=ON \
-DREGRESSIONTEST_DOWNLOAD=OFF \
-DCMAKE_INSTALL_PREFIX=${SOFT_DIR}/${VERSION}-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
# -DCMAKE_PREFIX_PATH='${BOOST_DIR}/boost;${LAPACK_DIR};${FFTW_DIR};${OPENMPI_DIR}' \

echo "Running the build"
make all
