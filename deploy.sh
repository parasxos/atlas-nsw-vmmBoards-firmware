#
# *********************************************************************************
# Script to create and deploy generic firmware for a specific VMM front end board.
# The scripts takes as an argument, a board's name as follows:
#
#	-mmfe8_vmm3
#	-gpvmm
#	-mmfe1
#	-mdt_446
#	-mdt_mu2e
#
# This script is removing any previous project and creates and deploys the
# firmware files project for the specified board. 
#
# by: Paris Moschovakos paris.moschovakos@cern.ch
# *********************************************************************************
#
#!/bin/sh
echo "Cleaning up the build directory..."
cd sources
rm -Rf MDT_446 2>&1 >/dev/null
rm -Rf MDT_MU2E 2>&1 >/dev/null
rm -Rf MMFE8_VMM3 2>&1 >/dev/null
rm -Rf MMFE1 2>&1 >/dev/null

tclArg=$1
projectDir="MMFE8_VMM3/"
projectXpr="MMFE8_VMM3.xpr"

if [ "$1" == "mmfe8_vmm3" ] 
then
	echo "Buildind project for:" $1
elif [ "$1" == "mmfe1" ] 
then
	echo "Buildind project for:" $1
	projectDir="MMFE1/"
	projectXpr="MMFE1.xpr"
elif [ "$1" == "gpvmm" ] 
then
	echo "Buildind project for:" $1
	projectDir="GPVMM/"
	projectXpr="GPVMM.xpr"
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

vivado -mode batch -nolog -nojournal -notrace -source buildVmmFrontEnd.tcl -tclargs $tclArg 2>&1 >/dev/null
echo "Build was made in project directory. Starting project..."
cd $projectDir
vivado $projectXpr 
