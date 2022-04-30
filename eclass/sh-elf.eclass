# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

# @ECLASS: sh-elf.eclass
# @MAINTAINER:
# Yuan Liao <liaoyuan@gmail.com>
# @AUTHOR:
# Yuan Liao <liaoyuan@gmail.com>
# @SUPPORTED_EAPIS: 8
# @BLURB: An eclass for integration with the sh-elf toolchain
# @DESCRIPTION:
# This eclass allows any ebuilds that install headers and libraries for the
# SH3/SH4 processors on CASIO graphing calculators to build them using the
# cross-compiling sh-elf toolchain, which is targeted at the same processors.
# Technically speaking, when the intended CHOST of a package is the CTARGET of
# the sh-elf toolchain, this eclass should be inherited.

if [[ ! "${_SH_ELF_ECLASS}" ]]; then

case ${EAPI:-0} in
	8) ;;
	*) die "${ECLASS}: EAPI ${EAPI} unsupported."
esac

inherit flag-o-matic

EXPORT_FUNCTIONS pkg_setup

BDEPEND="
	dev-embedded/sh-elf-gcc
"

# @FUNCTION: sh-elf_pkg_setup
# @DESCRIPTION:
# Sets up environment variables so the package build process can use the sh-elf
# toolchain.
sh-elf_pkg_setup() {
	[[ "${MERGE_TYPE}" == binary ]] && return

	CHOST="$(sh-elf-gcc -dumpmachine)"
	[[ -n "${CHOST}" ]] || die "Failed to get the value of CHOST"
	einfo "CHOST: ${CHOST}"

	# Ideally, there should be a straightforward mechanism that allows
	# users to set different toolchain flags for cross-compiling, just
	# like how sys-devel/crossdev would work.  Users can still do this
	# using /etc/portage/env and /etc/portage/package.env, but if they
	# do not customize the flags, then the default flags set on CBUILD
	# will be used, and these flags may contain flags not supported by
	# the toolchains targeting at CHOST (such as '-march').
	strip-unsupported-flags
}

_SH_ELF_ECLASS=1
fi
