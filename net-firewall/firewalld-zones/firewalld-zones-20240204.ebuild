# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Extra firewalld Zones"
HOMEPAGE="https://wiki.gentoo.org/wiki/No_homepage"

# Package content taken from https://src.fedoraproject.org/rpms/firewalld
LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="amd64"

S="${WORKDIR}"

src_install() {
	local zones_dir="/usr/lib/firewalld/zones"
	insinto "${zones_dir}"

	newins - workstation.xml <<- _EOF_
	<?xml version="1.0" encoding="utf-8"?>
	<zone>
	  <short>Workstation</short>
	  <description>Default zone on Fedora Workstation. Unsolicited incoming network packets are rejected from port 1 to 1024, except for select network services. Incoming packets that are related to outgoing network connections are accepted. Outgoing network connections are allowed.</description>
	  <service name="dhcpv6-client"/>
	  <service name="ssh"/>
	  <service name="samba-client"/>
	  <port protocol="udp" port="1025-65535"/>
	  <port protocol="tcp" port="1025-65535"/>
	</zone>
	_EOF_
}
