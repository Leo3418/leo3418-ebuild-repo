pre_src_configure() {
	# Use an alternate Wi-Fi geolocation service after the retirement of
	# Mozilla Location Service
	MYMESONARGS="-Ddefault-wifi-url='https://api.beacondb.net/v1/geolocate' ${MYMESONARGS}"
}
