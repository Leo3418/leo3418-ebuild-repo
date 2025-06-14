# Copyright 2022-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..13} )
inherit cmake optfeature python-r1

if [[ "${PV}" == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://git.planet-casio.com/Lephenixnoir/fxsdk.git"
	EGIT_BRANCH="dev"
else
	SRC_URI="https://git.planet-casio.com/Lephenixnoir/fxsdk/archive/${PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${PN}"
	KEYWORDS="~amd64"
fi

DESCRIPTION="Development tools for add-ins on CASIO fx-9860G and fx-CG50 graphing calculators"
HOMEPAGE="https://git.planet-casio.com/Lephenixnoir/fxsdk"

LICENSE="MIT"
SLOT="0"

IUSE="sdl udisks"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="
	virtual/pkgconfig
	${PYTHON_DEPS}
"

DEPEND="
	media-libs/libpng:0/16
	sys-libs/ncurses:=
	virtual/libusb:1
	sdl? (
		media-libs/libsdl2
	)
	udisks? (
		sys-fs/udisks:2
		dev-libs/glib:2
	)
"

RDEPEND="
	${DEPEND}
	${PYTHON_DEPS}
	dev-python/pillow[${PYTHON_USEDEP}]
"

# Use the same CTARGET as dev-embedded/sh-elf-binutils
CTARGET="sh3eb-fx-elf"

PATCHES=(
	"${FILESDIR}/${PN}-2.10.0-build-shared-libfxlink.patch"
	"${FILESDIR}/${PN}-2.10.0-fix-merged-usr.patch"
)

src_prepare() {
	# ebuilds for the sh-elf toolchain try to follow other common Gentoo
	# cross-compiling toolchain packages with regards to file installation
	# locations, which differ from the SDK's default search paths
	sed -i \
		-e "s|\(/share/fxsdk/sysroot\)/sh3eb-elf|\1/${CTARGET}|g" \
		-e 's|/share/fxsdk/sysroot||g' \
		fxsdk/fxsdk.sh ||
		die "Failed to adjust sh-elf toolchain paths"

	# Fix up the FXSDK_COMPILER_INSTALL path in CMake module files, so the
	# SDK will no longer install packages to the GCC installation path
	sed -i \
		-e "s|\(\${CMAKE_C_COMPILER}\) --print-file-name=\.|sh -c \"echo \\\\\"${EPREFIX}/usr/\$(\1 -dumpmachine)\\\\\"\"|g" \
		fxsdk/cmake/{FX9860G,FXCG50}.cmake ||
		die "Failed to modify CMake module files"

	# Install CMake module files to the conventional path
	sed -i -e 's|lib/cmake\(/fxsdk\)\?|share/cmake/Modules|g' \
		CMakeLists.txt fxsdk/fxsdk.sh ||
		die "Failed to modify installation destination of CMake module files"

	cmake_src_prepare
}

src_configure() {
	local mycmakeargs=(
		-DFXLINK_DISABLE_SDL2="$(usex !sdl)"
		-DFXLINK_DISABLE_UDISKS2="$(usex !udisks)"
	)
	cmake_src_configure
}

src_install() {
	cmake_src_install

	local fxconv_python_files=( "${ED}/usr/bin/fxconv"{,.py} )
	mv "${fxconv_python_files[@]}" "${T}" ||
		die "Failed to move Python files for fxconv to ${T}"
	python_foreach_impl python_domodule "${T}/fxconv.py"
	python_foreach_impl python_doscript "${T}/fxconv"
}

pkg_postinst() {
	optfeature_header \
	"To build projects created using this SDK, these packages might be needed:"
	optfeature "a library and kernel for add-ins" dev-embedded/gint
	optfeature "installing projects to fx-9860G" dev-embedded/p7utils
}
