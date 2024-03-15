# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Source VTE's initialization script in non-login shells"
HOMEPAGE="https://wiki.gentoo.org/wiki/No_homepage"

S="${WORKDIR}"

LICENSE="CC0-1.0"
SLOT="0"
KEYWORDS="amd64"

src_install() {
	insinto /etc/bash/bashrc.d
	newins - vte.sh <<- _EOF_
	# shellcheck shell=sh disable=SC1090

	# If multiple scripts exist, try to choose the one from the latest version
	for sh in /etc/profile.d/vte*.sh ; do
	    [ -r "\${sh}" ] && sh_to_source="\${sh}"
	done
	. "\${sh_to_source}"
	unset sh sh_to_source
	_EOF_
}
