#!/bin/bash -e
# Check build for GROMACS
. /etc/profile.d/modules.sh
module add ci
module add gcc/${GCC_VERSION}
module add cmake
module add lapack/3.6.0-gcc-${GCC_VERSION}
module add openmpi/${OPENMPI_VERSION}-gcc-${GCC_VERSION}
module add fftw/3.3.4-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
module add boost/1.62.0-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
module add gsl/2.0

# gromacs testing requires libxml2
# module  add  libxml2

export OMP_NUM_THREADS=1
echo ""
cd ${WORKSPACE}/${NAME}-${VERSION}/build-${BUILD_NUMBER}
# echo "Making check with ${OMP_NUM_THREADS} threads"
# export CTEST_TEST_TIMEOUT=3600
# make check
# echo $?
echo "Running Make Install"
make install

mkdir -p modules

echo "Making CI module"

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
setenv       GMX_DIR           /data/ci-build/$::env(SITE)/$::env(OS)/$::env(ARCH)/$NAME/$VERSION/${VERSION}-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}
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
) > modules/${VERSION}-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}

mkdir -p ${CHEMISTRY}/${NAME}
cp modules/${VERSION}-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION} ${CHEMISTRY}/${NAME}
#  check if we can use it.
echo "is the module available ?"
module avail ${NAME}
echo "Testing the module"
module add ${NAME}/${VERSION}-gcc-${GCC_VERSION}-mpi-${OPENMPI_VERSION}

echo "Binaries available : "
ls ${GMXPREFIX}/bin
env

#  the rest comes from http://www.bevanlab.biochem.vt.edu/Pages/Personal/justin/gmx-tutorials/lysozyme/
# Get the pdb file
wget https://files.rcsb.org/view/1AKI.pdb
echo 15 | gmx_mpi_d pdb2gmx -f 1AKI.pdb -o 1AKI_processed.gro -water spce
gmx_mpi_d editconf -f 1AKI_processed.gro -o 1AKI_newbox.gro -c -d 1.0 -bt cubic
gmx_mpi_d solvate -cp 1AKI_newbox.gro -cs spc216.gro -o 1AKI_solv.gro -p topol.top
wget http://www.bevanlab.biochem.vt.edu/Pages/Personal/justin/gmx-tutorials/lysozyme/Files/ions.mdp
gmx_mpi_d grompp -f ions.mdp -c 1AKI_solv.gro -p topol.top -o ions.tpr
echo 13 | gmx_mpi_d genion -s ions.tpr -o 1AKI_solv_ions.gro -p topol.top -pname NA -nname CL -nn 8
wget http://www.bevanlab.biochem.vt.edu/Pages/Personal/justin/gmx-tutorials/lysozyme/Files/minim.mdp
gmx_mpi_d grompp -f minim.mdp -c 1AKI_solv_ions.gro -p topol.top -o em.tpr
# mpirun gmx_mpi_d  mdrun -v -deffnm em
# wget http://www.bevanlab.biochem.vt.edu/Pages/Personal/justin/gmx-tutorials/lysozyme/Files/nvt.mdp
# gmx_mpi_d grompp -f nvt.mdp -c em.gro -p topol.top -o nvt.tpr
# This takes ALL the CPUS
# mpirun gmx_mpi_d mdrun -deffnm nvt
