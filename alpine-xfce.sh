#preparation Alpine
sed -i -r 's|#PermitRootLogin.*|PermitRootLogin yes|g' /etc/ssh/sshd_config
rc-service sshd restart;rc-update add sshd default

cat > /root/.cshrc << EOF
unsetenv DISPLAY || true
HISTCONTROL=ignoreboth
EOF
cp /root/.cshrc  /root/.bashrc
 echo "root:rrrr" | chpasswd

hostname alpine-desktop
echo 'hostname="alpine-desktop"' > /etc/conf.d/hostname 
echo "alpine-desktop" > /etc/hostname
cat > /etc/hosts << EOF
127.0.0.1 alpine-desktop localhost.localdomain localhost
::1 localhost localhost.localdomain
EOF

cat > /etc/apk/repositories << EOF
http://mirror.hyperdedic.ru/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/main
http://mirror.hyperdedic.ru/alpine/v$(cat /etc/alpine-release | cut -d'.' -f1,2)/community
EOF

apk update

apk add bash && add-shell '/bin/bash'

apk add mandoc man-pages nano binutils coreutils readline \
 sed attr dialog lsof less groff wget curl \
 file lz4 arch-install-scripts gawk tree pciutils usbutils lshw \
 zip p7zip xz tar cabextract cpio binutils lha acpi musl-locales musl-locales-lang \
 e2fsprogs e2fsprogs-doc btrfs-progs btrfs-progs-doc exfat-utils \
 f2fs-tools f2fs-tools-doc dosfstools dosfstools-doc xfsprogs xfsprogs-doc jfsutils jfsutils-doc \
 arch-install-scripts util-linux zram-init tzdata tzdata-utils

apk add font-terminus

setfont /usr/share/consolefonts/ter-132n.psf.gz

sed -i "s#.*consolefont.*=.*#consolefont="ter-132n.psf.gz"#g" /etc/conf.d/consolefont

rc-update add consolefont boot

#setup system users

apk add shadow shadow-uidmap doas musl-locales musl-locales-lang

cat > /tmp/tmp.tmp << EOF
set history = 10000
set prompt = "$ "
EOF

mkdir /etc/skel
cat /tmp/tmp.tmp > /etc/skel/.cshrc
cat /tmp/tmp.tmp > /etc/skel/.bashrc

cat > /etc/skel/.Xresources << EOF
Xft.antialias: 0
Xft.rgba:      rgb
Xft.autohint:  0
Xft.hinting:   1
Xft.hintstyle: hintslight
EOF

cat > /etc/default/useradd << EOF
# useradd defaults file
HOME=/home
INACTIVE=-1
EXPIRE=
SHELL=/bin/bash
SKEL=/etc/skel
CREATE_MAIL_SPOOL=yes
EOF

cat > /etc/login.defs << EOF
USERGROUPS_ENAB yes
SYSLOG_SU_ENAB		yes
SYSLOG_SG_ENAB		yes
SULOG_FILE	/var/log/sulog
SU_NAME		su
EOF

useradd -m -U -c "" -G wheel,input,disk,floppy,cdrom,dialout,audio,video,lp,netdev,games,users alpine

for u in $(ls /home); do for g in disk lp floppy audio cdrom dialout video lp netdev games users; do addgroup $u $g; done;done

#setup hardware support

apk add acpi acpid acpid-openrc alpine-conf eudev eudev-doc eudev-rule-generator eudev-openrc \
 pciutils util-linux arch-install-scripts zram-init acpi-utils rsyslog \
 fuse fuse-exfat-utils fuse-exfat avfs pcre2 cpufreqd bluez bluez-openrc \
 wpa_supplicant dhcpcd chrony macchanger wireless-tools iputils linux-firmware \
 networkmanager networkmanager-lang

modprobe btusb && echo "btusb" >> /etc/modprobe
setup-devd udev

rc-update add rsyslog
rc-update add udev
rc-update add acpid
rc-update add cpufreqd
rc-update add fuse
rc-update add bluetooth
rc-update add chronyd
rc-update add wpa_supplicant
rc-update add networkmanager

rc-service networking restart

rc-service wpa_supplicant restart

rc-service bluetooth restart

rc-service udev restart 

rc-service fuse restart

rc-service cpufreqd restart

rc-service rsyslog restart

#setup audio and video

apk add xinit xorg-server xorg-server-xnest xorg-server-xnest xorg-server-doc \
 xf86-video-vesa xf86-video-amdgpu xf86-video-nouveau xf86-video-intel \
 linux-firmware-amdgpu linux-firmware-radeon linux-firmware-nvidia linux-firmware-i915 linux-firmware-intel \
 xf86-video-apm xf86-video-vmware xf86-video-ati xf86-video-nv xf86-video-openchrome \
 xf86-video-r128 xf86-video-qxl xf86-video-sis xf86-video-i128 xf86-video-i740 \
 xf86-video-savage xf86-video-s3virge xf86-video-chips xf86-video-tdfx xf86-video-ast \
 xf86-video-rendition xf86-video-ark xf86-video-siliconmotion xf86-video-fbdev \
 xf86-video-dummy xf86-input-evdev xf86-video-modesetting xf86-input-libinput \
 mesa mesa-gl mesa-utils mesa-osmesa mesa-egl mesa-gles mesa-dri-gallium mesa-va-gallium libva-intel-driver intel-media-driver linux-firmware-amd

apk add libxinerama xrandr kbd setxkbmap bluez bluez-openrc \
 dbus dbus-x11 udisks2 udisks2-lang \
 gvfs gvfs-fuse gvfs-archive gvfs-dav gvfs-nfs gvfs-lang


dbus-uuidgen > /var/lib/dbus/machine-id

rc-update add dbus

apk add font-noto-all ttf-dejavu ttf-linux-libertine ttf-liberation \
 font-bitstream-type1 font-bitstream-100dpi font-bitstream-75dpi \
 font-adobe-utopia-type1 font-adobe-utopia-75dpi font-adobe-utopia-100dpi \
 font-isas-misc

apk add alsa-lib alsa-utils alsa-plugins alsa-tools alsaconf sndio \
 pulseaudio pulseaudio-bluez pulseaudio-equalizer

amixer sset Master unmute;  amixer sset PCM unmute;  amixer set Master 100%;  amixer set PCM 100%

rc-update add alsa

rc-service dbus restart

rc-service alsa restart

for u in $(ls /home); do chown -R $u:$u /home/$u; done

#Instalation Desktop Xfce4 Alpine

apk add gtk-update-icon-cache hicolor-icon-theme paper-gtk-theme adwaita-icon-theme xdg-user-dirs-gtk \
 numix-icon-theme numix-themes numix-themes-gtk2 numix-themes-gtk3 numix-themes-metacity numix-themes-openbox numix-themes-xfce4-notifyd numix-themes-xfwm4

apk add polkit polkit-openrc polkit-elogind networkmanager-elogind linux-pam \
 libcanberra libcanberra-gtk3 libcanberra-gtk2 libcanberra-gstreamer libcanberra-pulse \
 xfce4 xfce4-session xfce4-panel xfce4-terminal xarchiver mousepad \
 xfwm4-themes xfce-polkit xfce4-skel xfce4-power-manager xfce4-settings \
 xfce4-clipman-plugin xfce4-xkb-plugin xfce4-screensaver xfce4-screenshooter xfce4-taskmanager \
 xfce4-panel-lang xfce4-clipman-plugin-lang xfce4-xkb-plugin-lang xfce4-screenshooter-lang \
 xfce4-taskmanager-lang xfce4-battery-plugin-lang xfce4-power-manager-lang xfce4-settings-lang \
 gvfs gvfs-fuse gvfs-archive gvfs-afp gvfs-afp gvfs-afc gvfs-cdda gvfs-gphoto2 gvfs-mtp \
 libreoffice evince evince-lang evince-doc

for u in $(ls /home); do chown -R $u:$u /home/$u; done

#Login manager and user configurations

apk add elogind elogind-openrc lightdm lightdm-lang lightdm-gtk-greeter \
 polkit polkit-openrc polkit-elogind  networkmanager-elogind linux-pam \
 network-manager-applet network-manager-applet-lang vte3

rc-update add dbus
rc-update add lightdm

rc-service networkmanager restart

rc-service lightdm restart

#desktop integration and device media

apk add xdg-desktop-portal xdg-desktop-portal-wlr xdg-desktop-portal-lang xdg-desktop-portal-gtk xdg-desktop-portal-gtk-lang

#multimedia and hardware media device access for the users

apk add gst-plugins-base gst-plugins-bad gst-plugins-ugly gst-plugins-good gst-plugins-good-gtk \
 libcanberra-gtk2 libcanberra-gtk3 libcanberra-gstreamer \
 mediainfo ffmpeg ffmpeg-doc ffmpeg-libs lame lame-doc rtkit rtkit-doc \
 mpv mpv-doc libxinerama xrandr pango pixman

apk add gvfs-fuse ntfs-3g gvfs-cdda gvfs-afp gvfs-mtp gvfs-smb gvfs-lang \
 gvfs-afc gvfs-nfs gvfs-archive gvfs-dav gvfs-gphoto2 gvfs-avahi

for u in $(ls /home); do for g in plugdev audio cdrom dialout video netdev; do addgroup $u $g; done;done

cat > /etc/network/interfaces << EOF
auto lo
iface lo inet loopback
EOF

service networking restart

service wpa_supplicant restart

service networkmanager restart

#End!) Reboot!)