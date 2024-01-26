pre_src_configure() {
	# https://fedoraproject.org/wiki/Changes/Unit_Names_in_Systemd_Messages
	MYMESONARGS="-Dstatus-unit-format-default=combined ${MYMESONARGS}"
}
