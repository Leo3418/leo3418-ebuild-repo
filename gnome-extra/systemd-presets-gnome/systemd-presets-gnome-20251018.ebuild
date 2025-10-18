# Copyright 2024-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit systemd

DESCRIPTION="systemd Preset Files for GNOME"
HOMEPAGE="https://wiki.gentoo.org/wiki/No_homepage"

S="${WORKDIR}"

# Package content taken from:
# - https://src.fedoraproject.org/rpms/fedora-release
LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

src_install() {
	local system_preset_dir="$(systemd_get_systempresetdir)"
	local user_preset_dir="$(systemd_get_utildir)/user-preset"

	insinto "${system_preset_dir}"
	newins - 80-gnome.preset <<- _EOF_
	enable gdm.service

	# For GNOME Settings (gnome-control-center)
	enable bluetooth.service
	enable cups.socket
	enable NetworkManager.service
	enable NetworkManager-dispatcher.service
	enable NetworkManager-wait-online.service

	# Avoid conflicts between NetworkManager and systemd-networkd;
	# GNOME Settings does not have integration with systemd-networkd
	disable systemd-networkd.service
	disable systemd-networkd-wait-online.service
	disable systemd-network-generator.service

	# Disable SSH server by default for desktop systems
	disable sshd.socket
	_EOF_

	insinto "${user_preset_dir}"
	newins - 80-gnome.preset <<- _EOF_
	# Replace PulseAudio with PipeWire
	disable pulseaudio.*
	enable pipewire.socket
	enable pipewire-pulse.socket
	enable wireplumber.service

	# For better media control functionality of Bluetooth devices,
	# like automatic pausing when headphones are taken off
	enable mpris-proxy.service

	# Use GNOME Keyring as ssh-agent
	enable gcr-ssh-agent.socket
	_EOF_
}
