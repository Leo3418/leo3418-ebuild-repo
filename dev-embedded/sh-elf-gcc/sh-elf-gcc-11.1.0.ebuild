# Copyright 1999-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="gcc"
MY_P="${MY_PN}-${PV}"

inherit flag-o-matic gnuconfig libtool

DESCRIPTION="Cross-compiling GCC targeted at SH3/SH4 processors on CASIO graphing calculators"
HOMEPAGE="
	https://gitea.planet-casio.com/Lephenixnoir/sh-elf-gcc
	https://gcc.gnu.org/
"
SRC_URI="mirror://gnu/gcc/gcc-${PV}/gcc-${PV}.tar.xz"

LICENSE="GPL-3+ LGPL-3+ || ( GPL-3+ libgcc libstdc++ gcc-runtime-library-exception-3.1 ) FDL-1.3+"
SLOT="0"
KEYWORDS="~amd64"

# GCC's configure script may automagically enable support for installed
# dependencies that it detects if the related configuration option is never
# specified.  The scripts in the sh-elf-gcc repository barely include any such
# options, so a lot of dependencies' support would be automagically configured.
#
# To minimize the difference between the compiler built by this ebuild and the
# compiler one might get by running the sh-elf-gcc scripts outside Portage on a
# Gentoo system, USE flags whose USE-conditional dependencies are installed in
# a new stage3 environment are enabled by default.  Such USE flags include:
#
# - zstd: app-arch/zstd pulled in by sys-apps/portage
IUSE="custom-cflags graphite +nls valgrind +zstd"

BDEPEND="
	dev-embedded/sh-elf-binutils
	>=sys-devel/bison-1.875
	>=sys-devel/flex-2.5.4
	nls? ( sys-devel/gettext )
	valgrind? ( dev-util/valgrind )
"

RDEPEND="
	sys-libs/zlib
	virtual/libiconv
	>=dev-libs/gmp-4.3.2:0=
	>=dev-libs/mpfr-2.4.2:0=
	>=dev-libs/mpc-0.8.1:0=
	graphite? ( >=dev-libs/isl-0.14:0= )
	nls? ( virtual/libintl )
	zstd? ( app-arch/zstd:= )
"

DEPEND="
	${RDEPEND}
"

S="${WORKDIR}/${MY_P}"
MY_BUILDDIR="${WORKDIR}/build"

# Use the same CTARGET as dev-util/sh-elf-binutils
CTARGET="sh3eb-fx-elf"
PROGRAM_PREFIX="${PN%"${MY_PN}"}"

pkg_setup() {
	# we dont want to use the installed compiler's specs to build gcc
	unset GCC_SPECS
	unset LANGUAGES #265283
}

src_prepare() {
	default

	# Fixup libtool to correctly generate .la files with portage
	elibtoolize --portage --shallow --no-uclibc

	gnuconfig_update

	local f
	if [[ -x contrib/gcc_update ]] ; then
		einfo "Touching generated files"
		./contrib/gcc_update --touch | \
			while read f ; do
				einfo "  ${f%%...}"
			done
	fi
}

src_configure() {
	PREFIX="${EPREFIX}/usr"
	LIBPATH="${PREFIX}/lib/gcc/${CTARGET}/${PV}"
	INCLUDEPATH="${LIBPATH}/include"
	BINPATH="${PREFIX}/bin"
	DATAPATH="${PREFIX}/share/gcc-data/${CTARGET}/${PV}"
	STDCXX_INCDIR="${LIBPATH}/include/g++-v$(ver_cut 1)"
	MANPATH="${PREFIX}/share/man"

	if ! use custom-cflags; then
		# Over-zealous CFLAGS can often cause problems.  What may work for one
		# person may not work for another.  To avoid a large influx of bugs
		# relating to failed builds, we strip most CFLAGS out to ensure as few
		# problems as possible.
		strip-flags
		# Lock gcc at -O2; we want to be conservative here.
		filter-flags '-O?'
		append-flags -O2
	fi

	einfo "CFLAGS=\"${CFLAGS}\""
	einfo "CXXFLAGS=\"${CXXFLAGS}\""
	einfo "LDFLAGS=\"${LDFLAGS}\""

	mkdir -p "${MY_BUILDDIR}" || die "Failed to create build directory"
	cd "${MY_BUILDDIR}" || die "Failed to change to build directory"

	local confgcc=(
		--host="${CHOST}"
		--target="${CTARGET}"
	)
	[[ -n "${CBUILD}" ]] && confgcc+=( --build="${CBUILD}" )

	confgcc+=(
		--prefix="${PREFIX}"
		--bindir="${BINPATH}"
		--includedir="${INCLUDEPATH}"
		--datadir="${DATAPATH}"
		--mandir="${MANPATH}"
		--infodir="${DATAPATH}/info"
		--with-gxx-include-dir="${STDCXX_INCDIR}"
		--with-pkgversion="${PN}"
	)

	confgcc+=(
		--with-system-zlib
		$(use_enable valgrind valgrind-annotations)
		$(use_with zstd)
	)

	if use nls ; then
		confgcc+=( --enable-nls --without-included-gettext )
	else
		confgcc+=( --disable-nls )
	fi

	confgcc+=( $(use_with graphite isl) )
	use graphite && confgcc+=( --disable-isl-version-check )

	### Cross-compiler options
	confgcc+=(
		--enable-poison-system-directories
	)

	confgcc+=( ${EXTRA_ECONF} )

	# Adapted from https://gitea.planet-casio.com/Lephenixnoir/sh-elf-gcc/src/branch/master/configure.sh
	local GCC_LANG="c,c++"
	confgcc+=(
		--with-multilib-list=m3,m4-nofpu
		--enable-languages="${GCC_LANG}"
		--without-headers
		--with-newlib
		--program-prefix="${PROGRAM_PREFIX}"
		--enable-libssp
		--enable-lto
	)

	echo
	einfo "PREFIX:          ${PREFIX}"
	einfo "BINPATH:         ${BINPATH}"
	einfo "LIBPATH:         ${LIBPATH}"
	einfo "DATAPATH:        ${DATAPATH}"
	einfo "STDCXX_INCDIR:   ${STDCXX_INCDIR}"
	echo
	einfo "Languages:       ${GCC_LANG}"
	echo
	einfo "Configuring GCC with: ${confgcc[@]//--/\\n\\t--}"
	echo

	addwrite /dev/zero
	echo "${S}/configure" "${confgcc[@]}"
	bash "${S}/configure" "${confgcc[@]}" || die "configure failed"
}

src_compile() {
	cd "${MY_BUILDDIR}" || die "Failed to change to build directory"
	emake \
		LDFLAGS="${LDFLAGS}" \
		LIBPATH="${LIBPATH}" \
		all-gcc all-target-libgcc
}

src_install() {
	cd "${MY_BUILDDIR}" || die "Failed to change to build directory"
	emake -j1 DESTDIR="${D}" install-gcc install-target-libgcc

	local CTARGET_gcc_PV="${D}${BINPATH}/${CTARGET}-gcc-${PV}"
	if [[ -f "${CTARGET_gcc_PV}" ]]; then
		rm -v "${CTARGET_gcc_PV}" ||
			die "Failed to remove duplicate binary under BINPATH"
		# Use 'ln -s' instead of 'dosym' for link name starting with ${D}
		ln -sv "${PROGRAM_PREFIX}gcc" "${CTARGET_gcc_PV}" ||
			die "Failed to create symbolic link for duplicate binary"
	fi

	# Skip stripping library object files built against CTARGET
	dostrip -x "${LIBPATH}"

	# Only install manual pages in section 1, which are for executable
	# programs installed by this package; manual pages for other sections
	# from this package may collide with files provided by other packages
	find "${D}${MANPATH}" -mindepth 1 -maxdepth 1 -type d -not -name man1 \
		-exec rm -rv {} + || die "Failed to remove colliding manual pages"

	# Allow toolchain-funcs.eclass to find the binaries.  When the binaries are
	# used to build headers and libraries, the binaries' CTARGET becomes the
	# headers' and libraries' CHOST. toolchain-funcs.eclass picks up binaries
	# whose name starts with CHOST, which equals CTARGET in this ebuild.
	local tool_path
	for tool_path in "${D}${BINPATH}/${PROGRAM_PREFIX}"*; do
		local tool_prefixed="${tool_path##*/}"
		local tool="${tool_prefixed#"${PROGRAM_PREFIX}"}"
		dosym "${tool_prefixed}" "${BINPATH#"${EPREFIX}"}/${CTARGET}-${tool}"
	done
}
