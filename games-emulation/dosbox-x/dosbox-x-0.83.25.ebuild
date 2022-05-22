# Copyright 2022 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit autotools xdg

if [[ "${PV}" == 9999 ]]; then
	inherit git-r3
	EGIT_REPO_URI="https://github.com/joncampbell123/dosbox-x.git"
else
	SRC_URI="https://github.com/joncampbell123/dosbox-x/archive/dosbox-x-v${PV}.tar.gz"
	S="${WORKDIR}/${PN}-${PN}-v${PV}"
	KEYWORDS="~amd64"
fi

DESCRIPTION="Complete, accurate DOS emulator forked from DOSBox"
HOMEPAGE="https://dosbox-x.com/"

# Stay consistent with games-emulation/dosbox::gentoo even though source file
# headers specify the GPL version to be "either version 2 of the License, or
# (at your option) any later version."  The same header is used in both the
# DOSBox source tree and the DOSBox-X source tree.
LICENSE="GPL-2"
SLOT="0"

IUSE="X debug ffmpeg fluidsynth freetype opengl png slirp"

BDEPEND="
	dev-lang/nasm
"

# Unconditionally pulling in automagically-enabled optional dependencies:
# - media-libs/alsa-lib
# - media-libs/sdl2-net
# - net-libs/libpcap
#
# With media-libs/libsdl2[-X,wayland], this package does work on a Wayland
# desktop, but (at least on GNOME) the program does not launch in a movable
# and resizable window; whereas with media-libs/libsdl2[X], it does.  Thus,
# unconditionally require media-libs/libsdl2[X] for better user experience.
RDEPEND="
	media-libs/alsa-lib
	media-libs/libsdl2[X,alsa,threads,video]
	media-libs/sdl2-net
	net-libs/libpcap
	sys-libs/zlib
	X? (
		x11-libs/libX11
		x11-libs/libXrandr
		x11-libs/libxkbfile
	)
	debug? ( sys-libs/ncurses:= )
	ffmpeg? ( media-video/ffmpeg:= )
	fluidsynth? ( media-sound/fluidsynth:= )
	freetype? ( media-libs/freetype )
	opengl? ( media-libs/libglvnd[X] )
	png? ( media-libs/libpng:= )
	slirp? ( net-libs/libslirp )
"

DEPEND="
	${RDEPEND}
"

src_prepare() {
	default
	eautoreconf
}

src_configure() {
	local myconf=(
		# --disable-core-inline could cause compiler errors
		# as of v0.83.25, so enable it unconditionally
		--enable-core-inline

		# Always use SDL 2, even though the package provides the option to
		# build with SDL 1.x, because this package is expected to be built
		# with the bundled, heavily-modified version of SDL 1.x if that
		# branch is used.  Compiler errors are likely to occur if the
		# bundled version of SDL 1.x is not used.  Bundled dependencies
		# should be avoided on Gentoo, so SDL 2 is more preferable.
		--enable-sdl2

		$(use_enable debug '' heavy)

		$(use_enable X x11)
		$(use_enable ffmpeg avcodec)
		$(use_enable fluidsynth libfluidsynth)
		$(use_enable freetype)
		$(use_enable opengl)
		$(use_enable png screenshots)
		$(use_enable slirp libslirp)
	)

	econf "${myconf[@]}"
}
