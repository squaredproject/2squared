#!/bin/sh

echo "Rasberry Pi 2Squared Setup"

HOME=/home/squared

#######################
## Create User Squared ##
#######################
echo -e "\n\n\n*********** Creating new user squared **************\n\n\n\n\n"
sudo useradd -m -d $HOME -s /bin/bash -p 'thetrees!' squared
sudo chmod -R a+w /home/squared

######################
####### wifi internet access ######
######################
cd $HOME/pi/

echo -e "\n\n\n*********** configuring wifi access **************\n\n\n\n\n"
sudo cp wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf

echo -e "\n\n\n*********** DONE **************\n\n\n\n\n"

#######################
## Install Fadecandy ##
#######################
cd $HOME 
echo -e "\n\n\n*********** Installing fadecandy **************\n\n\n\n\n"

git clone git://github.com/scanlime/fadecandy
cd fadecandy/server
make submodules
make
sudo mv fcserver /usr/local/bin

echo -e "\n\n\n*********** Done installing fadecandy **************\n\n\n\n\n"


######################
## Install 2squared ##
######################
cd $HOME 
echo -e "\n\n\n*********** Installing 2squared **************\n\n\n\n\n"
git clone https://github.com/squaredproject/2squared.git
#git checkout minitree-norfolk # Comment this out before merge to master
cd 2squared && sh compile.sh && cd /home/squared

echo -e "\n\n\n*********** Done installing 2squared **************\n\n\n\n\n"


#####################################
## Fadecandy and 2squared Services ##
#####################################
echo -e "\n\n\n*********** Setting up fadecand and squared services **************\n\n\n\n\n"

sudo cp /home/squared/2squared/pi/pi_setup/2squared.service /etc/systemd/system/
sudo cp /home/squared/2squared/pi/pi_setup/fadecandy.service /etc/systemd/system/
sudo systemctl reenable 2squared.service
sudo systemctl reenable fadecandy.service

######################
####### Hostapd ######
######################
cd  $HOME/2squared/pi/

echo -e "\n\n\n*********** configuring hostapd **************\n\n\n\n\n"

sudo apt --assume-yes install dnsmasq hostapd bridge-utils -qq
sudo cp hostapd.conf  /etc/hostapd/hostapd.conf
sudo cp hostapd  /etc/default/hostapd

sudo cp dnsmasq.conf /etc/dnsmasq.conf

### Enable  hotspot as wireless access point
### See https://www.raspberrypi.org/documentation/configuration/wireless/access-point.md

echo -e "\n\n\n*********** configuring wifi access point **************\n\n\n\n\n"
echo -e "\n\n\n*********** warning: running this script more than once  **************\n\n\n\n\n"
echo -e "\n\n\n*********** warning: appends lines to /etc/rc.local /etc/dhcpcd.conf /etc/sysctl.conf   **************\n\n\n\n\n"

sudo cp  /etc/dhcpcd.conf /etc/dhcpcd.conf.bak
echo "interface wlan1" >> /etc/dhcpcd.conf
echo "\t static ip_address=192.168.4.1/24" >> /etc/dhcpcd.conf
echo "\t nohook wpa_supplicant" >> /etc/dhcpcd.conf

echo "\n\ninterface eth0" >> /etc/dhcpcd.conf
echo "\tstatic ip_address=10.0.0.10/24" >> /etc/dhcpcd.conf


### Uncomment line re IP forwarding
sudo cp /etc/sysctl.conf  /etc/sysctl.conf.orig
sudo sed -i 's/^#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

### Add masquerade for outbound traffic
sudo iptables -t nat -A  POSTROUTING -o wlan0 -j MASQUERADE

### Save IP tables
sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"

### load IP tables on reboot
sudo cp /etc/rc.local /tmp/rc.local.orig
sudo sed -i 's/exit 0/iptables-restore < \/etc\/iptables.ipv4.nat/' /etc/rc.local

sudo systemctl unmask hostapd
sudo systemctl enable hostapd
sudo systemctl restart hostapd
sudo systemctl restart dhcpcd
sudo systemctl reload  dnsmasq

### enable ssh
echo -e "\n\n\n*********** enabling ssh access  **************\n\n\n\n\n"
sudo apt-get install openssh-server
sudo systemctl enable ssh

echo -e "\n\n\n*********** Done with hostapd **************\n\n\n\n\n"
 

