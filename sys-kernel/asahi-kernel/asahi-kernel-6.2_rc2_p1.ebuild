# Copyright 2020-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit kernel-build

# https://github.com/AsahiLinux/PKGBUILDs/blob/main/linux-asahi/config
PKGBUILD_CONFIG_COMMIT="da67cf02622899775c233f52e441fc8127f51d99"
PKGBUILD_CONFIG_VER="6.1.0-rc7"
PKGBUILD_CONFIG_FILE_NAME="linux-asahi.config.${PKGBUILD_CONFIG_VER}"

GENTOO_CONFIG_VER="g4"

# Tag 'asahi-w.x-z'     = PV="w.x_pz"
# Tag 'asahi-w.x-rcN-z' = PV="w.x_rcN_pz"
MY_PV="${PV/_rc/-rc}"
MY_PV="${MY_PV/_p/-}"

DESCRIPTION="Asahi Linux kernel for Apple silicon-based Macs built from sources"
HOMEPAGE="https://asahilinux.org/"
SRC_URI="
	https://github.com/AsahiLinux/linux/archive/refs/tags/asahi-${MY_PV}.tar.gz
	https://raw.githubusercontent.com/AsahiLinux/PKGBUILDs/${PKGBUILD_CONFIG_COMMIT}/linux-asahi/config
		-> ${PKGBUILD_CONFIG_FILE_NAME}
	https://github.com/projg2/gentoo-kernel-config/archive/${GENTOO_CONFIG_VER}.tar.gz
		-> gentoo-kernel-config-${GENTOO_CONFIG_VER}.tar.gz
"
S="${WORKDIR}/linux-asahi-${MY_PV}"

LICENSE="GPL-2"
KEYWORDS="~arm64"
# The 'debug' USE flag is required by kernel-build_src_install
IUSE="debug"

BDEPEND="
	debug? ( dev-util/pahole )
"

PDEPEND="
	>=virtual/dist-kernel-${PV}
"

src_prepare() {
	default

	cp "${DISTDIR}/${PKGBUILD_CONFIG_FILE_NAME}" .config ||
		die "Failed to copy kernel configuration"

	# Avoid "Kernel release mismatch" error from kernel-install_pkg_preinst
	# by adding required version components to a localversion* file, so users
	# can still set their own CONFIG_LOCALVERSION value in savedconfig or
	# /etc/kernel/config.d/*.config without getting the same error again
	if [[ ${PV} == *_p* ]]; then
		local localversion=""
		if [[ ${PV} == *_rc* ]]; then
			localversion+="_"
		else
			localversion+="-"
		fi
		localversion+="p${PV##*_p}"
		echo "${localversion}" > localversion.00-gentoo ||
			die "Failed to write local version preset"
	fi

	local myversion="-dist"
	local ver_conf_path="${T}/version.config"
	echo "CONFIG_LOCALVERSION=\"${myversion}\"" > "${ver_conf_path}" ||
		die "Failed to write local version config"

	local merge_configs=(
		"${ver_conf_path}"
	)

	local dist_conf_path="${WORKDIR}/gentoo-kernel-config-${GENTOO_CONFIG_VER}"
	use !debug && merge_configs+=( "${dist_conf_path}/no-debug.config" )

	kernel-build_merge_configs "${merge_configs[@]}"
}
