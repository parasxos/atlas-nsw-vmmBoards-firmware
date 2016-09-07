#################################  README FIRST ###############################

This repo contains the firmware of the MMFE8 boards of ATLAS NSW.
In the bitstream directory one can find the released versions synthesized
.bit files. The entire Vivado .xpr project can be built from the build_mmfe8.tcl
script file.

In order to set up a local repository you must:

1) Configure your e-mail address and name for git with the commands:

$ git config --global user.email "your_email@example.com"

$ git config --global user.name "Your Name"

2) Now you are ready to clone the gitlab repository via krb5 on your
local machine:

$ git clone "KRB5 URL"

Where "KRB5 URL" can be found at the main page of the project.


In order to build the firmware, run the following command:

$ vivado -mode batch -source <PATH_TO>/build_mmfe8.tcl -nolog -nojournal

The command above runs the .tcl script and creates the .xpr project file.
An alternative way would simply be to run Vivado and go to:  
Tools -> Run Tcl Script

############# Christos Bakalis, christos.bakalis@cern.ch #######################

############# Paris Moschovakos, paris.moschovakos@cern.ch #####################



