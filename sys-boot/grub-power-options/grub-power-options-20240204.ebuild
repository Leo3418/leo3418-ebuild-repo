# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="GRUB Boot Menu Entries for System Power Options"
HOMEPAGE="https://wiki.gentoo.org/wiki/No_homepage"

# Package content taken from https://wiki.archlinux.org/title/GRUB
LICENSE="FDL-1.3+"
SLOT="0"
KEYWORDS="~amd64"

S="${WORKDIR}"

src_install() {
	local grub_d="/etc/grub.d"
	insinto "${grub_d}"
	insopts -m 0755

	newins - 31_power <<- _EOF_
	#!/bin/sh
	set -e

	. "\${pkgdatadir}/grub-mkconfig_lib"

	gettext_printf "Adding boot menu entries for system power options ...\n" >&2

	cat << EOF
	menuentry "System shutdown" {
	  echo "System shutting down ..."
	  halt
	}

	menuentry "System restart" {
	  echo "System restarting ..."
	  reboot
	}
	EOF
	_EOF_
}
