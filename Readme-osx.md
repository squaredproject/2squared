OS X has smart card reader integration and automatically launches pcscd every time a smartcard reader device is connected.

This conflicts with the libnfc-based driver, which is much faster than a pcscd based-tag reader.

You can work around this by killing pcscd manually, or you can prevent pcscd from starting.

To prevent pcscd from starting, edit /System/Library/LaunchDaemons/com.apple.securityd.plist
and add:

  <string>-s</string> 
  <string>off</string> 

below:

  <string>/usr/sbin/securityd</string> 
  <string>-i</string> 

and reboot the system.

Additionally, the config file for libnfc can be found at:
  /usr/local/Cellar/libnfc/1.7.0/etc/nfc/libnfc.conf

add:
  log_level=0
to this file to disable the verbose error logging.
