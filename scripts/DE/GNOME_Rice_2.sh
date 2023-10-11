#!/bin/bash
# shellcheck disable=SC2154
set +H
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}" && GIT_DIR=$(git rev-parse --show-toplevel)
source "${GIT_DIR}/scripts/GLOBAL_IMPORTS.sh"
source "${GIT_DIR}/configs/settings.sh"

if [[ ${IS_CHROOT} -eq 1 ]]; then
    echo -e "\nERROR: Do not run this script inside a chroot!\n"
	exit 1
fi

ExternalGnomeSettings() {
	cat << 'EOF' >>"/home/${WHICH_USER}/.zshrc"

# Make files in '~/.config/environment.d' apply.
/usr/lib/systemd/user-environment-generators/30-systemd-environment-d-generator >&/dev/null
EOF

	_move2bkup /home/"${WHICH_USER}"/.gtkrc-2.0
	_move2bkup /home/"${WHICH_USER}"/.config/{environment.d,gtk-3.0,gtk-4.0,Kvantum,qt5ct,qt6ct} &&
		mkdir "${mkdir_flags}" /home/"${WHICH_USER}"/.config/{environment.d,Kvantum,qt5ct,qt6ct}

	\cp "${cp_flags}" "${GIT_DIR}"/files/home/.gtkrc-2.0 "/home/${WHICH_USER}/"
	\cp "${cp_flags}" "${GIT_DIR}"/files/home/.config/environment.d/gnome.conf "/home/${WHICH_USER}/.config/environment.d/"
	\cp "${cp_flags}" "${GIT_DIR}"/files/home/.config/qt5ct/qt5ct.conf "/home/${WHICH_USER}/.config/qt5ct/"
	\cp "${cp_flags}" "${GIT_DIR}"/files/home/.config/qt6ct/qt6ct.conf "/home/${WHICH_USER}/.config/qt6ct/"

	kwriteconfig5 --file /home/"${WHICH_USER}"/.config/Kvantum/kvantum.kvconfig --group "General" --key "theme" "KvGnomeDark"

	kwriteconfig5 --file /home/"${WHICH_USER}"/.config/konsolerc --group "UiSettings" --key "ColorScheme" "KvGnomeDark"
	kwriteconfig5 --file /home/"${WHICH_USER}"/.config/konsolerc --group "UiSettings" --key "WindowColorScheme" "KvGnomeDark"
}
ExternalGnomeSettings

PKGS_AUR+=(adw-gtk3-git)
_pkgs_aur_add

GnomeSettings() {
	local SCHEMA="org.gnome.desktop"
	gsettings set "${SCHEMA}".interface document-font-name "Inter Regular 11"
	gsettings set "${SCHEMA}".interface font-name "Inter Regular 11"
	# KDE = font size 11, GNOME = font size 10.
	gsettings set "${SCHEMA}".interface monospace-font-name "Hack 10"

	gsettings set "${SCHEMA}".interface font-antialiasing "grayscale"
	gsettings set "${SCHEMA}".interface font-hinting "none"

	gsettings set "${SCHEMA}".interface color-scheme "prefer-dark"
	gsettings set "${SCHEMA}".interface gtk-theme "adw-gtk3-dark"
	gsettings set "${SCHEMA}".interface icon-theme "Papirus-Dark"

	gsettings set "${SCHEMA}".interface enable-animations "${gnome_animations}"

	gsettings set "${SCHEMA}".peripherals.mouse accel-profile "${gnome_mouse_accel_profile}"
	gsettings set "${SCHEMA}".privacy remember-app-usage "${gnome_remember_app_usage}"
	gsettings set "${SCHEMA}".privacy remember-recent-files "${gnome_remember_recent_files}"

	[[ ${gnome_no_idle} -eq 1 ]] &&
		gsettings set "${SCHEMA}".session idle-delay "0"
}
GnomeSettings

if [[ ${gnome_no_window_shadows} -eq 1 ]]; then
	if ! grep -q "decoration {box-shadow: none;}" /home/"${WHICH_USER}"/.config/gtk-3.0/gtk.css; then
		touch /home/"${WHICH_USER}"/.config/gtk-3.0/gtk.css
        cat << 'EOF' >>"/home/${WHICH_USER}/.config/gtk-3.0/gtk.css"

decoration {box-shadow: none;}
EOF
    fi
fi

gsettings set org.gnome.shell disable-user-extensions "true"

# scale-monitor-framebuffer = Fractional scaling; 100%, 125%, 150%, etc.
# -> Allows increasing display scaling by steps of 25% instead of 100%.
# -> Downside is it increases GPU load, leading to more power usage.
#
# kms-modifiers = hardware accelerated Xwayland on NVIDIA.
# -> See: https://download.nvidia.com/XFree86/Linux-x86_64/530.41.03/README/xwayland.html
gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer','kms-modifiers','x11-randr-fractional-scaling']" || :

gsettings set org.gnome.mutter center-new-windows "${gnome_center_new_windows}"

# Required for ~/.config/environment.d/gnome.conf to take effect without rebooting.
whiptail --yesno "A logout is required to complete the GNOME rice.\nLogout now?" 0 0 &&
	loginctl terminate-user "${WHICH_USER}"
