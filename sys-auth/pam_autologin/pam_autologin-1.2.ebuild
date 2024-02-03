# Copyright 2023-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="PAM module for automatic login"
HOMEPAGE="https://sourceforge.net/projects/pam-autologin/"
SRC_URI="mirror://sourceforge/pam-autologin/pam_autologin-${PV}.tar.gz"

LICENSE="ISC"
SLOT="0"
KEYWORDS="~amd64"

BDEPEND="
	virtual/pkgconfig
"

RDEPEND="
	sys-libs/pam
"

DEPEND="
	${RDEPEND}
"

src_prepare() {
	default
	sed -i -e "s|^progs=\".*\"$|progs='CC=$(tc-getCC) INSTALL=install'|" \
		configure || die "Failed to set CC in ./configure"
	sed -i -e "s|^pkgconfig=.*$|pkgconfig='$(tc-getPKG_CONFIG)'|" \
		configure || die "Failed to set PKG_CONFIG in ./configure"
	sed -i -e 's/s\/@$pname@\/$pcall\//s|@$pname@|$pcall|/' \
		configure || die "Failed to let ./configure handle path delimiters"
	sed -i -e '/^[[:space:]]*ldflags[[:space:]]*:= -s$/d' Config.mk.in ||
		die "Failed to disable pre-stripping in Config.mk.in"
	sed -i -e 's/^[[:space:]]*@/\t/' Makefile ||
		die "Failed to let Makefile echo recipe lines"
}

MY_CONFFILE="etc/security/autologin.conf"

print_clean_command() {
	elog "  shred -u ${EPREFIX}/${MY_CONFFILE}"
}

pkg_postinst() {
	[[ -n ${REPLACING_VERSIONS} ]] && return
	elog "To quickly get started with this module:"
	elog "1. At the top of file ${EPREFIX}/etc/pam.d/system-local-login," \
		"add this line:"
	elog "     auth optional pam_autologin.so"
	elog "2. Run this command:"
	elog "     install -m 600 /dev/null ${EPREFIX}/${MY_CONFFILE}"
	elog "The changes will take effect upon the next login."
	elog
	elog "To disable autologin, run this command, which also"
	elog "completely erases passwords saved by this module:"
	print_clean_command
	elog "To re-enable autologin later, rerun the command in step 2 above."
	elog
	elog "For more information, please consult:"
	elog "- Manual page pam_autologin(8)"
	elog "- ${EPREFIX}/usr/share/doc/${PF}/README.md*"
}

pkg_postrm() {
	[[ -n ${REPLACED_BY_VERSION} ]] && return
	elog "To completely erase passwords saved by this module, run command:"
	print_clean_command
}
