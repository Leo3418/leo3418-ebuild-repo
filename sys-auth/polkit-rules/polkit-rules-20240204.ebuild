# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="polkit Authorization Rules"
HOMEPAGE="https://wiki.gentoo.org/wiki/No_homepage"

# Package content taken from polkit
LICENSE="LGPL-2"
SLOT="0"
KEYWORDS="~amd64"

S="${WORKDIR}"

src_install() {
	local rules_d="/usr/share/polkit-1/rules.d"
	insinto "${rules_d}"

	# sys-auth/polkit::gentoo replaces upstream's 'unix-group:wheel'
	# with 'unix-user:0' for an old security bug, but other distributions
	# (e.g. Arch Linux, Fedora) do not do the same
	newins - 49-wheel.rules <<- _EOF_
	polkit.addAdminRule(function(action, subject) {
	    return ["unix-group:wheel"];
	});
	_EOF_
}
