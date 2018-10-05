# How To Install Arch-Linux

* boot from CD
* configure keymap `loadkeys de_CH-latin1`

## Encryption aktivieren

<https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=4&cad=rja&uact=8&ved=2ahUKEwjN7bmDu_LcAhWCHJoKHXQYCBkQwqsBMAN6BAgGEAQ&url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3DP0GISSpLlVI&usg=AOvVaw3splmYsQGRauamq1RFrtjc>

## Legacy Boot konfigurieren

* configure disk `fdisk -l` or `cfdisk`
* normalerweise gibt das /dev/sda zurück
   als nächsten muss man die Platte partitionieren
   `fdisk /dev/sda`
* ich nehme folgende Partitionierung vor:
   `/dev/sda1` - / (root Partion) - 13GB
   `/dev/sda2` - /boot (boot Partion) - 512MB
   `/dev/sda3` - SWAP - der ganze Rest
* im fdisk Menu sind folgende Befehle wichtig:
   `n - (new) partion -> danach p - (primary) -> dann einfach standardmässig vorgehen; Grösse +13G`
* nachher müssen die ersten beiden Partitionen noch bootable werden
   `a -> danach Nummer der Partition`
* Abschluss mit `w -> speichert die Infos in der Partitionstabelle`
* jetzt müssen die einzelnen Partitionen formatiert werden

   ````bash
   mkfs.ext4 /dev/sda1
   mkfs.ext4 /dev/sda2
   mkswap /dev/sda3
   swapon /dev/sda3
   ````

* als nächsten müssen die Partitionen gemountet werden

   ````bash
   mount /dev/sda1 /mnt
   mkdir /mnt/boot
   mount /dev/sda2 /mnt/boot
   ````

## UEFI Boot konfigurieren

* die Partiontable muss im Format GPT erstellt werden, dazu einfach `gdisk` aufrufen
* im Menu mittels `o` eine neue leere GTP Partitiontable erstellen
* das Disklayout ist das gleiche
* für die `boot` partition muss aber mit FAT formatiert werden: `mkfs.fat -F 32 /dev/sdaX`

## use Encryption

* Festplatte wird so partitioniert wie für UEFI
* die Hauptpartition verschlüsseln: `cryptsetup -c aes-xts-plain -y -s 512 luksFormat /dev/sda2`
* Hauptpartition entschlüsseln und LVM mounten: `cryptsetup luksOpen /dev/sda2 lvm`
* LVM für gemountete Partition aktivieren: `pvcreate /dev/mapper/lvm`
* Volumegroup erstellen: `vgcreate main /dev/mapper/lvm`
* Partition(Swap) erstellen: `lvcreate -L XXG -n swap main` - XX Gigabyte einstellen
* Partition(Main) erstellen: `lvcreate -l 100%FREE -n root main`
* Partitionen formatieren:

   ``` bash
   mkfs.ext4 /dev/mapper/main-root
   mkswap /dev/mapper/main-swap
   mkfs.fat -F 32 /dev/sda1

   mount /dev/mapper/main-root /mnt
   mkdir /mnt/boot
   mount /dev/sda1 /mnt/boot
   swapon /dev/mapper/main-swap
   ```

* jetzt erstmal weiter mit der normalen Installation

* Zeitserver setzen: `timedatectl set-ntp true`
* Bootstrap für das System erstellen: `pacstrap /mnt base base-devel intel-ucode wpa_supplicant dialog`
* fstab erstellen: `genfstab -U /mnt >> /mnt/etc/fstab`
* in das neue System wechseln: `arch-chroot /mnt`
* Timezone erstellen: `ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime`
* Hardware Uhr setzen: `hwclock --systohc`
* Update vom Base: `pacman -Syy & pacman -Syu`
* VBOX Utils installieren: `pacman -S virtualbox-guest-utils`
* VMWare Tools installieren: `pacman -S open-vm-tools`
* VIM installieren: `pacman -S vim`
* editieren von `/etc/locale.gen --> de_CH.UTF-8 UTF-8 & en_US.UTF-8 UTF-8`
* aktivieren mittels: `locale-gen`
* Locale Conf erstellen:

   ````bash
   vi /etc/locale.conf
   LANG=en_US.UTF-8
   ````

* Keymap erstellen:

   ````bash
   vi /etc/vconsole.conf
   LANG=de_CH-latin1
   ````

* hostname erstellen:

   ````bash
   vi /etc/hostname
   somecoolname
   ````

* hostname in `/etc/hosts` anpassen

   ````bash
   127.0.0.1 localhost
   127.0.1.1 somecoolname.localdomain somecoolname
   ````

* dhcp Dienst aktivieren: `systemctl enable dhcpcd`
* mit `passwd` root Passwort setzen
* `pacman -S sudo openssh zsh bash-completion terminator` installieren
* ssh Dienst aktivieren: `systemctl enable sshd`
* User erstellen: `useradd -m -s /bin/zsh USERNAME`
* User Passwort setzen: `passwd USERNAME`
* Sudoers anpassen: `USERNAME ALL=(ALL) ALL`

## für Encryption

* `/etc/mkinitcpio.conf` anpassen: `HOOKS="base udev autodetect modconf block keyboard keymap encrypt lvm2 filesystems fsck"`
* Linux Kernel erzeugen: `mkinitcpio -p linux`
* `bootctl --path=/boot install`
* `/boot/loader/loader.conf` anpassen:

   ``` bash
   # timeout 0
   default arch
   ```

* `/boot/loader/entries/arch.conf` erstellen und mit folgenden Werten abfüllen:

   ``` bash
   title    Arch Linux
   linux    /vmlinuz-linux
   initrd   /initramfs-linux.img
   options  cryptdevice=/dev/sda2:main root=/dev/mapper/main-root resume=/dev/mapper/main-swap lang=de locale=de_DE.UTF-8
   ```

## Legacy Boot installieren

* bootloader installieren: `pacman -S grub os-prober`
* bootloader für Harddisk aktivieren `grub-install /dev/sda`
* grub konfigurieren: `grub-mkconfig -o /boot/grub/grub.cfg`

## UEFI Boot installieren

* `bootctl install`
* Loader Conf erstellen: `vim /boot/loader/loader.conf` ggf. die default Einträge entfernen

  ``` bash
  default arch
  timeout 3
  ```

* Entrie Datei erstellen: `vim /boot/loader/entries/arch.conf`

  ``` bash
  title ANZEIGENAME
  linux /vmlinuz-linux #findet man übrigens im /boot Verzeichnis
  initrd /initramfs-linux.img
  options root=PARTUUID=[a-z0-9] rw
  ```

  > Um den Eintrag für die Partions UUID von /dev/sda1 zu bekommen, kann man im vim folgenden Befehl ausführen:
  > `r !blkid` > Der Output wird dann im aktuellen File dargestellt.

* nach der Installation aus arch-chroot ausloggen und neustarten
   `exit`
   `reboot`

## GUI

* X installieren `pacman -S xorg xorg-server xorg-xinit xorg-drivers networkmanager`
* localectl konfigurieren: `localectl set-x11-keymap ch apple de_mac` (Apple)
* localectl konfigurieren: `localectl set-x11-keymap ch dell de_nodeadkeys` (Dell)
* localectl konfigurieren: `localectl set-locale LANG=en_US.UTF-8`
* localectl konfigurieren: `localectl set-keymap de_CH-latin1`
* NetworkManager starten: `systemctl enable NetworkManager`

### Plasma minimal installieren

* Plasma KDE installieren: `pacman -S plasma`

### Plasma automatisch starten

* im .bash_profile (oder entsprechender Shell) folgendes einfügen

   ``` bash
   if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
       exec startx
   fi
   ```

* .xinitrc erstellen

   ``` bash
   exec startkde
   ```

* reboot (dann wird nach dem terminal login automatisch Plasma gestartet)

> alternativ kann man auch die beiden Anpassungen in den Files unterlassen und man startet nach dem Login Plasma mit `startx`

### Plasma normal installieren inklusive Desktop Manager

* Plasma KDE installieren: `pacman -S plasma plasma-meta plasma-wayland-session`
* Desktop manager installieren: `pacman -S sddm`
* Desktop manager aktivieren: `systemctl enable sddm`
* `reboot`

### Keyboard

* `setxkbmap -model apple -layout ch -variant de_mac`

## Applications

* firefox
* ttf-dejavu
* thunderbird
* dolphin

## Pacaur Installation

* `mkdir -p /tmp/pacaur_install`
* `cd /tmp/pacaur_install`
* check if packages are installed: `sudo pacman -S binutils make gcc fakeroot pkg-config --noconfirm --needed`
* `sudo pacman -S expac yajl git --noconfirm --needed`
* `curl -o PKGBUILD "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=cower"`
* `makepkg PKGBUILD --skippgpcheck --install --needed`
* `curl -o PKGBUILD "https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=pacaur"`
* `makepkg PKGBUILD --install --needed`