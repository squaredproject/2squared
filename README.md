# 2squared

Big LED trees with blinky blinks

* This document includes instructions on how to set up 2Squared on a laptop, rasberry pi or odroid. It also contains a bunch of unsorted notes regarding setup, fadecandys, NDBs, mapping etc which are useful!

##Github repo & files
Processing & Source code: [http://github.com/squaredproject/2squared](http://github.com/squaredproject/2squared)

Ipad App: [https://github.com/kylefleming/minitreesios](https://github.com/kylefleming/minitreesios)


## How to run Big Trees on desktop using Processing
- Install Processing 3.0
- Download this git repo https://github.com/squaredproject/2squared
- git clone https://github.com/squaredproject/2squared.git
- Check out hayes-valley branch
- git checkout hayes-valley
- Open Trees.pde in Processing 3.0
- Press Play and you should see the Squared App load

## How to run 2Squared on Rasberry PI
- Follow instructions here: 2squared/pi/README.md
- 
## Big Tree or Sqaured Mini?
- For the big tree, connect computer to NDBs through ethernet
- For squared mini, connect computer to fadecandys through USB ports

## How to run Squared Mini or Entwined mini using odroid (deprecated)
- You need an odroid that has the sqaured mini or entwined image preinstalled
- Using the mapping instructions to map the clusters using Processing on your laptop ( [https://github.com/squaredproject/2squared/blob/master/mappingHowTo.txt](https://github.com/squaredproject/2squared/blob/master/mappingHowTo.txt])
- Connect the odroid and follow the mapping instructions to copy over the custom mappings to the mini tree or entwined odroid
- Reboot odroid and see if patterns run and are mapped correctly

## Squared Mini New Owner Email
Hi there and welcome to your squared mini tree!

###Quick Start
* Plug your tree into the wall outlet
* Turn on the tree using the switch at the base of the tree
* Wait 2 mins for tree to start generating patterns
* Use the MINI app on the ipad to interact and make your own patterns
* Mini tree has its own wifi ( wifi: mini-tree password:thetrees!)
* You can also download the app on the app-store at https://apps.apple.com/us/app/squared-mini/id1464956368?ls=1
Any questions? Contact Charlie: 415 359 5084 art4fire@gmail.com

## Important Notes:
* How to map a tree: [https://github.com/squaredproject/2squared/blob/master/mappingHowTo.txt](https://github.com/squaredproject/2squared/blob/master/mappingHowTo.txt])
* Once you have mapped the clusters on a tree, the mappings is saved to a set of configuration json files. see [https://github.com/squaredproject/2squared/blob/master/mappingHowTo.txt](https://github.com/squaredproject/2squared/blob/master/mappingHowTo.txt) on how to map
* After mapping, create a new branch and commit those changes. Each tree should have its own branch in github with its specific mappings stored
* Squared files to edit for each tree:
* config.json -- fadecandy config (add one of your fadecandy serial numbers here)
* Trees/Config.java -- config file, defines which cluster json file is used
* Trees/clusters_bigtree.json --one of the mapped json config, unique for every new squared tree (both big and mini)
* After editing, be sure to compile using compile.sh

####Other important files (no need to edit them)
* run.sh -- runs headless java app
* Trees/Trees.pde -- main file to open in Processing
* Trees/Patterns_*.java -- patterns code
* Trees/data/Burning\ Man\ Playlist.json -- 22 burning man play list which is the default patterns, normally loops
*  odroid/odroid_setup/2squared.service & odroid/odroid_setup/fadecandy.service -- scripts to make sure headless java app is started on boot
*  odroid/odroid_setup/odroid_setup.sh -- script to configure a new odroid from a factory emmc card.  NOTE: better to wipe the emmc and use the disk images rather than doing this



## General Tech Info
There are three main types of trees, Big Squared, Squared Mini and Entwined.  

Squared Mini runs using fadecandys to drive the LEDs

Big Tree and Entwined use NDBs, so configuration files and mappings are different. 

**Squared Mini runs on Processing 2.0, Big Squared runs on Processing 3.0 and the software is not compatible with other versions of Processing**

### Odroid Differences

Big Trees are normally run through a physical laptop running processing 3.0.

Squared Mini odroids have a wifi antenna and offer a wifi hotspot called the-tree.  This is how users use the ipad app and also how you can ssh into the machine for troubleshooting

Entwined odroids do not use wifi but are connected to NDBs via ethernet.  They have a static ip address of 10.0.0.10.

Therefore there are two different odroid disk images

#### Odroid setup
Mini Trees:  connect via wifi mini-trees, ssh root@192.168.4.1 (password odroid)

Big Tree/Entwined: connect via ethernet, ssh root@10.0.0.10 (password odroid)

To change odroid from read only mode:
remountrw
make changes
reboot


## Odroids
Each squared mini requires an odroid (mini unix machine) to drive patterns.  You need to buy an odroid and then use the Squared disk images to configure the odroid correctly.

###Purchasing order for each odroid
* ODROID-C2   
* 5V/2A Power Supply (US Plug)	
* ODROID-C1-Plus/C2 Case Clear	
* WiFi Module 3
* 16GB eMMC Black Module C2 Linux (Red Box)	
### Burn odroid image
We have an odroid image that has ubuntu and squared confgured on that you need to burn onto the emmc disk.  To do this, make sure you only buy Odroid C2 machines otherwise burning the disk will not work

###How to burn our custom odroid images from a laptop to the factory new emmc 16GB disk
* Pre-reqs: macos laptop with disk images on desktop (entwined_odroid.img or mini_odroid.img)
* Connect new 16GB linux emmc to computer using usb emmc reader or micro sd reader
* Make sure the emmc is seen and mounted
 * *diskutil list*
* Get the name of the emmc, normally /dev/disk1 or /dev/disk2 and unmount it
 *    *diskutil unmountDisk /dev/disk1*
* Burn image to emmc (make sure to rename the disk using the char r - so /dev/disk1 becomes /dev/rdisk1
 * *dd bs=1m if=/Users/squaredproject/Desktop/minitree_odroid.img of=/dev/rdisk2*
* This will take at least 15 mins so be patient
* *Be very careful with using the right diskname, otherwise you could burn the image onto your laptop hard drive by accident and wipe it out completely*

## How to install ipad app for squared mini trees
Kyle wrote an ipad app to control the Squared trees

Each squared mini tree should come with its own ipad so the owner can interact with the tree.  The ipad works by connecting to the squared mini wifi hotspot.

* Wipe ipad to factory settings
* Use a laptop to build and install Squared app on ipad
* Make sure mini tree is running
* Connect ipad to mini tree hotspot (Wifi name: mini-tree. Wifi password: thetrees!)
* Open app and interact with patterns

#### Wipe Ipad to factory new

* Wipe and reinitialize ipad as brand new ipad
* Do not add your apple id (so new owner can do so instead)
* Make sure to not set a passcode
       
### Install app on ipad

To install the app on an ipad you need to download the code from github and build it using xcode onto the ipad.

Ipad app source code: [https://github.com/kylefleming/minitreesios]()

#### Pre-reqs
* macos machine with xcode installed
* Enroll your apple ID as a Apple developer (you do not need to pay the $99 fee)
* Github.com account
* Install Cocoapads (Xcode library dependencies) https://guides.cocoapods.org/using/getting-started.html

#### Installation howtoI  Howto install
* Download ipad source
  * cd ~/Desktop; git clone https://github.com/kylefleming/minitreesios.git; cd minitreesios
* Install latest libraries:
  * cd ~/Deskrtop/minitreesios; pod install 
* Add your developer apple id to xcode and make a cert
  * Open Xcode
  * Go to Xcode->Preferences, and click on Accounts
  * Add your APPLE ID	       	  
  * Create iOS Development Certificate:
    * Click on 'Manage Certificates"
      * Add IOS Development Certificate	 
* Open minitrees project in Xcode
  * File->Open
  * Navigate to minitereesios dir
  * Open Minitrees.xcworkspace
  * Connect to the Ipad in the Build pulldown
  * Click top left arrow to "build" minitreees
  * If build succeeds, then connect ipad to computer
  * Go to top left header and set Device to new Ipad
  * Click Build again
  * Check app is built on ipad
  * Sometimes ipad will say "Third-Party Apps from Unidentified Developers cannot be opened"
    * In this case, go to Settings > General > Profiles or Profiles & Device Management and click on developer name and hit Trust       

#### Troubleshooting
* Troubleshooting - sometimes ipad cannot find the mini-tree network, try:
 * On ipad hit - forget this network
 * Restart mini tree
 * Reconnect to wifi on ipad
 * OPTIONAL:
 *	You can turn on Guided Access if wanted, which will prevent other apps from running 
 *  How to enable Guided Access on iPhone and iPad
    * Close all applications on ipad
      * Go to Settings/General/Guided Access
      	* Tap the switch to turn on Guided Access.
	  * Set Passcode: 000000
	    * Then open Squared Mini App
	      * TripleClick Home Button


## NDBS Setup and troubleshooting

An NDB (Minleon Network Distribution Box) is a hardware LED controller that allows to drive patterns and sequences onto LED strips. 
The big trees use 48 NDBS to drive patterns on 48 clusters of LEDs.

Each NDB has an ethernet input and 16 DMX outputs. Each NDB has a unique IP address and has a cluster of 16 cubes connected to the DSMXZ outputs.
 
A computer/sequencer can connect to the NBDs via TCP IP and send patterns that are translated bty the NDB into LED signals.

[See NDB Docs](http://www.minleon.com.au/Minleon%20NDB%20Manual%20AUS%20-%20Sept%202016.pdf)

### NDB Big Trees Setup

The big trees have 48 NDBs in the tree. 
Each NDB drives one of the squared clusters and sends both power and data through a DMX cable.

There are 16 cubes in a cluster and each cube is connected to one of the 16 DMX outputs.  

Because the NDB needs power too via DMX, one of the 16 DMX outputs always has a tee and has a DMX power input cable also.

Each NDB has a unique IP address and is connected via two ethernet switches.  The IP address is unique, written on the NDB on a srticker and in the range 10.0.0.1-10.0.0.254

There is a computer or ipad connected to the ethernet switches that can find each NDB by IP address

The computer is running Processing 3.0 app and has a json config file that has all the IP addresses of each NDB at data/clusters_bigtree.json

The computer is connected to the two ethernet switches with all 48 NDBs via Ethernet. 

#### How to set up ethernet settings on a computer to connect to NDBs:
* Plug in Ethernet cable
* Go to network settings/USB Ethernet
* Configure Manually
* IP address 10.0.0.10
* Subnet Mask 255.255.255.0


NDB

•	NDBs each have an IP address (on the sticker)
•	You need a switch to plug them in
•	You need a computer with a static IP address
o	Same subnet as 10.0.0.0
o	Plug in Ethernet cable
o	Go to network settings/USB Ethernet
o	Use USB Ethernet
o	Configure Manually
o	IP address 10.0.0.10
o	Subnet Mask 255.255.255.0
•	Install Processing 3.0 (Big Tree requires 3.0)
•	Download 2sqaured BRANCH big-tree-with-ipad
•	Git branch big-tree-with-ipad –track origin/big-tree-with-ipad
•	Open Trees.PDE in Processing 3
•	Top map NDB: Trees/data/clusters_bigtree.json
•	In the past use clusters with consecutive IPS if possible
•	For the Big Tree there are 48 clusters (e.g 100-147)
•	If you don’t know the IPnaddress, ping everythibng from 10.0.0.2 to 10.0.0.254 
•	To EDIT NDBS
o	Make a list of all the NDB IP address (sequential is better but probably impossible)
o	There should be 48 of them
o	Open up Processing 3.0
o	Enable Cluster Tool (little box on lower left hand)
o	Go through clusters, (press left)right)
o	Change level|face|offset so MODEL looks like real life
o	Hit Save Changes (Trees/data/clusters_bigtree.json)
o	Restart Processing 3.0 to see changes



### To setup FACTORY  FRESH NDBS (One time only)

When you first get a factory fresh NDB, you will need to configure it for Squared using a script called ndb_tree_flasher.sh. This config is only done ONCE after getting a factory fresh NDB.  The script is ndb_tree_flasher.sh. When you run it, it will loop through IP addresses and flash NDBs one by one, so have them all ready in a queue.

The script will

* Set user-defined IP address
  * The IP addresses you chose should be UNIQUE and go from 10.0.0.1-10.0.0.254 (see list of IP addresses that are already used by NDBs)
* Configure the number of LEDS and color information for all 16 channels.  

####To configure factory fresh NDBs:

*      Choose  your NDB IP address range and edit ndb_tree_flasher.sh with your first IP address
*  Make sure to have all your factory fresh NDBs ready for flashing (scrupt will flash them one by one)
*  Connect NDP to ethernet switch and connect power via any DMX output
*  Close Processing on laptop
*  Connect laptop to Ethernet switch with ethernet cable 
   *  	   Make sure to configure Ethernet network preferences (IP address 10.0.0.10, Subnet Mask 255.255.255.0)
* Run ndb_tree_flasher.sh, it will tell you which IP address it will assign to the NDB and wait for you to hit enter to flash it
* For every NDB
  * Connect NDB to Ethernet switch and plug in power cable to any DMX channel
  * Hit enter on script
  * After flashing
  * 	  Restart NDB (remove power cable for a sec) – NDB needs a physical restart after flashing
  *  Use ping script to confirm NDB has new IP address, eg. 10.0.0.143
  *  Go to 10.0.0.143 in browser and confirm all 16 outputs have values (see screenshot)
  *  Write IP address on sticker on NDP
  *  	   Disconnect, plug in new NDB and continue

#### Helpful Info
Sometimes you will get an NDP that has an IP address written on a sticker on it, but you want to doublecheck its settings.  To do this:
•	  Connect single NDB to Ethernet switch, plug in power to any DMX channel
•	  Connect laptop to Ethernet (and set custom static IP – see above)
•	  Check current IP address of NDB:
♣	  In terminal run

* cd 2squared; ./ping.sh
* you should get one result for 10.0.0.100 – factory clean NDB

## Docs

* Engine: [LX](http://heronarts.com/lx/api/index.html)

## Installation

* Download [Processing](https://processing.org/download/?processing)
  * You will need to download version 2 of Processing
* Install [LibNFC](http://nfc-tools.org/index.php?title=Libnfc#Installation) (On Mac OS X, I recommend Homebrew; see below)
* Clone this repo (or download the zip)
* Open `Trees.pde` in Processing and run the sketch

#### Mac OS X LibNFC Install

* Install Homebrew: `ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"`
* Do all the brewy stuff by running: `brew doctor`
* Install libnfc: `brew install libnfc`

#### Other OS X stuff

###### To Make NFC actually work

OS X has smart card reader integration and automatically launches pcscd every time a smartcard reader device is connected. This conflicts with the libnfc-based driver, which is much faster than a pcscd based-tag reader. You can work around this by killing pcscd manually, or you can prevent pcscd from starting.

To prevent pcscd from starting, edit `/System/Library/LaunchDaemons/com.apple.securityd.plist` and add:

`-soff`

below:

`/usr/sbin/securityd-i`

and reboot the system.

###### To get rid of crazy logging

Additionally, the config file for libnfc can be found at: `/usr/local/Cellar/libnfc/1.7.0/etc/nfc/libnfc.conf`

add: `log_level=0 `to this file to disable the verbose error logging.


### References & Tech Specs
- [Odroid C2](http://www.hardkernel.com/main/products/prdt_info.php?g_code=G145457216438)
- [Fadecandy](https://github.com/scanlime/fadecandy)
- [TekLights/NDB manuals](http://www.teklights.com/pages/info)
- [LX](https://github.com/heronarts/LX])
- [P3LX](https://github.com/heronarts/P3LX)
- [LX/P3LX javadoc reference](http://heronarts.com/lx/api/index.html)

### Similar code and patterns to reference for new pattern writing
- Ascension (Burning Man 2016): [https://github.com/ascensionproject/ascension]()
- PAVO (Burning Man 2016): [https://github.com/pavoart/pavo]()
- Dr Brainlove (Burning Man): [https://github.com/DrBrainlove/DBL_LEDcontrol]()
- Titanic’s End (Burning Man 2014): [https://github.com/nottombrown/TitanicsEnd]()

### Random Email from Kyle Re Odroid setup
Hey Oren,

2) Not sure if you ordered it already, but the C2 seems fine. I got an XU4 for a project last year and found it to be slower than the U3, even though I was running the exact same software and the XU4 had better specs. Not sure how the C2 fares compared to the other 2.

I did find that oracle java 8 was much faster than openjdk java 8 for the tests I ran, so make sure you install that on any embedded linux boxes. To install oracle java 8:

$> sudo add-apt-repository ppa:webupd8team/java
$> sudo apt-get update
$> sudo apt-get install oracle-java8-installer

3) That’s basically what I got, plus the other components, like the usb hub, usb extension, power strip, etc. I don’t think you’ll need anything else for the odroid itself though.

4) To set up a linux box using u-boot in read-only mode:
The link you sent is half of it. That would normally be all you need to do, but since it’s using u-boot to bootstrap the boot sequence, you need to run mkimage after any changes to bake it into the uInitrd file. Also just fyi the eMMC acts as any other mounted drive, nothing special there.

References I used:
https://help.ubuntu.com/community/aufsRootFileSystemOnUsbFlash
https://trick77.com/how-to-encrypt-odroid-c1-ubuntu-root-filesystem-dm-crypt-luks/
http://odroid.com/dokuwiki/doku.php?id=en:xu3_building_kernel
http://forum.odroid.com/viewtopic.php?f=111&t=7965

This is the process I did to get the XU4 into read-only mode. (Samson set up the u3, so I’m not sure if the process is exactly the same or not, and I also don’t know if this will work with the c2.)

$> echo aufs >> /etc/initramfs-tools/modules
$> vi /etc/initramfs-tools/scripts/init-bottom/rootaufs
$> chmod 0755 /etc/initramfs-tools/scripts/init-bottom/rootaufs
$> mv /etc/initramfs-tools/scripts/init-bottom/rootaufs /etc/initramfs-tools/scripts/init-bottom/__rootaufs

$> update-initramfs -u
$> mkimage -A arm -O linux -T ramdisk -C none -a 0 -e 0 -n "uInitrd $(uname -r)" -d /boot/initrd.img-$(uname -r) /boot/uInitrd-$(uname -r)
$> cp /boot/uInitrd-$(uname -r) /media/boot/uInitrd

$> vi /media/boot/boot.ini

In step 2 where you edit the rootaufs file, the script is the same as the guide you linked under "rootaufs Script": https://help.ubuntu.com/community/aufsRootFileSystemOnUsbFlash
At the end when you edit the boot.ini file, you want to add "aufs=tmpfs” (without quotes) somewhere in the setenv bootargs line.

5) I set it up to restart the software when it gets killed using systemd. I think the service is called trees.service, but I don’t remember exactly. The commands take the form of `system enable trees.service`. The main commands you’d use are enable, disable, start, stop, and restart. You can also view the logs using `journalctl -fu trees.service`.

I don’t know what what in the service for this project, but if you want to set up a service for something, you’d create a somename.service file inside /etc/systemd/service, then run `systemctl enable somename.service` to add it so it boots up the next time you restart. You can also use start, stop, and restart to control it manually.

Here’s an example script from another project:

[Unit]
Description=SomeProject

[Service]
ExecStart=/home/some_project/run.sh
ExecStop=/bin/pkill java
Restart=always

[Install]
WantedBy=multi-user.target
