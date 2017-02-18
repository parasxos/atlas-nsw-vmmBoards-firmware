#!/bin/sh
echo "Cleaning up the build directory..."
cd sources
rm -Rf MDT_446 2>&1 >/dev/null
rm -Rf MDT_MU2E 2>&1 >/dev/null
echo "Buildind project..."
vivado -mode batch -nolog -nojournal -notrace -source build_mmfe8.tcl -tclargs mdt_446 2>&1 >/dev/null
echo "Build was made in project directory. Starting project..."
cd MDT_446/
vivado MDT_446.xpr
