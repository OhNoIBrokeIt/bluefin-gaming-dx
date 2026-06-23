#!/usr/bin/env bash
set -ouex pipefail

# Universal Blue main images ship the Fedora/RPM Fusion repository setup needed
# for native Steam and common gaming packages. Keep package resolution here so
# CI fails during composition instead of leaving each client to solve multilib.

# shellcheck source=/dev/null
source /etc/os-release
GHOSTTY_COPR_OWNER="${GHOSTTY_COPR_OWNER:-alternateved}"
GHOSTTY_COPR_PROJECT="${GHOSTTY_COPR_PROJECT:-ghostty}"
GHOSTTY_COPR_CHROOT="${GHOSTTY_COPR_CHROOT:-fedora-${VERSION_ID}-$(uname -m)}"
WINBOAT_VERSION="${WINBOAT_VERSION:-0.9.0}"
WINBOAT_TARBALL_URL="${WINBOAT_TARBALL_URL:-https://github.com/TibixDev/winboat/releases/download/v${WINBOAT_VERSION}/winboat-${WINBOAT_VERSION}-x64.tar.gz}"
WINBOAT_TARBALL_SHA256="${WINBOAT_TARBALL_SHA256:-9be10ccc06d0f999d10075cd127fba694eda841d3a533bde3776552fa66ae9e5}"
WINBOAT_TARBALL="/tmp/winboat-${WINBOAT_VERSION}-x64.tar.gz"
SLACK_VERSION="${SLACK_VERSION:-4.50.136}"
SLACK_RPM_URL="${SLACK_RPM_URL:-https://downloads.slack-edge.com/desktop-releases/linux/x64/${SLACK_VERSION}/slack-${SLACK_VERSION}-0.1.el8.x86_64.rpm}"
SLACK_RPM_SHA256="${SLACK_RPM_SHA256:-efe415e8f2bddf526044dfb0edad8b06bb4053cd8cd42951e2893cfafc818ad2}"
SLACK_RPM="/tmp/slack-${SLACK_VERSION}-0.1.el8.x86_64.rpm"
NORDVPN_VERSION="${NORDVPN_VERSION:-5.1.0}"
NORDVPN_RPM_URL="${NORDVPN_RPM_URL:-https://repo.nordvpn.com/yum/nordvpn/centos/x86_64/Packages/n/nordvpn-${NORDVPN_VERSION}-1.x86_64.rpm}"
NORDVPN_RPM_SHA256="${NORDVPN_RPM_SHA256:-a0e8c7534f6b15968c15b2d6aa4a8541f8fcb0c7ee9e40691841525c6ab8933e}"
NORDVPN_RPM="/tmp/nordvpn-${NORDVPN_VERSION}-1.x86_64.rpm"
PROTONVPN_RELEASE_VERSION="${PROTONVPN_RELEASE_VERSION:-1.0.4}"
PROTONVPN_RELEASE_RPM_URL="${PROTONVPN_RELEASE_RPM_URL:-https://repo.protonvpn.com/fedora-44-stable/protonvpn-stable-release/protonvpn-stable-release-${PROTONVPN_RELEASE_VERSION}-1.noarch.rpm}"
PROTONVPN_RELEASE_RPM_SHA256="${PROTONVPN_RELEASE_RPM_SHA256:-c3a4ca5943b142997597c1e1248226cfafbabe914c89895e0a8b2890e422657c}"
PROTONVPN_RELEASE_RPM="/tmp/protonvpn-stable-release-${PROTONVPN_RELEASE_VERSION}-1.noarch.rpm"

if rpm -q code >/dev/null; then
  dnf5 -y remove code
fi

dnf5 -y copr enable "${GHOSTTY_COPR_OWNER}/${GHOSTTY_COPR_PROJECT}" "${GHOSTTY_COPR_CHROOT}"

dnf5 -y upgrade \
  libdrm \
  mesa-filesystem \
  mesa-dri-drivers \
  mesa-libgbm \
  mesa-libEGL \
  mesa-libGL \
  mesa-vulkan-drivers \
  nspr \
  nss \
  nss-softokn \
  nss-softokn-freebl \
  nss-util \
  pipewire-alsa \
  pipewire-libs

dnf5 -y install \
  steam \
  at-spi2-core \
  ghostty \
  gamescope \
  gamemode \
  gamemode.i686 \
  gnome-extensions-app \
  gnome-shell-extension-appindicator \
  gtk3 \
  kitty \
  libappindicator-gtk3 \
  libnotify \
  libuuid \
  libXScrnSaver \
  libXtst \
  mangohud \
  mangohud.i686 \
  podman \
  podman-compose \
  freerdp \
  vulkan-tools \
  xdg-utils \
  protontricks \
  winetricks \
  wine-core \
  wine-core.i686 \
  wine-alsa \
  wine-alsa.i686 \
  wine-pulseaudio \
  wine-pulseaudio.i686 \
  wine-mono \
  alsa-lib.i686 \
  libFAudio.i686 \
  libatomic.i686 \
  libcurl.i686 \
  libdrm.i686 \
  libdrm \
  libglvnd-egl.i686 \
  libglvnd-glx.i686 \
  libva.i686 \
  libvdpau.i686 \
  libX11.i686 \
  libXScrnSaver.i686 \
  libXcursor.i686 \
  libXi.i686 \
  libXinerama.i686 \
  libXrandr.i686 \
  mesa-filesystem \
  mesa-filesystem.i686 \
  mesa-dri-drivers \
  mesa-dri-drivers.i686 \
  mesa-libgbm \
  mesa-libgbm.i686 \
  mesa-libEGL \
  mesa-libEGL.i686 \
  mesa-libGL \
  mesa-libGL.i686 \
  mesa-libGLU.i686 \
  mesa-vulkan-drivers \
  mesa-vulkan-drivers.i686 \
  mpg123-libs.i686 \
  nss \
  nss.i686 \
  openal-soft.i686 \
  openssl-libs.i686 \
  pipewire-alsa \
  pipewire-alsa.i686 \
  pipewire-libs \
  pipewire-libs.i686 \
  vulkan-loader.i686

curl -fsSL --retry 3 --retry-delay 2 --output "${WINBOAT_TARBALL}" "${WINBOAT_TARBALL_URL}"
echo "${WINBOAT_TARBALL_SHA256}  ${WINBOAT_TARBALL}" | sha256sum --check --status
rm -rf /usr/lib/winboat
install -d /usr/lib/winboat /usr/share/applications
tar -xzf "${WINBOAT_TARBALL}" --strip-components=1 -C /usr/lib/winboat
chmod 0755 /usr/lib/winboat/chrome-sandbox
ln -sf /usr/lib/winboat/winboat /usr/bin/winboat
cat >/usr/share/applications/winboat.desktop <<'EOF'
[Desktop Entry]
Name=WinBoat
Comment=Run Windows apps on Linux
Exec=winboat %U
Terminal=false
Type=Application
Categories=Utility;System;
StartupWMClass=winboat
EOF
rm -f "${WINBOAT_TARBALL}"

curl -fsSL --retry 3 --retry-delay 2 --output "${SLACK_RPM}" "${SLACK_RPM_URL}"
echo "${SLACK_RPM_SHA256}  ${SLACK_RPM}" | sha256sum --check --status
dnf5 -y install "${SLACK_RPM}"
rm -f "${SLACK_RPM}"

curl -fsSL --retry 3 --retry-delay 2 --output "${NORDVPN_RPM}" "${NORDVPN_RPM_URL}"
echo "${NORDVPN_RPM_SHA256}  ${NORDVPN_RPM}" | sha256sum --check --status
dnf5 -y install "${NORDVPN_RPM}"
rm -f "${NORDVPN_RPM}"

curl -fsSL --retry 3 --retry-delay 2 --output "${PROTONVPN_RELEASE_RPM}" "${PROTONVPN_RELEASE_RPM_URL}"
echo "${PROTONVPN_RELEASE_RPM_SHA256}  ${PROTONVPN_RELEASE_RPM}" | sha256sum --check --status
dnf5 -y install "${PROTONVPN_RELEASE_RPM}"
rm -f "${PROTONVPN_RELEASE_RPM}"
dnf5 -y install proton-vpn-gnome-desktop

/ctx/verify-multilib.sh

required_commands=(
  ghostty
  kitty
  nordvpn
  podman
  podman-compose
  protonvpn-app
  slack
  winboat
  xfreerdp
)

for command in "${required_commands[@]}"; do
  if ! command -v "${command}" >/dev/null; then
    echo "::error::Required command '${command}' is missing from the image." >&2
    exit 1
  fi
done

systemctl enable nordvpnd.service
systemctl enable nordvpnd.socket
systemctl enable nordvpnd-killswitch.service
systemctl enable me.proton.vpn.split_tunneling.service

if rpm -q code >/dev/null; then
  echo "::error::Visual Studio Code RPM package 'code' must not be installed in this image." >&2
  exit 1
fi

dnf5 clean all
rm -rf /var/cache/dnf /tmp/*
