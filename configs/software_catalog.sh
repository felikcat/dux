#!/bin/bash
# shellcheck disable=SC2034
set -a


# === Proprietary Software ===
# Official Discord client with additional safety and privacy provided by Flatpak's sandboxing.
# However, this sandboxing prevents the following features from working out of the box: 
# Game Activity, Unrestricted File Access, Rich Presence.
discord="1"


# === Open-Source Software ===
# Adds full support for AppImages.
appimagelauncher="0"

# The overall best Microsoft Office replacement.
onlyoffice="1"

# Interactive application firewall.
opensnitch="1"

# C/C++ debugging and reverse engineering: Valgrind, GDB, radere2 + ghidra (graphical interface: Cutter), pwndbg.
cxx_toolbox="0"

# Generally the best web browser on Linux; installs the "Developer Edition" for its additional tools.
firefox_dev="1"

# A patchbay for Pipewire; used to direct where audio transmits to and from.
qpwgraph="1"

# File synchronization utility; meant for use alongside a TrueNAS machine for automated backups
syncthing="1"

# File manager/explorer; already installed by default.
dolphin="1"

# A video/media player that's very extensible and works better than both MPC-HC and VLC.
mpv="1"

# PDF, Postscript, TIFF, DVI, and DjVu viewer.
evince="1"

# For screen recording, livestreaming, and acts as a virtual + physical camera manager.
obs_studio="1"

# EPUB, Mobipocket, Kindle, FictionBook, and Comic book viewer.
foliate="1"

# A great BitTorrent client with anti-leeching features.
qbittorrent_enhanced="1"

# Image & GIF viewer.
feh="1"

# Video downloader (CLI).
yt_dlp="1"

# Email, calendar, and RSS reader.
evolution="1"

# Messaging platform #2.
telegram="1"

# GNOME System Monitor: The best designed process manager; easy to use and comprehensive. 
task_manager="1"
