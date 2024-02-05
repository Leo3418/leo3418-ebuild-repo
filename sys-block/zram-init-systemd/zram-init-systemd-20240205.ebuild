# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="systemd Units for Better zram-init Integration"
HOMEPAGE="https://wiki.gentoo.org/wiki/No_homepage"

# Package content taken from zram-init
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	sys-block/zram-init
"

S="${WORKDIR}"

src_install() {
	local unit="zram-swap@.service"

	# Swap size follows Fedora's configuration for zram-generator:
	# https://src.fedoraproject.org/rpms/rust-zram-generator/blob/f39/f/zram-generator.conf
	systemd_newunit - "${unit}" <<- _EOF_
	[Unit]
	Description=Swap on zram Device %i (/dev/zram%i)
	DefaultDependencies=no
	After=dev-zram%i.device
	Before=swap.target

	[Service]
	Type=oneshot
	RemainAfterExit=yes
	ExecStart=/bin/sh -c "exec /sbin/zram-init -d %i -L zram-swap \$(m=\$(LC_ALL=C free -m | awk '/^Mem:/{print int(\$2 / 1)}'); [ \$m -gt 8192 ] && m=8192; echo \$m)"
	ExecStop=/sbin/zram-init -d %i 0

	[Install]
	WantedBy=swap.target
	_EOF_

	insinto "$(systemd_get_systempresetdir)"
	newins - 70-zram-swap.preset <<- _EOF_
	enable ${unit} 0
	_EOF_
}
