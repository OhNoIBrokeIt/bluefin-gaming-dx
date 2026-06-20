#!/usr/bin/env bash
set -ouex pipefail

required_packages=(
  hyprland-guiutils
  hyprland-qt-support
  xdg-desktop-portal-hyprland
  lxpolkit
  sddm
  qt6-qtsvg
  qt6-qtvirtualkeyboard
  qt6-qtmultimedia
  qt6-qtdeclarative
  qt6-qtwayland
  steam
  gamescope
  gamemode
  mangohud
  noctalia-shell
  protontricks
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
  /etc/sddm.conf.d/10-bluefin-gaming-hypr-theme.conf
  /usr/lib/tmpfiles.d/bluefin-gaming-hypr-dx.conf
)

for path in "${required_paths[@]}"; do
  if [[ ! -e "${path}" ]]; then
    echo "::error::Required path '${path}' is missing from the Hyprland image." >&2
    exit 1
  fi
done

if ! grep -q '^Current=sddm-astronaut-theme$' /etc/sddm.conf.d/10-bluefin-gaming-hypr-theme.conf; then
  echo "::error::SDDM Astronaut is not configured as the default SDDM theme." >&2
  exit 1
fi

if ! grep -q '^ConfigFile=Themes/astronaut.conf$' /usr/share/sddm/themes/sddm-astronaut-theme/metadata.desktop; then
  echo "::error::SDDM Astronaut metadata is not set to the astronaut theme variant." >&2
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
