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

* pacman aktualisieren: `pacman -Syy`
* reflector installieren: `pacman -S reflector`
* neue Mirrorliste erstellen `reflector -c "Switzerland" -a 6 --sort rate --save /etc/pacman.d/mirrorlist`
* Bootstrap für das System erstellen: `pacstrap /mnt base base-devel linux linux-firmware intel-ucode dialog vim git`
* sollte es Probleme mit den Keys bei der Installation geben:
  * Archlinux GPG Keystore herunterladen: `pacman -S archlinux-keyring`
  * Keyserver unter /etc/pacman.d/gnupg/gpg.conf setzen `keyserver hkps://keyserver.ubuntu.com:443`
  * Update Base: `pacman -Syy && pacman -Syu`
* fstab erstellen: `genfstab -pU /mnt >> /mnt/etc/fstab`
* in das neue System wechseln: `arch-chroot /mnt`
* Ansible installieren: `pacman -S ansible`
* dieses Repository clonen (z.B. nach /opt/)
* group_vars/all/main.yaml anpassen
* Staging Playbook ausführen: `ansible-playbook staging.yaml`
* nach dem das Staging Playbook durchgelaufen ist reboot der Maschine
* Deployment Playbook ausführen: `ansible-playbook deployment.yaml`

## Flatpak als "Container" für Applikationen
