# Copyright 2023 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..11} )
DISTUTILS_USE_PEP517=setuptools

inherit distutils-r1

if [[ "${PV}" == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/enzingerm/snapborg.git"
else
	if [[ "${PV}" == *_pre* ]] || [[ "${PV}" == *_p* ]]; then
		GIT_COMMIT=""
		[[ -n "${GIT_COMMIT}" ]] ||
			die "GIT_COMMIT is not defined for snapshot ebuild"
		MY_PV="${GIT_COMMIT}"
	else
		MY_PV="${PV}"
	fi
	MY_P="${PN}-${MY_PV}"
	SRC_URI="https://github.com/enzingerm/snapborg/archive/${MY_PV}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${MY_P}"
	KEYWORDS="~amd64"
fi

DESCRIPTION="Synchronize Snapper snapshots to a BorgBackup repository"
HOMEPAGE="https://github.com/enzingerm/snapborg"

LICENSE="GPL-3+" # Declared in setup.py
SLOT="0"

COMMON_DEPEND="
	dev-python/packaging[${PYTHON_USEDEP}]
	dev-python/pyyaml[${PYTHON_USEDEP}]
"

BDEPEND="
	${COMMON_DEPEND}
"

RDEPEND="
	${COMMON_DEPEND}
	app-backup/borgbackup
	app-backup/snapper
"

src_prepare() {
	default
	sed -i -e '/^    data_files=\[/,/^    \],/d' setup.py ||
		die "Failed to remove data files from setup.py"
	distutils-r1_src_prepare
}

src_install() {
	distutils-r1_src_install

	insinto /etc
	doins etc/snapborg.yaml
}
