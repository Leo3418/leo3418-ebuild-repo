# Copyright 2016-2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

if [[ ${PV} == 9999* ]]; then
	ECLASS="git-r3"
	EGIT_REPO_URI="https://github.com/Leo3418/java-ebuilder.git"
	MY_S="${WORKDIR}/${P}"
else
	# Live ebuild: Might be intentionally left blank
	# Normal ebuild: Fill in commit SHA-1 object name to this variable's value
	GIT_COMMIT=""
	SRC_URI="https://github.com/Leo3418/java-ebuilder/archive/${GIT_COMMIT}.tar.gz -> ${P}.tar.gz"
	KEYWORDS="~amd64"
	MY_S="${WORKDIR}/${PN}-${GIT_COMMIT}"
fi

PYTHON_COMPAT=( python3_{8..10} )
inherit java-pkg-2 java-pkg-simple prefix python-single-r1 ${ECLASS}

DESCRIPTION="Java team tool for semi-automatic creation of ebuilds from pom.xml"
HOMEPAGE="https://github.com/gentoo/java-ebuilder"

LICENSE="GPL-2"
SLOT="0"

IUSE="test"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"
PROPERTIES="test_network"
RESTRICT="test"

RDEPEND=">=virtual/jre-1.8:*
	>=dev-java/maven-bin-3
	sys-process/parallel
	sys-apps/portage
	${PYTHON_DEPS}"
DEPEND=">=virtual/jdk-1.8:*
	test? ( ${RDEPEND} )"

S="${MY_S}"

JAVA_SRC_DIR="src/main/java"
JAVA_RESOURCE_DIRS="src/main/resources"

JAVA_LAUNCHER_FILENAME=${PN}
JAVA_MAIN_CLASS="org.gentoo.java.ebuilder.Main"

src_prepare() {
	default
	python_fix_shebang .
	hprefixify scripts/{bin/*,resources/Makefiles/*,movl} java-ebuilder.conf
}

src_test() {
	env SRC_ROOT="." CLASSPATH="${PN}.jar" \
		MAVEN_OPTS="-Dmaven.repo.local=${HOME}/.m2/repository" \
		tests/ebuild-tests.sh -v || die "ebuild generation tests failed"
}

src_install() {
	java-pkg-simple_src_install

	insinto /var/lib/${PN}
	doins -r maven
	dodir /var/lib/${PN}/{poms,cache}
	keepdir /var/lib/${PN}/{poms,cache}

	dodoc README.md maven.conf

	exeinto /usr/lib/${PN}/bin
	doexe scripts/bin/*
	insinto /usr/lib/${PN}
	doins -r scripts/resources/*
	dobin scripts/movl

	insinto /etc
	doins java-ebuilder.conf
}
