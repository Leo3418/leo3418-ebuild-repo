# Copyright 2021-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{10..12} )

inherit python-r1 wrapper

if [[ ${PV} == *9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/lorenzodifuccia/safaribooks.git"
else
	# Live ebuild: Might be intentionally left blank
	# Normal ebuild: Fill in commit SHA-1 object name to this variable's value
	GIT_COMMIT="af22b43c1cb18d54b83419d9a2041700f5981278"
	KEYWORDS="~amd64"

	SRC_URI="https://github.com/lorenzodifuccia/safaribooks/archive/${GIT_COMMIT}.tar.gz -> ${P}.tar.gz"
	S="${WORKDIR}/${PN}-${GIT_COMMIT}"
fi

DESCRIPTION="Download and generate EPUB of books from O'Reilly Learning library"
HOMEPAGE="https://github.com/lorenzodifuccia/safaribooks"

LICENSE="WTFPL-2"
SLOT="0"

REQUIRED_USE="${PYTHON_REQUIRED_USE}"

BDEPEND="
	${PYTHON_DEPS}
"

RDEPEND="
	${PYTHON_DEPS}
	dev-python/lxml[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
"

PATCHES=(
	"${FILESDIR}/${PN}-write-files-to-home.patch"
)

python_install() {
	python_moduleinto "${PN}"
	python_domodule *.py
	local py_src exe
	for py_src in *.py; do
		exe="${py_src%.py}"
		make_wrapper "${exe}.tmp" \
			"${EPYTHON} $(python_get_sitedir)/${PN}/${py_src}"
		python_newexe "${ED}/usr/bin/${exe}.tmp" "${exe}"
		rm "${ED}/usr/bin/${exe}.tmp" || \
			die "Failed to remove temporary wrapper executable for ${py_src}"
	done
}

src_install() {
	python_foreach_impl python_install
	einstalldocs
}

pkg_postinst() {
	if [[ -z "${REPLACING_VERSIONS}" ]]; then
		elog "The files created by this program will be stored under:"
		elog "	~/.safaribooks"
	fi
}
