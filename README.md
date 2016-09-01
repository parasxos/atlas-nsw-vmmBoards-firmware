Readme
------
          
This repo contains the firmware of the MMFE8 boards of ATLAS NSW.
In the bitstream directory one can find the released versions.
The repo is to be enriched with the source files and documentation.

To compile the firmware, run the following two commands:
git config --global user.name "Your Name"
vivado -mode batch -source build_mmfe8.tcl

e-mail: paris.moschovakos@cern.ch

#################################  README FIRST ##########################################

 The build_mmfe8.tcl script points to the source files needed to re-create the project
 'MMFE8'. The user may change the project name at the #Set project name
  field as he wishes. (e.g. set projectname "myproject"). 

 In order to execute the tcl script and build the project, run Vivado and go to: 
 Tools -> Run Tcl Script...

 An alternative way would be to open a terminal, and run this command:
 vivado -mode batch -source <PATH>/build_mmfe8.tcl

 For more info on how to make further changes to the script, see: 
 http://xillybus.com/tutorials/vivado-version-control-packaging

##########################-Christos Bakalis, christos.bakalis@cern.ch-####################


