# Do not install the file that sets the number of zram devices to create
INSTALL_MASK+=" ${EPREFIX}/etc/modprobe.d/zram.conf"
