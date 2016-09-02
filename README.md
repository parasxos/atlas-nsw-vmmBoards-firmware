#################################  README FIRST ###############################

This repo contains the firmware of the MMFE8 boards of ATLAS NSW.
In the bitstream directory one can find the released versions synthesized
.bit files. The entire Vivado .xpr project can be built from the build_mmfe8.tcl
script file.

In order to set up a local repository one must:

1) Register his/her e-mail address at gitlab with the command:

$ git config --global user.email "your_email@example.com"

2)Generate an ssh key in his/her local machine:

$ ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

3)Copying the ssh key, by first making sure that ssh-agent is enabled:

$ eval "$(ssh-agent -s)"

Then adding the ssh key:

$ ssh-add ~/../../"KEY LOCATION"

Where "KEY LOCATION"is the location where the key was saved in step 2.
And finally one must open the ~/.ssh/id_rsa.pub and copy the contents of the
file.

4)Adding the SSH key to his/her git account:
Open the settings of the account (top right of the gitlab page), click on 
"Deploy Keys" and paste the ssh key on the appropriate field.

5)Now the user is ready to clone the gitlab repository via ssh on his/her
local machine:

$ git clone "SSH URL"

Where "SSH URL" can be found at the main page of the project.


In order to build the firmware, run the following command:

$ vivado -mode batch -source build_mmfe8.tcl -nolog -nojournal

The command above runs the .tcl script and creates the .xpr project file.
An alternative way would simply be to run Vivado and go to:  
Tools -> Run Tcl Script

############# Christos Bakalis, christos.bakalis@cern.ch #######################

############# Paris Moschovakos, paris.moschovakos@cern.ch #####################



