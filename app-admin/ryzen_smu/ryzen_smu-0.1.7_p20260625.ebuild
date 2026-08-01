# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit linux-mod-r1

if [[ ${PV} == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/amkillam/ryzen_smu.git"
else
	# Live ebuild: Might be intentionally left blank
	# Normal ebuild: Fill in commit SHA-1 object name to this variable's value
	GIT_COMMIT="1be4fb1cd9d60b5ddefc2a4201a898766a731400"
	[[ -n "${GIT_COMMIT}" ]] ||
		die "GIT_COMMIT is not defined for snapshot ebuild"

	KEYWORDS="~amd64 ~x86"
	SRC_URI="https://github.com/amkillam/ryzen_smu/archive/${GIT_COMMIT}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${PN}-${GIT_COMMIT}"
fi

DESCRIPTION="Active fork of kernel driver for AMD Ryzen's System Management Unit"
HOMEPAGE="https://github.com/amkillam/ryzen_smu"

LICENSE="GPL-2"
SLOT="0"

src_compile() {
	local modlist=( ryzen_smu )
	local modargs=( KERNEL_BUILD="${KV_OUT_DIR}" )

	linux-mod-r1_src_compile
}

src_install() {
	linux-mod-r1_src_install

	insinto /usr/lib/modules-load.d
	newins - ryzen_smu.conf <<- _EOF_
	ryzen_smu
	_EOF_
}
