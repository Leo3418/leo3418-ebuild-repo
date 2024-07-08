# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

MY_PN="gcc"
MY_P="${MY_PN}-${PV}"

inherit edo flag-o-matic gnuconfig libtool

DESCRIPTION="Cross-compiling GCC targeted at SH3/SH4 processors on CASIO graphing calculators"
HOMEPAGE="
	https://git.planet-casio.com/Lephenixnoir/sh-elf-gcc
	https://gcc.gnu.org/
"
SRC_URI="mirror://gnu/gcc/gcc-${PV}/gcc-${PV}.tar.xz"

S="${WORKDIR}/${MY_P}"
MY_BUILDDIR="${WORKDIR}/build"

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
IUSE="custom-cflags cxx graphite +nls valgrind +zstd"

BDEPEND="
	app-alternatives/yacc
	dev-embedded/sh-elf-binutils
	>=sys-devel/flex-2.5.4
	nls? ( sys-devel/gettext )
	valgrind? ( dev-debug/valgrind )
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
	cxx? ( dev-embedded/fxlibc )
"

# Use the same CTARGET as dev-embedded/sh-elf-binutils
CTARGET="sh3eb-fx-elf"
PROGRAM_PREFIX="${PN%"${MY_PN}"}"

PATCHES=(
	"${FILESDIR}/gcc-13.1.0-fix-CROSS_SYSTEM_HEADER_DIR.patch"
)

pkg_setup() {
	# We don't want to use the installed compiler's specs to build gcc
	unset GCC_SPECS

	# bug #265283
	unset LANGUAGES

	# See https://www.gnu.org/software/make/manual/html_node/Parallel-Output.html
	# Avoid really confusing logs from subconfigure spam, makes logs far
	# more legible.
	MAKEOPTS="--output-sync=line ${MAKEOPTS}"
}

src_prepare() {
	default

	# Fixup libtool to correctly generate .la files with portage
	elibtoolize --portage --shallow --no-uclibc

	gnuconfig_update
}

src_configure() {
	PREFIX="${EPREFIX}/usr"
	LIBPATH="${PREFIX}/lib/gcc/${CTARGET}/$(ver_cut 1)"
	INCLUDEPATH="${LIBPATH}/include"
	BINPATH="${PREFIX}/bin"
	DATAPATH="${PREFIX}/share/gcc-data/${CTARGET}/$(ver_cut 1)"
	STDCXX_INCDIR="${LIBPATH}/include/g++-v$(ver_cut 1)"
	MANPATH="${PREFIX}/share/man"

	BUILD_CONFIG_TARGETS=()
	is-flagq '-O3' && BUILD_CONFIG_TARGETS+=( bootstrap-O3 )

	if ! use custom-cflags; then
		# Over-zealous CFLAGS can often cause problems.  What may work for one
		# person may not work for another.  To avoid a large influx of bugs
		# relating to failed builds, we strip most CFLAGS out to ensure as few
		# problems as possible.
		strip-flags

		# Lock gcc at -O2; we want to be conservative here.
		filter-flags '-O?'

		# We allow -O3 given it's a supported option upstream.
		# Only add -O2 if we're not doing -O3.
		if [[ ${BUILD_CONFIG_TARGETS[@]} == *bootstrap-O3* ]] ; then
			append-flags '-O3'
		else
			append-flags '-O2'
		fi
	fi

	einfo "CFLAGS=\"${CFLAGS}\""
	einfo "CXXFLAGS=\"${CXXFLAGS}\""
	einfo "LDFLAGS=\"${LDFLAGS}\""

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

		# portage's econf() does not detect presence of --d-s-r
		# because it greps only top-level ./configure. But not
		# libiberty's or gcc's configure.
		--disable-silent-rules
		--disable-dependency-tracking

		--with-python-dir="${DATAPATH/"${PREFIX}"/}/python"
		--with-pkgversion="${PN}"
		--with-gcc-major-version-only
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

	# The default project created by fxSDK unconditionally searches
	# for sh-elf-g++ even if the project contains no C++ source files,
	# so always enable C++ for better user experience
	local GCC_LANG="c,c++"

	# Adapted from https://git.planet-casio.com/Lephenixnoir/sh-elf-gcc/src/branch/master/configure.sh
	confgcc+=(
		--with-multilib-list=m3,m4-nofpu
		--enable-languages="${GCC_LANG}"
		--without-headers
		--program-prefix="${PROGRAM_PREFIX}"
		--enable-libssp
		--enable-lto
		--enable-clocale=generic
		--enable-libstdcxx-allocator
		--disable-threads
		--disable-libstdcxx-verbose
		--enable-cxx-flags="-fno-exceptions"
	)

	eval "local -a EXTRA_ECONF=(${EXTRA_ECONF})"
	confgcc+=( "$@" "${EXTRA_ECONF[@]}" )

	echo
	einfo "PREFIX:          ${PREFIX}"
	einfo "BINPATH:         ${BINPATH}"
	einfo "LIBPATH:         ${LIBPATH}"
	einfo "DATAPATH:        ${DATAPATH}"
	einfo "STDCXX_INCDIR:   ${STDCXX_INCDIR}"
	einfo "Languages:       ${GCC_LANG}"
	echo

	mkdir -p "${MY_BUILDDIR}" || die "Failed to create build directory"
	cd "${MY_BUILDDIR}" || die "Failed to change to build directory"
	addwrite /dev/zero
	local gcc_shell="${BROOT}/bin/sh"
	CONFIG_SHELL="${gcc_shell}" \
		edo "${gcc_shell}" "${S}/configure" "${confgcc[@]}"
}

src_compile() {
	cd "${MY_BUILDDIR}" || die "Failed to change to build directory"
	local gcc_shell="${BROOT}/bin/sh"

	local emakeargs=(
		LDFLAGS="${LDFLAGS}"
		LIBPATH="${LIBPATH}"
	)

	CONFIG_SHELL="${gcc_shell}" emake "${emakeargs[@]}" \
		all-gcc all-target-libgcc \
		$(usev cxx all-target-libstdc++-v3)
}

src_install() {
	cd "${MY_BUILDDIR}" || die "Failed to change to build directory"
	emake DESTDIR="${D}" install-gcc install-target-libgcc \
		$(usev cxx install-target-libstdc++-v3)

	local CTARGET_gcc_PV="${D}${BINPATH}/${CTARGET}-gcc-${PV}"
	if [[ -f "${CTARGET_gcc_PV}" ]]; then
		rm -v "${CTARGET_gcc_PV}" ||
			die "Failed to remove duplicate binary under BINPATH"
		# Use 'ln -s' instead of 'dosym' for link name starting with ${D}
		ln -sv "${PROGRAM_PREFIX}gcc" "${CTARGET_gcc_PV}" ||
			die "Failed to create symbolic link for duplicate binary"
	fi

	# Move the libraries to the proper location
	gcc_movelibs

	# Skip stripping library object files built against CTARGET
	dostrip -x "${LIBPATH}"

	# Only install manual pages in section 1, which are for executable
	# programs installed by this package; manual pages for other sections
	# from this package may collide with files provided by other packages
	find "${D}${MANPATH}" -mindepth 1 -maxdepth 1 -type d -not -name man1 \
		-exec rm -rv {} + || die "Failed to remove colliding manual pages"

	# Remove redundant libtool archives
	find "${D}${LIBPATH}" -type f \
		\( -name libstdc++.la -o -name libsupc++.la \) \
		-exec rm -rv {} + || die "Failed to remove redundant libtool archives"

	# Prune empty dirs left behind. It's fine not to die here as we may
	# really have no empty dirs left.
	find "${ED}" -depth -type d -delete 2> /dev/null

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

pkg_postinst() {
	if ! use cxx; then
		elog "To build libstdc++, please enable the 'cxx' USE flag"
		elog "and then rebuild this package."
	fi
}

# Grab a variable from the build system (taken from toolchain.eclass,
# which in turn took it from linux-info.eclass)
get_make_var() {
	local var="$1" makefile="${2:-"${MY_BUILDDIR}/Makefile"}"
	echo -e "e:\\n\\t@echo \$(${var})\\ninclude ${makefile}" | \
		r="${makefile%/*}" emake --no-print-directory -s -f - 2>/dev/null
}

gcc_movelibs() {
	local XGCC="$(get_make_var GCC_FOR_TARGET)"
	local multiarg
	for multiarg in $(${XGCC} -print-multi-lib) ; do
		multiarg="${multiarg#*;}"
		multiarg="${multiarg//@/ -}"

		local OS_MULTIDIR="$(${XGCC} ${multiarg} --print-multi-os-directory)"
		local MULTIDIR="$(${XGCC} ${multiarg} --print-multi-directory)"
		local TODIR="${D}${LIBPATH}/${MULTIDIR}"
		local FROMDIR=

		[[ -d "${TODIR}" ]] || mkdir -p "${TODIR}" ||
			die "Failed to create internal library directory"

		for FROMDIR in \
			"${LIBPATH}/${OS_MULTIDIR}" \
			"${LIBPATH}/../${MULTIDIR}" \
			"${PREFIX}/${CTARGET}/lib/${OS_MULTIDIR}"
		do
			FROMDIR="${D}${FROMDIR}"
			if [[ "${FROMDIR}" != "${TODIR}" && -d "${FROMDIR}" ]] ; then
				local files=$(find "${FROMDIR}" -maxdepth 1 ! -type d 2> /dev/null || die)
				if [[ -n ${files} ]] ; then
					mv -v ${files} "${TODIR}" ||
						die "Failed to move file to internal library directory"
				fi
			fi
		done
	done
}
