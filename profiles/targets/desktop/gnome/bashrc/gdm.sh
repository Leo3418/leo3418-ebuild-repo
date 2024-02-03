pre_src_configure() {
	# Allow GDM to launch GNOME Initial Setup
	MYMESONARGS="-Ddefault-pam-config=arch ${MYMESONARGS}"
}
