# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit sh-elf

if [[ "${PV}" == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitea.planet-casio.com/Lephenixnoir/gint.git"
	EGIT_BRANCH="dev"
else
	SRC_URI="https://gitea.planet-casio.com/Lephenixnoir/gint/archive/${PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${PN}"
	KEYWORDS="~amd64"
fi

DESCRIPTION="Library & kernel for add-ins on CASIO fx-9860G and fx-CG50 graphing calculators"
HOMEPAGE="https://gitea.planet-casio.com/Lephenixnoir/gint"

LICENSE="Lephenixnoir"
SLOT="0"

# The 'os-stack' USE flag corresponds to the 'GINT_NO_OS_STACK' CMake option,
# which is set to 'OFF' by default when the project is being built by fxSDK.
# Since 'no*' style USE flags should be avoided according to the devmanual,
# this USE flag is devised to represent the negation of the CMake option
# and is thus enabled by default accordingly.
IUSE="kmalloc-debug +os-stack static-gray"

BDEPEND="
	>=dev-embedded/fxsdk-2.9.0
	>=dev-embedded/sh-elf-binutils-2.39
"

DEPEND="
	dev-embedded/fxlibc
	>=dev-embedded/sh3eb-openlibm-0.7.5_p2
"

src_configure() {
	local GINT_CMAKE_OPTIONS=(
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr/${CHOST}"
		-DGINT_KMALLOC_DEBUG="$(usex kmalloc-debug)"
		-DGINT_NO_OS_STACK="$(usex !os-stack)"
		-DGINT_STATIC_GRAY="$(usex static-gray)"
	)
	set -- fxsdk build -c "${GINT_CMAKE_OPTIONS[@]}"
	echo "${@}" >&2
	"${@}" || die "configure failed"
}

src_compile() {
	set -- fxsdk build VERBOSE=1 ${MAKEOPTS}
	echo "${@}" >&2
	"${@}" || die "compile failed"
}

src_install() {
	set -- fxsdk build VERBOSE=1 ${MAKEOPTS} DESTDIR="${D}" install
	echo "${@}" >&2
	"${@}" || die "install failed"
	einstalldocs
}
