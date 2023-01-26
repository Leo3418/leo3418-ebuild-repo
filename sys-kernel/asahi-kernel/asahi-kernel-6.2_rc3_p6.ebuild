# Copyright 2020-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit kernel-build savedconfig toolchain-funcs

# https://github.com/AsahiLinux/PKGBUILDs/blob/main/linux-asahi/config
PKGBUILD_CONFIG_COMMIT="fa0fbb251bbe98a2d7977b2854b07685b0acd18c"
PKGBUILD_CONFIG_VER="6.2.0-rc2"
PKGBUILD_CONFIG_FILE_NAME="linux-asahi.config.${PKGBUILD_CONFIG_VER}"
# https://github.com/AsahiLinux/PKGBUILDs/blob/main/linux-asahi/config.edge
PKGBUILD_EDGE_CONFIG_FILE_NAME="${PKGBUILD_CONFIG_FILE_NAME}-edge"

GENTOO_CONFIG_VER="g5"

# Tag 'asahi-w.x-z'     = PV="w.x_pz"
# Tag 'asahi-w.x-rcN-z' = PV="w.x_rcN_pz"
MY_PV="${PV/_rc/-rc}"
MY_PV="${MY_PV/_p/-}"

HOMEPAGE="https://asahilinux.org/"
SRC_URI="
	https://github.com/AsahiLinux/linux/archive/refs/tags/asahi-${MY_PV}.tar.gz
	https://raw.githubusercontent.com/AsahiLinux/PKGBUILDs/${PKGBUILD_CONFIG_COMMIT}/linux-asahi/config
		-> ${PKGBUILD_CONFIG_FILE_NAME}
	https://github.com/projg2/gentoo-kernel-config/archive/${GENTOO_CONFIG_VER}.tar.gz
		-> gentoo-kernel-config-${GENTOO_CONFIG_VER}.tar.gz
"
S="${WORKDIR}/linux-asahi-${MY_PV}"

if [[ ${PN} == asahi-edge-kernel ]]; then
	DESCRIPTION="Asahi Linux testing kernel for Apple silicon-based Macs built from sources"
	SRC_URI+="
		https://raw.githubusercontent.com/AsahiLinux/PKGBUILDs/${PKGBUILD_CONFIG_COMMIT}/linux-asahi/config.edge
			-> ${PKGBUILD_EDGE_CONFIG_FILE_NAME}
	"
else
	DESCRIPTION="Asahi Linux kernel for Apple silicon-based Macs built from sources"
fi

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

	local myversion=""
	[[ ${PN} == asahi-edge-kernel ]] && myversion+="-edge"
	myversion+="-dist"
	local ver_conf_path="${T}/version.config"
	echo "CONFIG_LOCALVERSION=\"${myversion}\"" > "${ver_conf_path}" ||
		die "Failed to write local version config"

	local merge_configs=()
	if [[ ${PN} == asahi-edge-kernel ]]; then
		local edge_conf_path="${DISTDIR}/${PKGBUILD_EDGE_CONFIG_FILE_NAME}"
		merge_configs+=( "${edge_conf_path}" )
	fi
	merge_configs+=( "${ver_conf_path}" )

	local dist_conf_path="${WORKDIR}/gentoo-kernel-config-${GENTOO_CONFIG_VER}"
	use !debug && merge_configs+=( "${dist_conf_path}/no-debug.config" )

	kernel-build_merge_configs "${merge_configs[@]}"
}

src_install() {
	# Override DTBs installation path for sys-apps/asahi-scripts::asahi
	export INSTALL_DTBS_PATH="${ED}/usr/src/linux-${PV}${KV_LOCALVERSION}/arch/$(tc-arch-kernel)/boot/dts"
	kernel-build_src_install
}

pkg_postinst() {
	asahi-kernel_pkg_postinst
	savedconfig_pkg_postinst
}

# Override kernel-install_pkg_postinst to call asahi-kernel_update_symlink for
# updating the kernel source symlink
asahi-kernel_pkg_postinst() {
	local dir_ver=${PV}${KV_LOCALVERSION}
	asahi-kernel_update_symlink "${EROOT}/usr/src/linux" "${dir_ver}"

	if [[ -z ${ROOT} ]]; then
		kernel-install_install_all "${dir_ver}"
	fi
}

# Override kernel-install_update_symlink to use asahi-kernel_can_update_symlink
# for testing if the kernel source symlink should be updated
asahi-kernel_update_symlink() {
	[[ ${#} -eq 2 ]] || die "${FUNCNAME}: invalid arguments"
	local target=${1}
	local version=${2}

	if asahi-kernel_can_update_symlink "${target}"; then
		ebegin "Updating ${target} symlink"
		ln -f -n -s "${target##*/}-${version}" "${target}"
		eend ${?}
	else
		elog "${target} points at another kernel, leaving it as-is."
		elog "Please use 'eselect kernel' to update it when desired."
	fi
}

# Override kernel-install_can_update_symlink
# to recognize '_rc' and '_p' in ${symlink_ver}
asahi-kernel_can_update_symlink() {
	[[ ${#} -eq 1 ]] || die "${FUNCNAME}: invalid arguments"
	local target=${1}

	# if the symlink does not exist or is broken, update
	[[ ! -e ${target} ]] && return 0
	# if the target does not seem to contain kernel sources
	# (i.e. is probably a leftover directory), update
	[[ ! -e ${target}/Makefile ]] && return 0

	local symlink_target=$(readlink "${target}")
	# the symlink target should start with the same basename as target
	# (e.g. "linux-*")
	[[ ${symlink_target} != ${target##*/}-* ]] && return 1

	# try to establish the kernel version from symlink target
	local symlink_ver=${symlink_target#${target##*/}-}
	# strip KV_LOCALVERSION, we want to update the old kernels not using
	# KV_LOCALVERSION suffix and the new kernels using it
	symlink_ver=${symlink_ver%${KV_LOCALVERSION}}

	# if ${symlink_ver} contains anything but numbers and expected
	# suffixes ('_rc', '_p'), it's not our kernel, so leave it alone
	local symlink_ver_copy=${symlink_ver}
	symlink_ver_copy=${symlink_ver_copy/_rc/}
	symlink_ver_copy=${symlink_ver_copy/_p/}
	[[ -n ${symlink_ver_copy//[0-9.]/} ]] && return 1

	local symlink_pkg=${CATEGORY}/${PN}-${symlink_ver}
	# if the current target is either being replaced, or still
	# installed (probably depclean candidate), update the symlink
	has "${symlink_ver}" ${REPLACING_VERSIONS} && return 0
	has_version -r "~${symlink_pkg}" && return 0

	# otherwise it could be another kernel package, so leave it alone
	return 1
}
