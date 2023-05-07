# Copyright 2022-2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..11} )
DISTUTILS_USE_PEP517="setuptools"

inherit distutils-r1 optfeature

if [[ ${PV} == "9999" ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/Leo3418/ebuild-commander.git"
else
	SRC_URI="https://github.com/Leo3418/ebuild-commander/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
fi

DESCRIPTION="Test ebuilds with fine-grained control in stage3 Docker containers"
HOMEPAGE="https://github.com/Leo3418/ebuild-commander"

LICENSE="GPL-3+"
SLOT="0"

distutils_enable_tests unittest

pkg_postinst() {
	# Display a note about container engine upon first installation of package
	[[ -z "${REPLACING_VERSIONS}" ]] || return
	if has_version app-containers/podman; then
		elog "To use Podman with this tool, please set the"
		elog "following environment variable and value:"
		elog "  EBUILD_CMDER_DOCKER=podman"
	elif ! has_version app-containers/docker; then
		optfeature_header \
			"Please install a container engine compatible with this tool:"
		optfeature "Docker" app-containers/docker
		optfeature "Podman" app-containers/podman
		elog
		elog "To use a container engine that is not Docker, please"
		elog "set the environment variable and value for it:"
		elog "  Podman:	EBUILD_CMDER_DOCKER=podman"
	fi
}
