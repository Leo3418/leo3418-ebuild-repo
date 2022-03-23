# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..10} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/Leo3418/zarro-boogs-tools.git"
else
	SRC_URI="https://github.com/Leo3418/zarro-boogs-tools/archive/v${PV}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
fi

DESCRIPTION="Facade for Gentoo keywording tools that allows them to be used without Bugzilla"
HOMEPAGE="https://github.com/Leo3418/zarro-boogs-tools"

LICENSE="GPL-3+"
SLOT="0"

IUSE="test"
RESTRICT="!test? ( test )"

RDEPEND="
	app-portage/nattka[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	dev-util/pkgcheck[${PYTHON_USEDEP}]
	sys-apps/pkgcore[${PYTHON_USEDEP}]
"

BDEPEND="
	test? (
		${RDEPEND}
	)
"

distutils_enable_tests unittest
