# Copyright 2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="User for GNOME Initial Setup"
ACCT_USER_ID=-1
ACCT_USER_GROUPS=( gnome-initial-setup )

# From file data/gnome-initial-setup.conf under project gnome-initial-setup
ACCT_USER_COMMENT="GNOME Initial Setup"
ACCT_USER_HOME="/run/gnome-initial-setup"

acct-user_add_deps
