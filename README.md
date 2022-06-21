# How To Install Arch-Linux

* boot from CD
* configure keymap `loadkeys de_CH-latin1`

## LVM Installation (UEFI)

* configure disk `fdisk -l` or `cfdisk`
* normalerweise gibt das /dev/sda zurück
   als nächsten muss man die Platte partitionieren

   `fdisk /dev/sda`

* Partitionstabelle erstellen: `gpt`

* Partitionierung erfolgt wiefolgt:
  `/dev/sda1` - 512MB - Bootpartition
  `/dev/sda2` - Rest

* physical Volume erstellen
  `pvcreate /dev/sda2`

* Volumegroup erstellen
  `vgcreate main /dev/sda2`

* logical Volumes erstellen
  `lvcreate -L XXGB -n swap main` XX - Gigabyte erstellen
  `lvcreate -l 100%FREE -n root main`

* Partitionen formatieren
  `mkfs.ext4 /dev/mapper/main-root`
  `mkswap /dev/mapper/main-swap`
  `mkfs.fat -F 32 /dev/sda1`

* Mountpoints aktivieren

   ```bash
   mount /dev/mapper/main-root /mnt
   mkdir /mnt/boot
   mount /dev/sda1 /mnt/boot
   swapon /dev/mapper/main-swap
   ```

## Encryption

* Encryption aktivieren
<https://www.google.com/url?sa=t&rct=j&q=&esrc=s&source=web&cd=4&cad=rja&uact=8&ved=2ahUKEwjN7bmDu_LcAhWCHJoKHXQYCBkQwqsBMAN6BAgGEAQ&url=https%3A%2F%2Fwww.youtube.com%2Fwatch%3Fv%3DP0GISSpLlVI&usg=AOvVaw3splmYsQGRauamq1RFrtjc>

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

## Installation

* Zeitserver setzen: `timedatectl set-ntp true`
* pacman aktualisieren: `pacman -Syy`
* reflector installieren: `pacman -S reflector`
* neue Mirrorliste erstellen `reflector -c "Switzerland" -a 6 --sort rate --save /etc/pacman.d/mirrorlist`
* Bootstrap für das System erstellen: `pacstrap /mnt base base-devel linux linux-firmware intel-ucode dialog vim git`
* fstab erstellen: `genfstab -pU /mnt >> /mnt/etc/fstab`
* in das neue System wechseln: `arch-chroot /mnt`
* PC Speaker ausschalten: `rmmode pcspkr`
* Archlinux GPG Keystore herunterladen: `pacman -S archlinux-keyring`
* Keyserver unter /etc/pacman.d/gnupg/gpg.conf setzen `keyserver hkps://keyserver.ubuntu.com:443`
* Update Base: `pacman -Syy & pacman -Syu`
* Archlinux GPG Keystore herunterladen: `pacman -S openssh python os-prober networkmanager network-manager-applet iwd`
* unter /etc/NetworkManager/NetworkManager.conf Eintrag erstellen:
  ```
  [device]
  wifi.backend=iwd
  ```
* iwd Service starten `systemctl enable --now iwd sshd NetworkManager`

* Timezone erstellen: `ln -sf /usr/share/zoneinfo/Europe/Zurich /etc/localtime`
* Hardware Uhr setzen: `hwclock --systohc --utc`
* Locale Conf erstellen:

   ```bash
   echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
   echo "de_CH.UTF-8 UTF-8" >> /etc/locale.gen
   locale-gen
   echo "LANG=en_US.UTF-8" >> /etc/locale.conf
   ```

* Keymap & Hostname erstellen:

   ```bash
   echo "myhostname" > /etc/hostname
   echo "KEYMAP=de_CH-latin1" >> /etc/vconsole.conf
   echo "FONT=lat9w-16" >> /etc/vconsole.conf
   echo "FONT_MAP=8859-1_to_uni" >> /etc/vconsole.conf
   echo "127.0.0.1 localhost myhostname" >> /etc/hosts
   echo "127.0.1.1 myhostname.localdomain myhostname" >> /etc/hosts
   ```

* mit `passwd` root Passwort setzen

* User erstellen: `useradd -mG wheel $USERNAME`
* User Passwort setzen: `passwd USERNAME`
* Wheel Group in /etc/sudoers aktivieren: `%wheel ALL=(ALL) ALL`
* für den Kernel müssen folgende Pakete installiert werden: `pacman -S linux linux-firmware lvm2`

## für Encryption

* pacman -S linux lvm2 linux-firmware
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

## UEFI Boot für LVM installieren

* `bootctl install`
* Loader Conf erstellen: `vim /boot/loader/loader.conf` ggf. die default Einträge entfernen

  ``` bash
  default arch
  timeout 3
  ```

* Entry Datei erstellen: `vim /boot/loader/entries/arch.conf`

  ``` bash
  title ANZEIGENAME
  linux /vmlinuz-linux #findet man übrigens im /boot Verzeichnis
  initrd /initramfs-linux.img
  options root=/dev/mapper/root-main resume=/dev/mapper/swap-main rw
  ```

* nach der Installation aus arch-chroot ausloggen und neustarten
   `exit`
   `reboot`

### Plasma automatisch starten

* im .bash_profile (oder entsprechender Shell) folgendes einfügen

   ``` bash
   if [[ ! $DISPLAY && $XDG_VTNR -eq 1 ]]; then
       exec startx
   fi
   ```

### Plasma normal installieren inklusive Desktop Manager

* Plasma KDE installieren: `pacman -S plasma plasma-meta plasma-wayland-session`
* Desktop manager installieren: `pacman -S sddm`
* Desktop manager aktivieren: `systemctl enable sddm`
* `reboot`
