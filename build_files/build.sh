#!/usr/bin/env bash
set -ouex pipefail

# Universal Blue main images ship the Fedora/RPM Fusion repository setup needed
# for native Steam and common gaming packages. Keep package resolution here so
# CI fails during composition instead of leaving each client to solve multilib.

if rpm -q code >/dev/null; then
  dnf5 -y remove code
fi

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
  gamescope \
  gamemode \
  gamemode.i686 \
  mangohud \
  mangohud.i686 \
  vulkan-tools \
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

/ctx/verify-multilib.sh

if rpm -q code >/dev/null; then
  echo "::error::Visual Studio Code RPM package 'code' must not be installed in this image." >&2
  exit 1
fi

dnf5 clean all
rm -rf /var/cache/dnf /tmp/*
