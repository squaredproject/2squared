#!/bin/sh

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

cd /home/odroid
#######################
## Install Fadecandy ##
#######################
wget https://codeload.github.com/scanlime/fadecandy/zip/master -O fadecandy.zip
unzip fadecandy.zip
mv fadecandy-master fadecandy
rm fadecandy.zip

######################
## Install 2squared ##
######################
wget -O 2squared.zip https://github.com/squaredproject/2squared/archive/master.zip
unzip 2squared.zip
mv 2squared-master 2squared
rm 2squared.zip
cd 2squared && sh run.sh && cd /home/odroid

###########################
## Install Oracle Java 8 ##
###########################

# Note: you will be prompted several times while running these commands
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get update
sudo apt-get install oracle-java8-installer

########################
## Install Processing ##
########################
wget -O processing.tgz http://download.processing.org/processing-2.2.1-linux64.tgz
tar xvzf processing.tgz

#####################################
## Fadecandy and 2squared Services ##
#####################################
cp /home/odroid/2squared/odroid_setup/2squared.service /etc/systemd/system/
cp /home/odroid/2squared/odroid_setup/fadecandy.service /etc/systemd/system/
systemctl enable 2squared.service
systemctl enable fadecandy.service
