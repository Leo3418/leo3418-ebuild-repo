# Copyright 2022-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="Utilities for connecting to CASIO fx-9860G graphing calculators via P7 protocol"
HOMEPAGE="https://p7.planet-casio.com/en.html"
SRC_URI="https://p7.planet-casio.com/pub/p7utils-${PV}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

IUSE="+man"

BDEPEND="
	virtual/pkgconfig
	man? ( app-text/asciidoc )
"

RDEPEND="
	dev-embedded/libp7[usb]
	media-libs/libsdl[X,video]
"

DEPEND="
	${RDEPEND}
"

PATCHES=(
	"${FILESDIR}/${P}-fix-gmake-4.4.patch"
)

src_configure() {
	local myconf=(
		# Increase output verbosity of build process
		--make-full-log

		# Unlike libp7, setting this package's '--target' configuration
		# option will enable cross-compilation settings that alter some
		# files' installation destination in an undesirable way (but
		# nothing else beyond that would be changed), so this option
		# has to be omitted for this package.  This will cause the host
		# machine's configuration name to be dropped from the values of
		# toolchain program variables in this project's Makefile (e.g.
		# x86_64-pc-linux-gnu-gcc -> gcc), which is undesirable either;
		# but this issue can be fixed easier by manually specifying the
		# prefixed toolchain program names to Make during src_compile.

		# Also unlike libp7, CFLAGS and LDFLAGS are not recognized by
		# this package's configure script either, so they must be set
		# in src_compile instead as well.

		$(usev !man --noinstall-manpages)
	)

	econf "${myconf[@]}"
}

src_compile() {
	local CC="$(tc-getCC)"
	# For more details, please search for these variables' names in
	# Makefile.vars; to find toolchain program variables that need
	# to be overridden, please search for 'TARGET' in the same file
	emake \
		CC="${CC}" LD="${CC}" \
		LDR="$(tc-getLD)" PKGCONFIG="$(tc-getPKG_CONFIG)" \
		CMOREFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
}

src_install() {
	# The Makefile installs a compressed copy of this package's manual pages,
	# which would trigger a QA notice from Portage if manual pages were not
	# added to the exclusion list for compression
	use man && docompress -x /usr/share/man

	default
}
