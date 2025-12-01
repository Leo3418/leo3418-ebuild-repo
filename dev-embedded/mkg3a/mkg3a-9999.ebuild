# Copyright 2022-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake

if [[ "${PV}" == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://gitlab.com/taricorp/mkg3a.git"
else
	# tar.bz2 is slightly smaller than tar.gz
	SRC_URI="https://gitlab.com/taricorp/mkg3a/-/archive/${PV}/${P}.tar.bz2"
	KEYWORDS="~amd64"
fi

DESCRIPTION="A utility for creating CASIO fx-CG50 add-in (.g3a) files"
HOMEPAGE="https://gitlab.com/taricorp/mkg3a"

LICENSE="ZLIB"
SLOT="0"

RDEPEND="
	media-libs/libpng:=
"

DEPEND="
	${RDEPEND}
	virtual/zlib:=
"

src_install() {
	# The project installs a compressed copy of its manual pages from CMake,
	# which would trigger a QA notice from Portage if manual pages were not
	# added to the exclusion list for compression
	docompress -x /usr/share/man

	cmake_src_install
}
