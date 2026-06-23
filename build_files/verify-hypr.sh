#!/usr/bin/env bash
set -ouex pipefail

required_packages=(
  hyprland-guiutils
  hyprland-qt-support
  xdg-desktop-portal-hyprland
  fuzzel
  cliphist
  kde-connect
  qt6ct
  lxpolkit
  sddm
  qt6-qtsvg
  qt6-qtvirtualkeyboard
  qt6-qtmultimedia
  qt6-qtdeclarative
  qt6-qtwayland
  steam
  ghostty
  gamescope
  gamemode
  kitty
  mangohud
  nordvpn
  podman
  podman-compose
  freerdp
  vulkan-tools
  noctalia-shell
  proton-vpn-gnome-desktop
  protontricks
  winetricks
  wine-core
  slack
)

for package in "${required_packages[@]}"; do
  if ! rpm -q "${package}" >/dev/null; then
    echo "::error::Required package '${package}' is missing from the Hyprland image." >&2
    exit 1
  fi
done

if [[ ! -x /usr/bin/Hyprland && ! -x /usr/bin/hyprland ]]; then
  echo "::error::Hyprland binary is missing from the Hyprland image." >&2
  exit 1
fi

required_paths=(
  /usr/share/wayland-sessions/hyprland.desktop
  /usr/share/wayland-sessions/gnome.desktop
  /usr/share/sddm/themes/sddm-astronaut-theme/Main.qml
  /usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop
  /usr/share/sddm/themes/sddm-astronaut-theme/Themes/black_hole.conf
  /usr/share/sddm/themes/sddm-astronaut-theme/Themes/hyprland_kath.conf
  /usr/share/sddm/themes/sddm-astronaut-hyprland-kath/Main.qml
  /usr/share/sddm/themes/sddm-astronaut-hyprland-kath/metadata.desktop
  /usr/share/sddm/themes/sddm-astronaut-black-hole/Main.qml
  /usr/share/sddm/themes/sddm-astronaut-black-hole/metadata.desktop
  /etc/sddm.conf.d/10-bluefin-gaming-hypr-theme.conf
  /usr/lib/tmpfiles.d/bluefin-gaming-hypr-dx.conf
  /usr/bin/bluefin-hypr-sddm-theme
)

for path in "${required_paths[@]}"; do
  if [[ ! -e "${path}" ]]; then
    echo "::error::Required path '${path}' is missing from the Hyprland image." >&2
    exit 1
  fi
done

unreadable_theme_dir="$(find /usr/share/sddm/themes/sddm-astronaut-theme -type d ! -perm -005 -print -quit)"
if [[ -n "${unreadable_theme_dir}" ]]; then
  echo "::error::SDDM Astronaut theme directory is not readable/traversable by SDDM: ${unreadable_theme_dir}" >&2
  exit 1
fi

unreadable_theme_file="$(find /usr/share/sddm/themes/sddm-astronaut-theme -type f ! -perm -004 -print -quit)"
if [[ -n "${unreadable_theme_file}" ]]; then
  echo "::error::SDDM Astronaut theme file is not readable by SDDM: ${unreadable_theme_file}" >&2
  exit 1
fi

if ! grep -q '^Current=sddm-astronaut-hyprland-kath$' /etc/sddm.conf.d/10-bluefin-gaming-hypr-theme.conf; then
  echo "::error::SDDM Astronaut Hyprland Kath is not configured as the default SDDM theme." >&2
  exit 1
fi

if ! grep -q '^ConfigFile=Themes/astronaut.conf$' /usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop; then
  echo "::error::SDDM Astronaut metadata is not set to the astronaut theme variant." >&2
  exit 1
fi

if ! grep -q '^ConfigFile=Themes/hyprland_kath.conf$' /usr/share/sddm/themes/sddm-astronaut-hyprland-kath/metadata.desktop; then
  echo "::error::SDDM Astronaut Hyprland Kath metadata is not set to the hyprland_kath variant." >&2
  exit 1
fi

if ! grep -q '^ConfigFile=Themes/black_hole.conf$' /usr/share/sddm/themes/sddm-astronaut-black-hole/metadata.desktop; then
  echo "::error::SDDM Astronaut Black Hole metadata is not set to the black_hole variant." >&2
  exit 1
fi

if ! /usr/bin/bluefin-hypr-sddm-theme list | grep -qx 'kath'; then
  echo "::error::SDDM theme switcher does not list the Kath variant." >&2
  exit 1
fi

if ! /usr/bin/bluefin-hypr-sddm-theme list | grep -qx 'black-hole'; then
  echo "::error::SDDM theme switcher does not list the Black Hole variant." >&2
  exit 1
fi

if ! systemctl is-enabled sddm.service >/dev/null; then
  echo "::error::sddm.service is not enabled." >&2
  exit 1
fi

if systemctl is-enabled gdm.service >/dev/null 2>&1; then
  echo "::error::gdm.service must not be enabled in the Hyprland variant." >&2
  exit 1
fi

if rpm -q code >/dev/null; then
  echo "::error::Visual Studio Code RPM package 'code' must not be installed in this image." >&2
  exit 1
fi

required_commands=(
  gamescope
  ghostty
  kitty
  nordvpn
  podman
  podman-compose
  protontricks
  protonvpn-app
  slack
  steam
  winboat
  winetricks
  xfreerdp
)

for command in "${required_commands[@]}"; do
  if ! command -v "${command}" >/dev/null; then
    echo "::error::Required inherited native command '${command}' is missing from the Hyprland image." >&2
    exit 1
  fi
done
