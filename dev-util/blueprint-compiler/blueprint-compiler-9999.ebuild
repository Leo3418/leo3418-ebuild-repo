# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{8..10} )

inherit meson python-single-r1

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.gnome.org/jwestman/blueprint-compiler.git"
else
	# Live ebuild: Might be intentionally left blank
	# Normal ebuild: Fill in commit SHA-1 object name to this variable's value
	GIT_COMMIT=""
	KEYWORDS="~amd64"

	SRC_URI="https://gitlab.gnome.org/jwestman/blueprint-compiler/-/archive/${GIT_COMMIT}/blueprint-compiler-${GIT_COMMIT}.tar.gz"
	S="${WORKDIR}/${PN}-${GIT_COMMIT}"
fi

DESCRIPTION="Compiler of Blueprint, a markup language for GTK 4 user interfaces"
HOMEPAGE="https://jwestman.pages.gitlab.gnome.org/blueprint-compiler/"

LICENSE="LGPL-3+"
SLOT="0"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

DEPEND="
	${PYTHON_DEPS}
"

RDEPEND="
	${PYTHON_DEPS}
"

src_install() {
	meson_src_install
	python_optimize
	python_fix_shebang "${D}/usr/bin/${PN}"
}
