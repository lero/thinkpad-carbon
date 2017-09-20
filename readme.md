thinkpad-carbon
---------------

Salt configuration to get Arch Linux running on a Thinkpad X1 Carbon 5th generation.
The idea is to run one script from Arch Linux installation and get a working box.

Steps:

1. Fork this repo and adjust `install.sh` and Salt configuration to your needs
2. Boot Arch Linux USB installer
3. Connect to your wifi using `wifi-menu` and run `install.sh`:
    - wget https://raw.githubusercontent.com/xxxxx/thinkpad-carbon/master/install.sh
    - bash install.sh
4. Profit :)
