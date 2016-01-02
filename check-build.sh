#!/bin/bash -e
# Check build for GROMACS
. /etc/profile.d/modules.sh
module add ci
module add gmp
module add mpfr
module add mpc
module add gcc/${GCC_VERSION}
module add openmpi/${OPENMPI_VERSION}-gcc-${GCC_VERSION}
module add fftw/3.3.4-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
module add boost/1.59.0-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
echo ""
cd ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
echo "Making check"
make check
echo $?
echo "Running Make Install"
# "Warning
# make install can overwrite or masquerade the python binary. make altinstall is therefore recommended instead of make install since it
# only installs exec_prefix/bin/pythonversion.
# see : https://docs.python.org/2/using/unix.html#building-python
make altinstall

mkdir -p modules

echo "Making CI module"

# according to the gromacs GMXRC file that comes with the distro, these variables need to be set:
#GMXPREFIX=/usr/local/gromacs
#GMXBIN=${GMXPREFIX}/bin
#GMXLDLIB=${GMXPREFIX}/lib
#GMXMAN=${GMXPREFIX}/share/man
#GMXDATA=${GMXPREFIX}/share/gromacs
#GROMACS_DIR=${GMXPREFIX}

(
cat <<MODULE_FILE
#%Module1.0
## $NAME modulefile
##
proc ModulesHelp { } {
    puts stderr "       This module does nothing but alert the user"
    puts stderr "       that the [module-info name] module is not available"
}

module-whatis   "$NAME $VERSION. Compiled for GCC ${GCC_VERSION} with OpenMPI version ${OPENMPI_VERSION}"
setenv       GMX_VERSION       $VERSION
setenv       GMX_DIR           /apprepo/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/$VERSION-mpi-${OPENMPI_VERSION}-gcc-${GCC_VERSION}
setenv       GMXPREFIX         $::env(GMX_DIR)
setenv       GMXBIN            $::env(GMX_DIR)/bin
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
) > modules/${VERSION}-mpi-${OPENMPI_VERSION}-gcc-${GCC_VERSION}

mkdir -p ${LIBRARIES_MODULES}/${NAME}
cp modules/${VERSION}-mpi-${OPENMPI_VERSION}-gcc-${GCC_VERSION} ${LIBRARIES_MODULES}/${NAME}
#  check if we can use it.
echo "Testing the module"
module add ${NAME}/${VERSION}-mpi-${OPENMPI_VERSION}-gcc-${GCC_VERSION}

echo "Binaries available : "
ls ${GMXPREFIX}/bin
source ${GMPREFIX}/bin/GMXRC.sh
env
