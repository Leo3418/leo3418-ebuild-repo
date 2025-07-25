# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools desktop xdg

MY_PV="${PV%_p*}"
MY_P="${PN}-${MY_PV}"
TUXRACER_DATA_P="tuxracer-data-0.61"

DESCRIPTION="High speed arctic racing game based on Tux Racer"
HOMEPAGE="https://sourceforge.net/p/extremetuxracer/wiki/Home/"
SRC_URI="
	https://downloads.sourceforge.net/extremetuxracer/etr-${MY_PV}.tar.xz -> ${MY_P}.tar.xz
	!vanilla? ( https://downloads.sourceforge.net/tuxracer/${TUXRACER_DATA_P}.tar.gz )
"
S="${WORKDIR}/etr-${MY_PV/_/}"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="vanilla"

# <media-libs/libsfml-3: breaking changes
# https://sourceforge.net/p/extremetuxracer/discussion/help/thread/6de9a5beae/
RDEPEND="
	<media-libs/libsfml-3.0
	>=media-libs/libsfml-2.4:0=
	virtual/glu
	virtual/opengl
"
DEPEND="${RDEPEND}"
BDEPEND="
	virtual/pkgconfig
	!vanilla? (
		media-sound/modplugtools
		media-sound/sox[ogg]
	)
"

src_prepare() {
	default
	# kind of ugly in there so we'll do it ourselves
	sed -i -e '/SUBDIRS/s/resources doc//' Makefile.am || die
	eautoreconf
}

src_compile() {
	if use vanilla; then
		default
		return
	fi

	pushd "${WORKDIR}/${TUXRACER_DATA_P}/music" ||
		die "Failed to enter Tux Racer music directory"
	rm options1-jt.it wonrace1-jt.it ||
		die "Failed to remove duplicate music file"
	rm race2-jt.it || die "Failed to remove unused music file"

	einfo "Converting Tux Racer music files to WAV ..."
	local file
	for file in *.it; do
		# Connect /dev/tty to standard input to avoid
		# "warning: failed to get terminal size" from modplug123,
		# which would prevent the conversion from being performed
		modplug123 -ao wav "${file}" < /dev/tty ||
			die "Failed to convert ${file} to WAV"
		mv -v output.wav "${file/%.it/.wav}" ||
			die "Failed to rename output.wav converted from ${file}"
	done

	einfo "Converting WAV files to Ogg ..."
	local factor=10 # Use best quality
	sox start1-jt.wav -C "${factor}" start1-jt.ogg \
		trim 0 =22.26 =25.02 =27.84 ||
		die "Failed to convert start1-jt.wav to Ogg"
	sox race1-jt.wav -C "${factor}" race1-jt.ogg \
		trim 0.02 50.92 ||
		die "Failed to convert race1-jt.wav to Ogg"

	cp -v *.ogg "${S}/data/music" ||
		die "Failed to merge converted Ogg files into \${S}"
	cp -v "${S}/data/music/"{options1-jt,credits1-cp}.ogg ||
		die "Failed to replace credits screen music file"
	cp -v "${S}/data/music/"{wonrace1-jt,lostrace-ks}.ogg ||
		die "Failed to replace lost race music file"

	popd || die "Failed to leave Tux Racer music directory"
	default
}

src_install() {
	default
	dodoc doc/{code,courses_events,guide,score_algorithm}
	doicon -s 64 resources/etr.png
	doicon -s scalable resources/etr.svg
	domenu resources/net.sourceforge.extremetuxracer.desktop
}
