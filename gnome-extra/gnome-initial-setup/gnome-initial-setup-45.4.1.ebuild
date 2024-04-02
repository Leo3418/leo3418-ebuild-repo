# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit gnome.org meson

DESCRIPTION="Initial setup wizard for GNOME desktop"
HOMEPAGE="https://gitlab.gnome.org/GNOME/gnome-initial-setup"

LICENSE="GPL-2+"
SLOT="0"
# Try to follow the default of gnome-base/gnome-{control-center,shell}::gentoo
IUSE="+ibus systemd"
KEYWORDS="~amd64"

BDEPEND="
	dev-libs/glib:2
	gnome-base/dconf
	sys-devel/gettext
	virtual/pkgconfig
"

COMMON_DEPEND="
	app-crypt/libsecret
	app-crypt/mit-krb5
	app-misc/geoclue:2.0
	dev-libs/glib:2
	dev-libs/json-glib
	dev-libs/libgweather:4=
	dev-libs/libpwquality
	gnome-base/gdm
	gnome-base/gnome-desktop:4=
	gui-libs/gtk:4
	>=gui-libs/libadwaita-1.2_alpha:1
	media-libs/fontconfig
	net-libs/gnome-online-accounts:=
	net-libs/libnma
	net-libs/rest:1.0
	net-misc/networkmanager
	sci-geosciences/geocode-glib:2
	sys-apps/accountsservice
	sys-auth/polkit
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/pango
	net-libs/webkit-gtk:6
	ibus? ( >=app-i18n/ibus-1.4.99 )
	systemd? ( >=sys-apps/systemd-242 )
"

DEPEND="
	${COMMON_DEPEND}
"

RDEPEND="
	${COMMON_DEPEND}
	acct-group/gnome-initial-setup
	acct-user/gnome-initial-setup
"

src_configure() {
	local emesonargs=(
		$(meson_feature ibus)
		$(meson_use systemd)
		# malcontent, which is required for parental controls,
		# is not packaged for Gentoo yet
		-Dparental_controls=disabled
	)
	meson_src_configure
}

src_install() {
	meson_src_install
	if use systemd; then
		# acct-user/gnome-initial-setup already creates a sysusers.d file
		rm "${ED}/usr/lib/sysusers.d/gnome-initial-setup.conf" ||
			die "Failed to remove redundant sysusers.d file"
	fi
}

pkg_postinst() {
	[[ -n ${REPLACING_VERSIONS} ]] && return
	elog "To allow GDM to successfully launch GNOME Initial Setup,"
	elog "an edit equivalent to the command below is needed:"
	elog "  sed -i 's/user = gdm/user in gdm:gnome-initial-setup/'" \
		"${EROOT}/etc/pam.d/gdm-launch-environment"
}
