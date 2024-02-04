# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="sudoers Files for Sudo"
HOMEPAGE="https://wiki.gentoo.org/wiki/No_homepage"

# Package content taken from https://wiki.archlinux.org/title/Sudo
LICENSE="FDL-1.3+"
SLOT="0"
KEYWORDS="~amd64"

S="${WORKDIR}"

src_install() {
	local sudoers_d="/etc/sudoers.d"
	insinto "${sudoers_d}"
	fperms 0750 "${sudoers_d}"
	insopts -m 0440

	newins - 00-wheel <<- _EOF_
	%wheel ALL=(ALL:ALL) ALL
	_EOF_
}
