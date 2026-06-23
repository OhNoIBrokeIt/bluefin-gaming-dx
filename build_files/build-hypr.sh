#!/usr/bin/env bash
set -ouex pipefail

ASTRONAUT_REF="${SDDM_ASTRONAUT_REF:-cd46736b4135a71700d2225d60eb8e85917585eb}"
ASTRONAUT_REPO="https://github.com/Keyitdev/sddm-astronaut-theme.git"
ASTRONAUT_THEME_DIR="/usr/share/sddm/themes/sddm-astronaut-theme"
ASTRONAUT_DEFAULT_VARIANT="${SDDM_ASTRONAUT_VARIANT:-hyprland_kath}"
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
  fuzzel \
  hyprpaper \
  hyprlock \
  hypridle \
  wl-clipboard \
  cliphist \
  grim \
  slurp \
  brightnessctl \
  playerctl \
  pavucontrol \
  kde-connect \
  qt6ct \
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

create_astronaut_variant() {
  local theme_name="$1"
  local config_name="$2"
  local variant_dir="/usr/share/sddm/themes/${theme_name}"

  if [[ ! -f "${ASTRONAUT_THEME_DIR}/Themes/${config_name}.conf" ]]; then
    echo "::error::SDDM Astronaut variant '${config_name}' does not exist." >&2
    exit 1
  fi

  rm -rf "${variant_dir}"
  install -d "${variant_dir}"

  for path in "${ASTRONAUT_THEME_DIR}"/*; do
    local base
    base="$(basename "${path}")"

    if [[ "${base}" == "metadata.desktop" ]]; then
      cp "${path}" "${variant_dir}/${base}"
      sed -i "s|^Name=.*|Name=${theme_name}|" "${variant_dir}/${base}"
      sed -i "s|^Description=.*|Description=${theme_name}|" "${variant_dir}/${base}"
      sed -i "s|^Theme-Id=.*|Theme-Id=${theme_name}|" "${variant_dir}/${base}"
      sed -i "s|^ConfigFile=.*|ConfigFile=Themes/${config_name}.conf|" "${variant_dir}/${base}"
    else
      ln -s "../$(basename "${ASTRONAUT_THEME_DIR}")/${base}" "${variant_dir}/${base}"
    fi
  done

  chmod -R a+rX "${variant_dir}"
}

case "${ASTRONAUT_DEFAULT_VARIANT}" in
  hyprland_kath|hyprland-kath|kath)
    ASTRONAUT_DEFAULT_THEME="sddm-astronaut-hyprland-kath"
    ;;
  black_hole|black-hole|blackhole)
    ASTRONAUT_DEFAULT_THEME="sddm-astronaut-black-hole"
    ;;
  *)
    echo "::error::Unsupported SDDM Astronaut variant '${ASTRONAUT_DEFAULT_VARIANT}'. Use 'hyprland_kath' or 'black_hole'." >&2
    exit 1
    ;;
esac

sed -i 's|^ConfigFile=.*|ConfigFile=Themes/astronaut.conf|' "${ASTRONAUT_THEME_DIR}/metadata.desktop"
create_astronaut_variant "sddm-astronaut-hyprland-kath" "hyprland_kath"
create_astronaut_variant "sddm-astronaut-black-hole" "black_hole"

install -d /etc/sddm.conf.d
cat >/etc/sddm.conf.d/10-bluefin-gaming-hypr-theme.conf <<EOF
[Theme]
Current=${ASTRONAUT_DEFAULT_THEME}

[General]
InputMethod=qtvirtualkeyboard
EOF

cat >/usr/bin/bluefin-hypr-sddm-theme <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

conf="/etc/sddm.conf.d/10-bluefin-gaming-hypr-theme.conf"

usage() {
  cat <<'USAGE'
Usage:
  bluefin-hypr-sddm-theme current
  bluefin-hypr-sddm-theme list
  bluefin-hypr-sddm-theme kath
  bluefin-hypr-sddm-theme black-hole
USAGE
}

theme_for() {
  case "$1" in
    kath|hyprland-kath|hyprland_kath)
      printf '%s\n' "sddm-astronaut-hyprland-kath"
      ;;
    black-hole|black_hole|blackhole)
      printf '%s\n' "sddm-astronaut-black-hole"
      ;;
    *)
      return 1
      ;;
  esac
}

current() {
  awk -F= '$1 == "Current" { print $2; found=1; exit } END { if (!found) exit 1 }' "${conf}" 2>/dev/null || true
}

set_theme() {
  local command="$1"
  local theme
  theme="$(theme_for "${command}")"

  if [[ "${EUID}" -ne 0 ]]; then
    exec sudo "$0" "${command}"
  fi

  install -d "$(dirname "${conf}")"

  if [[ ! -f "${conf}" ]]; then
    cat >"${conf}" <<EOF_CONF
[Theme]
Current=${theme}

[General]
InputMethod=qtvirtualkeyboard
EOF_CONF
    return
  fi

  if grep -q '^Current=' "${conf}"; then
    sed -i "s|^Current=.*|Current=${theme}|" "${conf}"
  elif grep -q '^\[Theme\]$' "${conf}"; then
    sed -i "/^\[Theme\]$/a Current=${theme}" "${conf}"
  else
    sed -i "1i[Theme]\nCurrent=${theme}\n" "${conf}"
  fi
}

case "${1:-}" in
  current)
    current
    ;;
  list)
    printf '%s\n' kath black-hole
    ;;
  kath|hyprland-kath|hyprland_kath|black-hole|black_hole|blackhole)
    set_theme "$1"
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac
EOF
chmod 0755 /usr/bin/bluefin-hypr-sddm-theme

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
env = XCURSOR_SIZE,24
env = HYPRCURSOR_SIZE,24
env = GDK_SCALE,1
env = QT_QPA_PLATFORMTHEME,qt6ct
env = QT_QPA_PLATFORM,wayland;xcb
env = QT_AUTO_SCREEN_SCALE_FACTOR,1
env = QT_WAYLAND_DISABLE_WINDOWDECORATION,1
env = XCURSOR_THEME,Adwaita
env = MOZ_ENABLE_WAYLAND,1
env = ELECTRON_OZONE_PLATFORM_HINT,auto
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland

$terminal = ghostty
exec-once = lxpolkit
exec-once = wl-paste --type text --watch cliphist store
exec-once = wl-paste --type image --watch cliphist store
exec-once = kdeconnect-indicator
bind = SUPER, RETURN, exec, sh -lc 'command -v ghostty >/dev/null && exec ghostty; command -v ptyxis >/dev/null && exec ptyxis; exec kgx'
EOF

systemctl disable gdm.service || true
systemctl enable sddm.service

/ctx/verify-hypr.sh

dnf5 clean all
rm -rf /var/cache/dnf /tmp/*
