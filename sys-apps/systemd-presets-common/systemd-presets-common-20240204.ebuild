# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="Common systemd Preset Files for All Systems"
HOMEPAGE="https://wiki.gentoo.org/wiki/No_homepage"

# Package content taken from https://src.fedoraproject.org/rpms/fedora-release
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

S="${WORKDIR}"

src_install() {
	local system_preset_dir="$(systemd_get_systempresetdir)"
	local user_preset_dir="$(systemd_get_utildir)/user-preset"

	insinto "${system_preset_dir}"
	newins - 90-common.preset <<- _EOF_
	# net-firewall/firewalld
	enable firewalld.service

	# net-misc/openssh
	enable sshd.socket

	# sys-apps/util-linux
	enable fstrim.timer

	# sys-process/systemd-cron
	enable cron.target
	_EOF_

	insinto "${user_preset_dir}"
	newins - 99-default.preset <<- _EOF_
	disable *
	_EOF_
}
