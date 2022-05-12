# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake flag-o-matic sh-elf

if [[ "${PV}" == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitea.planet-casio.com/Vhex-Kernel-Core/fxlibc.git"
	EGIT_BRANCH="dev"
else
	SRC_URI="https://gitea.planet-casio.com/Vhex-Kernel-Core/fxlibc/archive/${PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${PN}"
	KEYWORDS="~amd64"
fi

DESCRIPTION="FxLibc: A C standard library for CASIO fx-9860G and fx-CG50 graphing calculators"
HOMEPAGE="https://gitea.planet-casio.com/Vhex-Kernel-Core/fxlibc"

# CC0-1.0 for the FxLibc proper
# BSD for 3rdparty/tinymt32
# MIT for 3rdparty/grisu2b_59_56
LICENSE="CC0-1.0 BSD MIT"
SLOT="0"

DEPEND="
	dev-embedded/sh3eb-openlibm
"

src_configure() {
	local SYSROOT="${ESYSROOT}/usr/${CHOST}"
	append-cppflags -I"${SYSROOT}/include/openlibm"

	local mycmakeargs=(
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr/${CHOST}"
	)

	# Adapted from https://gitea.planet-casio.com/Vhex-Kernel-Core/fxlibc/src/branch/master/giteapc.make
	append-flags -nostdlib
	mycmakeargs+=(
		-DFXLIBC_TARGET=gint
	)

	# Adapted from https://gitea.planet-casio.com/Vhex-Kernel-Core/fxlibc/src/branch/master/cmake/toolchain-sh.cmake
	local KERNEL="Generic"

	cmake_src_configure
}
