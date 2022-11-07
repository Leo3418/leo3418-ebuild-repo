# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit sh-elf toolchain-funcs

if [[ "${PV}" == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitea.planet-casio.com/Lephenixnoir/OpenLibm.git"
else
	MY_PV="$(ver_cut 1-3)-sh3eb"
	[[ "$(ver_cut 4)" == p ]] && [[ -n "$(ver_cut 5)" ]] &&
		MY_PV+="-$(ver_cut 5)"
	SRC_URI="https://gitea.planet-casio.com/Lephenixnoir/OpenLibm/archive/${MY_PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/openlibm"
	KEYWORDS="~amd64"
fi

DESCRIPTION="A fork of OpenLibm intended for add-in development on CASIO graphing calculators"
HOMEPAGE="https://gitea.planet-casio.com/Lephenixnoir/OpenLibm"

LICENSE="public-domain MIT ISC BSD-2 LGPL-2.1+"
# Only static libraries will be installed, so no sub-slot is needed
SLOT="0"

src_configure() {
	# The Makefile uses the ARCH variable's value to set toolchain flags for
	# different platforms.  Unfortunately, the ARCH variable is also used by
	# Gentoo package managers as per the PMS, and the value set by the package
	# manager may cause unsupported toolchain flags to be used.  For example,
	# when this package is being built on an x86_64 system, ARCH="amd64" will
	# be set, and the Makefile will add toolchain flags for x86_64, some of
	# which are unsupported by the sh-elf toolchain.  If this variable's value
	# is non-empty, then the Makefile will assign it a value based on the
	# toolchain's target platform, hence correct toolchain flags can be used.
	unset ARCH

	export USEGCC=1
	tc-export CC AR
}

src_test() {
	# Upstream does not guarantee any possibility to run the tests
	:
}

src_install() {
	emake DESTDIR="${D}" prefix="${EPREFIX}/usr/${CHOST}" \
		install-static-superh install-headers-superh
	einstalldocs
}
