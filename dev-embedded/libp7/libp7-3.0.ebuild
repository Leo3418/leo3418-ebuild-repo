# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit udev

DESCRIPTION="Library for connecting to CASIO fx-9860G graphing calculators via P7 protocol"
HOMEPAGE="https://p7.planet-casio.com/en.html"
SRC_URI="https://p7.planet-casio.com/pub/libp7-${PV}.tar.gz"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64"

IUSE="man +usb"

BDEPEND="
	virtual/pkgconfig
	man? ( app-text/asciidoc )
"

RDEPEND="
	usb? ( virtual/libusb:1 )
"

DEPEND="
	${RDEPEND}
"

src_configure() {
	local myconf=(
		# Increase output verbosity of build process
		--make-full-log

		# There is only one small udev rule file, which
		# can and should be unconditionally installed
		--udev
		--udevrulesdir="$(get_udevdir)/rules.d"

		# This project's configure script recognizes '--target'
		# instead of '--host' for the configuration name of CHOST
		--target="${CHOST}"

		CFLAGS="${CFLAGS}"
		LDFLAGS="${LDFLAGS}"

		$(usev !man --no-manpages)
		$(usev !usb --no-libusb)
	)

	econf "${myconf[@]}"
}

src_install() {
	# The Makefile installs a compressed copy of this package's manual pages,
	# which would trigger a QA notice from Portage if manual pages were not
	# added to the exclusion list for compression
	use man && docompress -x /usr/share/man

	default
}

pkg_postinst() {
	udev_reload
}

pkg_postrm() {
	udev_reload
}
