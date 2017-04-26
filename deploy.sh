#!/bin/sh
echo "Cleaning up the build directory..."
cd sources
rm -Rf MDT_446 2>&1 >/dev/null
rm -Rf MDT_MU2E 2>&1 >/dev/null
rm -Rf MMMFE8_VMM3 2>&1 >/dev/null

tclArg=$1
projectDir="MMFE8_VMM3/"
projectXpr="MMFE8_VMM3.xpr"

if [ "$1" == "mmfe8_vmm3" ] 
then
	echo "Buildind project for:" $1
elif [ "$1" == "mdt_446" ] 
then
	echo "Buildind project for:" $1
	projectDir="MDT_446/"
	projectXpr="MDT_446.xpr"
elif [ "$1" == "mdt_mu2e" ] 
then
	echo "Buildind project for:" $1
	projectDir="MDT_MU2E/"
	projectXpr="MDT_MU2E.xpr"
else
	tclArg="mmfe8_vmm3"
	echo "Building project for:" $tclArg	
fi

vivado -mode batch -nolog -nojournal -notrace -source build_mmfe8.tcl -tclargs $tclArg 2>&1 >/dev/null
echo "Build was made in project directory. Starting project..."
cd $projectDir
vivado $projectXpr 
