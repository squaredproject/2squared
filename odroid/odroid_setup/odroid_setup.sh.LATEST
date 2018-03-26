#!/bin/sh

if [ `id -u` != 0 ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

cd /home/odroid

###########################
## Install Oracle Java 8 ## (And other packages)
###########################
echo -e "\n\n\n*********** Installing packages **************\n\n\n\n\n"
# Note: you will be prompted several times while running these commands
sudo add-apt-repository ppa:webupd8team/java
sudo apt-get -y update
sudo apt-get -y install libnl-3-dev libnl-genl-3-dev libssl-dev hostapd iptables git-core oracle-java8-installer isc-dhcp-server aufs-tools
sudo apt-get -y install --reinstall pkg-config
echo -e "\n\n\n*********** Done installing packages **************\n\n\n\n\n"


#######################
## Install Fadecandy ##
#######################
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
echo -e "\n\n\n*********** Installing 2squared **************\n\n\n\n\n"
git clone https://github.com/squaredproject/2squared.git
git checkout minitree-norfolk # Comment this out before merge to master
cd 2squared && sh compile.sh && cd /home/odroid

echo -e "\n\n\n*********** Done installing 2squared **************\n\n\n\n\n"




#####################################
## Fadecandy and 2squared Services ##
#####################################
echo -e "\n\n\n*********** Setting up fadecand and squared services **************\n\n\n\n\n"

sudo cp /home/odroid/2squared/odroid_setup/2squared.service /etc/systemd/system/
sudo cp /home/odroid/2squared/odroid_setup/fadecandy.service /etc/systemd/system/
systemctl reenable 2squared.service
systemctl reenable fadecandy.service

######################
####### Hostapd ######
######################
echo -e "\n\n\n*********** configuring hostapd **************\n\n\n\n\n"

# https://fleshandmachines.wordpress.com/2012/10/04/wifi-acces-point-on-beaglebone-with-dhcp/
# http://odroid.com/dokuwiki/doku.php?id=en:xu4_wlan_ap
sudo cp /home/odroid/2squared/odroid_setup/interfaces /etc/network/interfaces

git clone https://github.com/pritambaral/hostapd-rtl871xdrv.git
wget https://w1.fi/releases/hostapd-2.6.tar.gz
tar xvfz hostapd-2.6.tar.gz
cd hostapd-2.6
patch -p1 < ../hostapd-rtl871xdrv/rtlxdrv.patch
cd hostapd
cp defconfig .config
echo CONFIG_LIBNL32=y >> .config
echo CONFIG_DRIVER_RTW=y >> .config
make
cd /home/odroid

sudo cp /usr/sbin/hostapd /usr/sbin/hostapd.back
sudo cp /home/odroid/hostapd-2.6/hostapd/hostapd /usr/sbin/hostapd

sudo cp /home/odroid/2squared/odroid_setup/hostapd_default /etc/default/hostapd
sudo cp /home/odroid/2squared/odroid_setup/hostapd.conf /etc/hostapd/hostapd.conf

service hostapd restart
echo -e "\n\n\n*********** Done with hostapd **************\n\n\n\n\n"

###############################
####### isc-dhcp-server #######
###############################
echo -e "\n\n\n*********** configuring isc-dhcp-server **************\n\n\n\n\n"

sudo cat <<EOT >> /etc/dhcp/dhcpd.conf
subnet 192.168.4.0 netmask 255.255.255.0 {
  range 192.168.4.2 192.168.4.100;
}
EOT
service isc-dhcp-server restart

echo -e "\n\n\n*********** Done with isc-dhcp-server **************\n\n\n\n\n"

###############################
####### AUFS read-only  #######
###############################
echo aufs >> /etc/initramfs-tools/modules
# vi /etc/initramfs-tools/scripts/init-bottom/rootaufs
sudo cp /home/odroid/2squared/odroid_setup/rootaufs /etc/initramfs-tools/scripts/init-bottom/rootaufs
chmod 0755 /etc/initramfs-tools/scripts/init-bottom/rootaufs
mv /etc/initramfs-tools/scripts/init-bottom/rootaufs /etc/initramfs-tools/scripts/init-bottom/__rootaufs

update-initramfs -u
mkimage -A arm64 -O linux -T ramdisk -C none -a 0 -e 0 -n "uInitrd $(uname -r)" -d /boot/initrd.img-$(uname -r) /boot/uInitrd-$(uname -r)
cp /boot/uInitrd-$(uname -r) /media/boot/uInitrd

# vi /media/boot/boot.ini
# add aufs=tmpfs

echo -e "\n\n\n*********** Done!!! Now add aufs=tmpfs to setenv bootargs line in /media/boot.ini **************\n\n\n\n\n"
