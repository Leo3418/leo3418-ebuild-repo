# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit gnome2-utils meson xdg

if [[ ${PV} == "9999" ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/mjakeman/extension-manager.git"
else
	SRC_URI="https://github.com/mjakeman/extension-manager/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
fi

DESCRIPTION="An extension manager for browsing and installing GNOME Shell Extensions"
HOMEPAGE="https://github.com/mjakeman/extension-manager"

LICENSE="GPL-3+"
SLOT="0"

# 'Validate appstream file' test case requires Internet connection
PROPERTIES="test_network"
RESTRICT="test"

BDEPEND="
	dev-util/blueprint-compiler
	virtual/pkgconfig
"

DEPEND="
	dev-libs/json-glib
	gui-libs/gtk:4
	gui-libs/libadwaita:1
	net-libs/libsoup:3.0
"

RDEPEND="
	${DEPEND}
	dev-libs/glib:2
"

pkg_postinst() {
	xdg_pkg_postinst
	gnome2_schemas_update
}

pkg_postrm() {
	xdg_pkg_postrm
	gnome2_schemas_update
}
