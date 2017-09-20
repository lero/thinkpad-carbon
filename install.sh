# Arch Linux installation script

disk="/dev/nvme0n1"

# remove file system signatures
for partition in ${disk}p*; do
  wipefs -a $partition
done

# cleanup partition table
sgdisk -Z $disk

# create /boot/efi and / but leave some space for OpenBSD
echo -e "n\n\n\n+200M\nef00\nw\ny" | gdisk $disk
echo -e "n\n\n\n+208G\nw\ny" | gdisk $disk

# encrypt entire partition
cryptsetup -y luksFormat ${disk}p2
cryptsetup open ${disk}p2 cryptroot

# create file systems and mount
mkfs.ext4 /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
mkdir /mnt/boot
mkfs.vfat ${disk}p1
mount ${disk}p1 /mnt/boot

# set pacman mirror and enable testing/community-testing
echo "Server = http://ftp.nluug.nl/os/Linux/distr/archlinux/\$repo/os/\$arch" > /etc/pacman.d/mirrorlist
sed -i -e '72, 73 s/^#*//' -e '81, 82 s/^#*//' /etc/pacman.conf

# install the base system
pacstrap /mnt base
genfstab -U -p /mnt >> /mnt/etc/fstab

# now inside the final system
cat << EOF | arch-chroot /mnt
# enable yaourt and install salt
echo -e '[archlinuxfr]\nSigLevel = Never\nServer = http://repo.archlinux.fr/\$arch' >> /etc/pacman.conf
pacman -Sy
pacman -S yaourt --noconfirm
yaourt -S salt git --noconfirm

# clone needed repos and create some dirs/links
git clone https://github.com/lero/thinkpad-carbon.git /srv/salt
git clone https://github.com/lero/dotfiles.git /srv/dotfiles
git clone https://github.com/lero/archlinux.git /srv/archlinux
mkdir -p /var/log/salt /srv/salt/files
ln -s /srv/dotfiles /srv/salt/files/home
ln -s /srv/archlinux/* /srv/salt/files/

# install bootloader before running salt
bootctl install

# salt _will_ fail on some items (we can't start some defined services here
# because we are in a chroot and systemd knows that) but hopefully it will
# do all needed stuff to boot
salt-call --local state.highstate --pillar-root=/srv/salt/pillar

# last bits
echo carbon > /etc/hostname
locale-gen
mkinitcpio -p linux

# setup initial user config for WM and stuff
/home/gms/bin/sreset
EOF

# fingers crossed
umount /mnt/boot
umount /mnt
sync
echo b > /proc/sysrq-trigger
