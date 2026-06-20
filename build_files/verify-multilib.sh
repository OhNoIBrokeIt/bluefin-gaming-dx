#!/usr/bin/env bash
set -euo pipefail

required_i686=(
  mesa-filesystem.i686
  mesa-dri-drivers.i686
  mesa-libgbm.i686
  mesa-libEGL.i686
  mesa-libGL.i686
  mesa-vulkan-drivers.i686
  nss.i686
)

echo "Verifying required i686 Steam/Proton runtime packages..."
for pkg in "${required_i686[@]}"; do
  if ! rpm -q "$pkg" >/dev/null; then
    echo "::error::Required package is missing after install: $pkg" >&2
    exit 1
  fi
done

version_of() {
  rpm -q --qf '%{EPOCHNUM}:%{VERSION}-%{RELEASE}\n' "$1"
}

aligned_pairs=(
  mesa-filesystem
  mesa-dri-drivers
  mesa-libgbm
  mesa-libEGL
  mesa-libGL
  mesa-vulkan-drivers
  nss
)

echo "Verifying x86_64/i686 Mesa and NSS version alignment..."
for name in "${aligned_pairs[@]}"; do
  x86_pkg="${name}.x86_64"
  i686_pkg="${name}.i686"

  if ! rpm -q "$x86_pkg" >/dev/null; then
    echo "::error::Expected x86_64 package missing: $x86_pkg" >&2
    exit 1
  fi

  x86_version="$(version_of "$x86_pkg")"
  i686_version="$(version_of "$i686_pkg")"

  if [[ "$x86_version" != "$i686_version" ]]; then
    echo "::error::Multilib version mismatch for $name: x86_64=$x86_version i686=$i686_version" >&2
    exit 1
  fi
done

echo "Multilib package verification passed."
