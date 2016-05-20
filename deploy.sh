#!/bin/bash -e
# this should be run after check-build finishes.
. /etc/profile.d/modules.sh
module add deploy

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
module add gsl/2.0

echo "SOFT DIR is ${SOFT_DIR}"
cd ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
echo "All tests have passed, will now build into ${SOFT_DIR}"
echo "cleaning the previous build "
rm -rf *
echo "Setting compilers"
export CC=mpicc
export CXX=mpicxx
# CMake needs BOOST_ROOT
export BOOST_ROOT=${BOOST_DIR}
echo "Configuring the build"
export CFLAGS="${CFLAGS} -fPIC"
cmake ../ \
-G"Unix Makefiles" \
-DCMAKE_C_COMPILER=mpicc \
-DCMAKE_CXX_COMPILER=mpicxx \
-DGMX_X11=OFF \
-DGMX_FFT_LIBRARY=fftw3 \
-DFFTWF_LIBRARY=${FFTW_DIR}/lib/libfftw3f.so \
-DFFTWF_INCLUDE_DIR=${FFTW_DIR}/include \
-DGMX_GSL=ON \
-DGMX_DOUBLE=ON \
-DGMX_GPU=OFF \
-DGMX_OPENMP=ON \
-DGMX_MPI=ON \
-DGMX_EXTERNAL_BLAS=on \
-DCMAKE_PREFIX_PATH='${BOOST_DIR}/boost;${LAPACK_DIR};${FFTW_DIR};${OPENMPI_DIR}' \
-DREGRESSIONTEST_DOWNLOAD=ON \
-DCMAKE_INSTALL_PREFIX=${SOFT_DIR}/${VERSION}-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}

make -j2
make install
echo "Creating the modules file directory ${LIBRARIES_MODULES}"
mkdir -p ${LIBRARIES_MODULES}/${NAME}
(
cat <<MODULE_FILE
#%Module1.0
## $NAME modulefile
##
proc ModulesHelp { } {
    puts stderr "       This module does nothing but alert the user"
    puts stderr "       that the [module-info name] module is not available"
}

module-whatis   "$NAME $VERSION : See https://github.com/SouthAfricaDigitalScience/gromacs-deploy"
setenv GMX_VERSION       $VERSION
setenv GMX_DIR           $::env(CVMFS_DIR)/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/$VERSION/${VERSION}-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
setenv       GMXPREFIX         $::env(GMX_DIR)
setenv       GMXBIN            $::env(GMX_DIR)/bin
prepend-path PATH              $::env(GMXBIN)
setenv       GMXLDLIB          $::env(GMXPREFIX)/lib
setenv       GMXMAN            $::env(GMXPREFIX)/share/man
setenv       GMXDATA           $::env(GMXPREFIX)/share/gromacs
setenv       GROMACS_DIR       $::env(GMXPREFIX)
prepend-path LD_LIBRARY_PATH   $::env(GMXPREFIX)/lib
setenv GMX_INCLUDE_DIR   $::env(GMX_DIR)/include
setenv GMX_LIB_DIR      $::env(GMX_DIR)/lib
prepend-path CPATH             $::env(GMX_INCLUDE_DIR)
append-path CFLAGS             "-I$::env(GMX_INCLUDE_DIR) -L$::env(GMX_DIR)/lib"

MODULE_FILE
) > ${CHEMISTRY_MODULES}/${NAME}/${VERSION}-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}

#### try to use gromacs
module add ${NAME}/${VERSION}-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
echo "binaries available are : "
ls  ${GMXPREFIX}/bin
