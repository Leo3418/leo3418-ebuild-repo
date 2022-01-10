# Copyright 2021-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module

DESCRIPTION="Name resolution for containers"
HOMEPAGE="https://github.com/containers/dnsname"
SRC_URI="https://github.com/containers/dnsname/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0 BSD BSD-2 MIT"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test"

RDEPEND="
	net-dns/dnsmasq
"

S="${WORKDIR}/dnsname-${PV}"

src_install() {
	emake DESTDIR="${D}" PREFIX="${EPREFIX}/usr" install
	einstalldocs
}
