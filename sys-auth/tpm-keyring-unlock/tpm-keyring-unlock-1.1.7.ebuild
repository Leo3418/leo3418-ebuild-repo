# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit edo toolchain-funcs

DESCRIPTION="TPM-sealed auto-unlock for GNOME Keyring"
HOMEPAGE="https://github.com/dmitriitimoshenko/tpm-keyring-unlock"

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/dmitriitimoshenko/tpm-keyring-unlock.git"
else
	KEYWORDS="~amd64"
	SRC_URI="https://github.com/dmitriitimoshenko/tpm-keyring-unlock/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
fi

LICENSE="MIT"
SLOT="0"

DEPEND="
	sys-libs/pam
"

RDEPEND="
	${DEPEND}
	app-crypt/tpm2-tools
"

DOCS=(
	README.md
	JOURNAL.md
)

src_prepare() {
	default
	rm Makefile || die # Useless
	export PKG_LIBDIR="/usr/lib/${PN}"
	export HELPER_PATH="/usr/libexec"
	sed -i -e "s|\\\$(cd \"\\\$(dirname \"\\\${BASH_SOURCE\[0\]}\")\" && pwd)|${PKG_LIBDIR}|" bin/seal.sh ||
		die "Failed to change bin/lib.sh install path"
	sed -i -e "s|/usr/local/sbin|${HELPER_PATH}|" bin/seal.sh ||
		die "Failed to change helper install path"
}

src_compile() {
	export PAM_MODULE="pam_tpm_keyring_authtok"
	local CC="$(tc-getCC)"
	edo "${CC}" -DHELPER_PATH="\"${HELPER_PATH}/tpm-keyring-unseal\"" -fPIC \
		${CPPFLAGS} ${CFLAGS} \
		-c -o "pam/${PAM_MODULE}.o" "pam/${PAM_MODULE}.c"
	edo "${CC}" ${LDFLAGS} -shared \
		-o "pam/${PAM_MODULE}.so" "pam/${PAM_MODULE}.o" -lpam
}

src_install() {
	newbin bin/seal.sh "${PN}-seal"

	insinto "${PKG_LIBDIR}"
	doins bin/lib.sh

	einstalldocs

	insopts -m 0755

	insinto "$(get_libdir)/security"
	doins "pam/${PAM_MODULE}.so"

	insinto "${HELPER_PATH}"
	newins pam/tpm-keyring-unseal.sh tpm-keyring-unseal
}

pkg_postinst() {
	[[ -n ${REPLACING_VERSIONS} ]] && return
	elog "To quickly get started with this module:"
	elog "1. In each file in /etc/pam.d/, if it contains this line:"
	elog "     auth optional pam_gnome_keyring.so"
	elog "   Then add the following line above it:"
	elog "     auth optional ${PAM_MODULE}.so"
	elog "2. Add users whose keyring is to be unlocked to 'tss' group:"
	elog "     usermod --append --groups tss \${USER}"
	elog "3. Run this command to seal the keyring password in the TPM:"
	elog "     ${PN}-seal"
}
