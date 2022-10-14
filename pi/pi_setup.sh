#!/bin/sh

echo "Rasberry Pi 2Squared Setup"

HOME=/home/squared

#######################
## Install Fadecandy ##
#######################
cd $HOME 
echo -e "\n\n*********** Installing fadecandy **************\n\n"

git clone git@github.com:scanlime/fadecandy.git
cd fadecandy/server
make submodules
make
sudo mv fcserver /usr/local/bin

echo -e "\n\n*********** Done installing fadecandy **************\n\n"

######################
## Compile 2squared ##
######################
cd $HOME
echo -e "\n\n*********** Compiling 2squared **************\n\n"
#cd $HOME;  git clone https://github.com/squaredproject/2squared.git;
#cd 2squared && git checkout hayes-valley && sh compile.sh && cd /home/squared
echo -e "\n\n*********** Done compiling 2squared **************\n\n"

#####################################
## Fadecandy and 2squared Services ##
#####################################
cd $HOME

echo -e "\n\n*********** Setting up fadecandy and squared services **************\n\n"

sudo cp /home/squared/2squared/pi/2squared.service /etc/systemd/system/
sudo cp /home/squared/2squared/pi/fadecandy.service /etc/systemd/system/
sudo systemctl enable 2squared.service
sudo systemctl enable fadecandy.service
sudo systemctl start 2squared
sudo systemctl start fadecandy

######################
####### Network ######
######################
### See https://www.raspberrypi.org/documentation/configuration/wireless/access-point.md

