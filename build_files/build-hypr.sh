#!/usr/bin/env bash
set -ouex pipefail

ASTRONAUT_REF="${SDDM_ASTRONAUT_REF:-cd46736b4135a71700d2225d60eb8e85917585eb}"
ASTRONAUT_REPO="https://github.com/Keyitdev/sddm-astronaut-theme.git"
ASTRONAUT_THEME_DIR="/usr/share/sddm/themes/sddm-astronaut-theme"
HYPR_COPR_OWNER="${HYPR_COPR_OWNER:-craftidore}"
HYPR_COPR_PROJECT="${HYPR_COPR_PROJECT:-wayblueorg-hyprland}"

# shellcheck source=/dev/null
source /etc/os-release
HYPR_COPR_CHROOT="${HYPR_COPR_CHROOT:-fedora-${VERSION_ID}-$(uname -m)}"

if rpm -q code >/dev/null; then
  echo "::error::Visual Studio Code RPM package 'code' must not be installed in this image." >&2
  exit 1
fi

dnf5 -y copr enable "${HYPR_COPR_OWNER}/${HYPR_COPR_PROJECT}" "${HYPR_COPR_CHROOT}"
dnf5 -y --no-gpgchecks \
  --repofrompath "terra,https://repos.fyralabs.com/terra${VERSION_ID}" \
  install terra-release

dnf5 -y install \
  hyprland \
  hyprland-guiutils \
  hyprland-qt-support \
  xdg-desktop-portal-hyprland \
  xdg-desktop-portal-gtk \
  waybar \
  wofi \
  hyprpaper \
  hyprlock \
  hypridle \
  wl-clipboard \
  grim \
  slurp \
  brightnessctl \
  playerctl \
  pavucontrol \
  lxpolkit \
  sddm \
  qt6-qtsvg \
  qt6-qtvirtualkeyboard \
  qt6-qtmultimedia \
  qt6-qtdeclarative \
  qt6-qtwayland \
  noctalia-shell \
  git

theme_tmp="$(mktemp -d)"
git -C "${theme_tmp}" init
git -C "${theme_tmp}" remote add origin "${ASTRONAUT_REPO}"
git -C "${theme_tmp}" fetch --depth 1 origin "${ASTRONAUT_REF}"
git -C "${theme_tmp}" checkout --detach FETCH_HEAD

rm -rf "${ASTRONAUT_THEME_DIR}"
install -d "${ASTRONAUT_THEME_DIR}"
cp -a "${theme_tmp}/." "${ASTRONAUT_THEME_DIR}/"
rm -rf "${ASTRONAUT_THEME_DIR}/.git"
chmod -R a+rX "${ASTRONAUT_THEME_DIR}"

if [[ -d "${ASTRONAUT_THEME_DIR}/Fonts" ]]; then
  cp -a "${ASTRONAUT_THEME_DIR}/Fonts/." /usr/share/fonts/
fi

sed -i 's|^ConfigFile=.*|ConfigFile=Themes/astronaut.conf|' "${ASTRONAUT_THEME_DIR}/metadata.desktop"

install -d /etc/sddm.conf.d
cat >/etc/sddm.conf.d/10-bluefin-gaming-hypr-theme.conf <<'EOF'
[Theme]
Current=sddm-astronaut-theme

[General]
InputMethod=qtvirtualkeyboard
EOF

install -d /usr/share/bluefin-gaming-hypr-dx
cat >/usr/share/bluefin-gaming-hypr-dx/sddm-state.conf <<'EOF'
[Last]
Session=hyprland.desktop
EOF

install -d /usr/lib/tmpfiles.d
cat >/usr/lib/tmpfiles.d/bluefin-gaming-hypr-dx.conf <<'EOF'
d /var/lib/sddm 0755 sddm sddm -
C /var/lib/sddm/state.conf 0644 sddm sddm - /usr/share/bluefin-gaming-hypr-dx/sddm-state.conf
EOF

install -d /etc/hypr
cat >/etc/hypr/hyprland.conf <<'EOF'
# System fallback config. User config in ~/.config/hypr/hyprland.conf wins.
source = /usr/share/hypr/hyprland.conf

env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = NVD_BACKEND,direct
env = GBM_BACKEND,nvidia-drm

$terminal = ghostty
exec-once = lxpolkit
bind = SUPER, RETURN, exec, sh -lc 'command -v ghostty >/dev/null && exec ghostty; command -v ptyxis >/dev/null && exec ptyxis; exec kgx'
EOF

systemctl disable gdm.service || true
systemctl enable sddm.service

/ctx/verify-hypr.sh

dnf5 clean all
rm -rf /var/cache/dnf /tmp/*
