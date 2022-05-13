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

IUSE="kmalloc-debug static-gray user-vram"

BDEPEND="
	dev-embedded/fxsdk
"

DEPEND="
	dev-embedded/fxlibc
"

src_prepare() {
	# Change installation destination of libraries and linker scripts
	# from ${FXSDK_COMPILER_INSTALL} to ${FXSDK_COMPILER_INSTALL}/lib
	sed -i \
		-e '/TARGETS/s/\(${FXSDK_COMPILER_INSTALL}\)/\1\/lib/g' \
		-e '/${LINKER_SCRIPT}/{n;s/\(${FXSDK_COMPILER_INSTALL}\)/\1\/lib/g}' \
		CMakeLists.txt ||
		die "Failed to modify installation destination paths"

	# Fix up paths to this package's headers in CMake module files, so
	# projects created by fxSDK can find them.  This is necessary because
	# the headers are not being installed to the GCC installation path, and
	# GCC's '-print-file-name' option does not return the absolute paths to
	# these headers for this reason.
	sed -i \
		-e "s|\(\${CMAKE_C_COMPILER}\) -print-file-name=include\(.*\)|sh -c \"echo \\\\\"${EPREFIX}/usr/\$(\1 -dumpmachine)/include\2\\\\\"\"|g" \
		cmake/FindGint.cmake ||
		die "Failed to modify CMake module files"

	default
}

src_configure() {
	local GINT_CMAKE_OPTIONS=(
		-DCMAKE_INSTALL_PREFIX="${EPREFIX}/usr/${CHOST}"
		-DGINT_KMALLOC_DEBUG="$(usex kmalloc-debug)"
		-DGINT_STATIC_GRAY="$(usex static-gray)"
		-DGINT_USER_VRAM="$(usex user-vram)"
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
