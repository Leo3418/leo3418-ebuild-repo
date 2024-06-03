# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="binutils"
MY_P="${MY_PN}-${PV}"

inherit libtool flag-o-matic gnuconfig strip-linguas

DESCRIPTION="GNU binutils targeted at SH3/SH4 processors on CASIO graphing calculators"
HOMEPAGE="
	https://gitea.planet-casio.com/Lephenixnoir/sh-elf-binutils
	https://sourceware.org/binutils/
"
SRC_URI="mirror://gnu/binutils/binutils-${PV}.tar.xz"

S="${WORKDIR}/${MY_P}"
MY_BUILDDIR="${WORKDIR}/build"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"

# binutils' configure script may automagically enable support for installed
# dependencies that it detects if the related configuration option is never
# specified
IUSE="+nls zstd"

BDEPEND="
	sys-devel/flex
	app-alternatives/yacc
	nls? ( sys-devel/gettext )
	zstd? ( virtual/pkgconfig )
"

RDEPEND="
	sys-libs/zlib
	zstd? ( app-arch/zstd:= )
"

DEPEND="
	${RDEPEND}
"

# The fxsdk/cmake/FX{9860G,CG50}.cmake files under the fxSDK source tree
# <https://gitea.planet-casio.com/Lephenixnoir/fxsdk> state that:
#
# # Target triplet: sh-elf (custom sh3eb-elf supporting sh3 and sh4-nofpu)
#
# This suggests that the '--program-prefix' configuration option is set
# probably to fake an 'sh-elf' target to signify it is different from the
# ordinary sh3eb-elf target.  Unfortunately, this can also cause troubles
# when this package is to be installed globally to a system while following
# any file system layout conventions.  The target name used by the toolchain
# in paths to binaries, headers, and libraries will still be the value of
# the '--target' configuration option rather than '--program-prefix'.
#
# A better way to indicate that the toolchain's target may be regarded as a
# custom and specialized one different from the ordinary sh3eb-elf target is
# to utilize the omitted and optional "company" part (a.k.a. the "vendor"
# part) in the configuration name for the target.
CTARGET="sh3eb-fx-elf"
PROGRAM_PREFIX="${PN%"${MY_PN}"}"

src_prepare() {
	default

	# Run misc portage update scripts
	gnuconfig_update
	elibtoolize --portage --no-uclibc
}

src_configure() {
	# See https://www.gnu.org/software/make/manual/html_node/Parallel-Output.html
	# Avoid really confusing logs from subconfigure spam, makes logs far
	# more legible.
	MAKEOPTS="--output-sync=line ${MAKEOPTS}"

	# Setup some paths
	LIBPATH="/usr/$(get_libdir)/binutils/${CTARGET}/${PV}"
	INCPATH="${LIBPATH}/include"
	DATAPATH="/usr/share/binutils-data/${CTARGET}/${PV}"
	BINPATH="/usr/bin"
	MANPATH="/usr/share/man"

	# Make sure we filter $LINGUAS so that only ones that
	# actually work make it through #42033
	strip-linguas -u */po

	# Keep things sane
	strip-flags

	append-ldflags $(test-flags-CCLD -Wl,--undefined-version)

	local x
	echo
	for x in CATEGORY CBUILD CHOST CTARGET CFLAGS LDFLAGS ; do
		einfo "$(printf '%10s' ${x}:) ${!x}"
	done
	echo

	mkdir -p "${MY_BUILDDIR}" || die "Failed to create build directory"
	cd "${MY_BUILDDIR}" || die "Failed to change to build directory"
	local myconf=()

	if use nls ; then
		myconf+=( --without-included-gettext )
	else
		myconf+=( --disable-nls )
	fi

	myconf+=( --with-system-zlib )

	[[ -n "${CBUILD}" ]] && myconf+=( --build="${CBUILD}" )

	myconf+=(
		--with-sysroot="${EPREFIX}/usr/${CTARGET}"
		--enable-poison-system-directories
	)

	myconf+=(
		--prefix="${EPREFIX}/usr"
		--host="${CHOST}"
		--target="${CTARGET}"
		--datadir="${EPREFIX}${DATAPATH}"
		--datarootdir="${EPREFIX}${DATAPATH}"
		--infodir="${EPREFIX}${DATAPATH}/info"
		--mandir="${EPREFIX}${MANPATH}"
		--bindir="${EPREFIX}${BINPATH}"
		--libdir="${EPREFIX}${LIBPATH}"
		--libexecdir="${EPREFIX}${LIBPATH}"
		--includedir="${EPREFIX}${INCPATH}"
		# portage's econf() does not detect presence of --d-d-t
		# because it greps only top-level ./configure. But not
		# libiberty's or bfd's configure.
		--disable-dependency-tracking
		--disable-silent-rules
		--with-pkgversion="${PN}"
		$(use_with zstd)
	)

	# Adapted from https://gitea.planet-casio.com/Lephenixnoir/sh-elf-binutils#method-3-fully-manually
	myconf+=(
		--with-multilib-list=m3,m4-nofpu
		--program-prefix="${PROGRAM_PREFIX}"
		--enable-libssp
		--enable-lto
	)

	ECONF_SOURCE="${S}" econf "${myconf[@]}"
}

src_compile() {
	cd "${MY_BUILDDIR}" || die "Failed to change to build directory"
	# see Note [tooldir hack for ldscripts] in sys-devel/binutils ebuilds
	emake tooldir="${EPREFIX}" all
}

src_install() {
	cd "${MY_BUILDDIR}" || die "Failed to change to build directory"
	# see Note [tooldir hack for ldscripts] in sys-devel/binutils ebuilds
	emake DESTDIR="${D}" tooldir="${EPREFIX}${LIBPATH}" install

	# Clean-ups under LIBPATH that would be done by sys-devel/binutils
	rm -r "${ED}${LIBPATH}/bin" ||
		die "Failed to remove duplicate tools under LIBPATH"
	if [[ -d "${ED}/${LIBPATH}/lib" ]] ; then
		mv "${ED}/${LIBPATH}/lib"/* "${ED}/${LIBPATH}" ||
			die "Failed to move files under \${LIBPATH}/lib"
		rm -r "${ED}/${LIBPATH}/lib" || die "Failed to remove \${LIBPATH}/lib"
	fi

	docompress "${DATAPATH}"/{info,man}

	local BINPATH_LINKS="/usr/libexec/gcc/${CTARGET}"
	local tool_path
	for tool_path in "${ED}${BINPATH}/${PROGRAM_PREFIX}"*; do
		local tool_prefixed="${tool_path##*/}"
		local tool="${tool_prefixed#"${PROGRAM_PREFIX}"}"

		# Allow cross-compiling GCC with the same CTARGET to find the tools
		dosym -r "${BINPATH}/${tool_prefixed}" "${BINPATH_LINKS}/${tool}"

		# Allow toolchain-funcs.eclass to find the tools.  When the tools are
		# used to build headers and libraries, the tools' CTARGET becomes the
		# headers' and libraries' CHOST. toolchain-funcs.eclass picks up tools
		# whose name starts with CHOST, which equals CTARGET in this ebuild.
		dosym "${tool_prefixed}" "${BINPATH}/${CTARGET}-${tool}"
	done
}
