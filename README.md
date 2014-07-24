# 2squared

Big LED trees with blinky blinks

## Technical Details

The way the guts work for this is that the LXEngine (http://heronarts.com/lx/api/heronarts/lx/LXEngine.html) has an arbitrary number of LXDecks (http://heronarts.com/lx/api/heronarts/lx/LXDeck.html), it runs them all on each frame and combines the results based on the LXTransition (http://heronarts.com/lx/api/heronarts/lx/transition/LXTransition.html) set for each LXDeck.

## Installation

* Download Processing: https://processing.org/download/?processing
* Download zip or clone this repo
* Open `trees.pde` in Processing and run the sketch

### Mac OS X

* Install Homebrew `ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"`
* Do all the brewy stuff: `brew doctor`
* Install libnfc: `brew install libnfc`

#### Other stuff

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
