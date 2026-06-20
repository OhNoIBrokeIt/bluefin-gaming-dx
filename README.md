# bluefin-gaming-dx

`bluefin-gaming-dx` is a Universal Blue image-template style repository that publishes two Bluefin-derived gaming images:

```text
ghcr.io/<user>/bluefin-gaming-dx:latest
ghcr.io/<user>/bluefin-gaming-hypr-dx:latest
```

Both images keep Bluefin DX, NVIDIA Open compatibility, HDR-capable base graphics components, native Steam, Gamescope, and the gaming runtime package set. Neither image rebases to Bazzite.

## Image Variants

### bluefin-gaming-dx

Base image:

```text
ghcr.io/ublue-os/bluefin-dx-nvidia-open:stable
```

Use this image when you want Bluefin DX GNOME as the primary desktop with native Steam and multilib gaming packages composed into the image.

This variant:

- keeps GNOME as the only desktop target
- preserves Bluefin DX developer tooling
- preserves NVIDIA Open compatibility from Bluefin
- preserves HDR support provided by the base image stack
- installs native Steam, Gamescope, Gamemode, MangoHud, Vulkan tools, Protontricks, Winetricks, Wine runtime packages, and Steam/Proton multilib dependencies
- removes the Visual Studio Code RPM package `code`

### bluefin-gaming-hypr-dx

Base image:

```text
ghcr.io/<user>/bluefin-gaming-dx:latest
```

Use this image when Hyprland should be the primary daily-driver session while GNOME remains installed as a fallback and troubleshooting session.

This variant keeps everything from `bluefin-gaming-dx` and additionally:

- installs Hyprland
- installs `xdg-desktop-portal-hyprland`
- keeps GNOME installed and available from the login screen
- replaces GDM as the enabled display manager with SDDM
- installs the SDDM Astronaut theme
- sets Astronaut as the default SDDM theme
- installs Qt6/QML dependencies required by the theme
- enables `sddm.service`
- disables `gdm.service`
- does not install Visual Studio Code
- does not modify Homebrew or Neovim

Hyprland packages are resolved from the `craftidore/wayblueorg-hyprland` COPR because the Fedora 44 repositories enabled in the Bluefin base do not currently provide the `hyprland` package directly. This COPR is used only by the Hyprland image variant.

As of June 20, 2026, upstream Hyprland's latest release is `v0.55.4`, and this COPR resolves `hyprland-git 0.55.4^3.git9556660-1.fc44` on Fedora 44. That keeps the image current rather than pinned to an old Hyprland release.

## Gaming Packages

The base gaming image installs:

- Native Steam RPM package
- Gamescope
- Gamemode
- MangoHud
- Vulkan tools
- Protontricks and Winetricks
- Wine runtime packages commonly needed by Steam/Proton
- Steam runtime support packages
- Required 32-bit i686 multilib runtime packages for Steam and Proton

Required i686 packages installed explicitly:

```text
mesa-filesystem.i686
mesa-dri-drivers.i686
mesa-libgbm.i686
mesa-libEGL.i686
mesa-libGL.i686
mesa-vulkan-drivers.i686
nss.i686
```

## Repository Structure

```text
bluefin-gaming-dx/
├── .github/
│   └── workflows/
│       ├── build.yml
│       └── build-hypr.yml
├── build_files/
│   ├── build.sh
│   ├── build-hypr.sh
│   ├── verify-hypr.sh
│   └── verify-multilib.sh
├── .gitignore
├── Containerfile
├── Containerfile.hypr
├── Justfile
└── README.md
```

## How to Fork

1. Fork or copy this repository.
2. Keep the repository name as `bluefin-gaming-dx` unless you also update workflow labels and README URLs.
3. Enable GitHub Actions for the repository.
4. In repository settings, allow GitHub Actions to write packages.
5. Optional: create a cosign key pair and add the private key as the `SIGNING_SECRET` repository secret.

Generate a signing key:

```bash
COSIGN_PASSWORD="" cosign generate-key-pair
```

Add the private key as a GitHub Actions secret named `SIGNING_SECRET`. Do not commit `cosign.key`.

The workflows still build and publish without `SIGNING_SECRET`; they skip signing.

## How to Build Locally

Build the GNOME image:

```bash
podman build --pull=newer --tag bluefin-gaming-dx:latest .
```

Or with `just`:

```bash
just build
```

Build the Hyprland image from the published GNOME gaming image:

```bash
podman build \
  --pull=newer \
  --file Containerfile.hypr \
  --build-arg BASE_IMAGE=ghcr.io/<user>/bluefin-gaming-dx:latest \
  --tag bluefin-gaming-hypr-dx:latest \
  .
```

Or with `just`:

```bash
just build-hypr bluefin-gaming-hypr-dx latest ghcr.io/<user>/bluefin-gaming-dx:latest
```

## How to Publish

Push to the default branch.

The GNOME workflow publishes:

```text
ghcr.io/<user>/bluefin-gaming-dx:latest
ghcr.io/<user>/bluefin-gaming-dx:stable
ghcr.io/<user>/bluefin-gaming-dx:<YYYYMMDD>
ghcr.io/<user>/bluefin-gaming-dx:latest.<YYYYMMDD>
```

After the GNOME workflow succeeds, the Hyprland workflow publishes:

```text
ghcr.io/<user>/bluefin-gaming-hypr-dx:latest
ghcr.io/<user>/bluefin-gaming-hypr-dx:stable
ghcr.io/<user>/bluefin-gaming-hypr-dx:<YYYYMMDD>
ghcr.io/<user>/bluefin-gaming-hypr-dx:latest.<YYYYMMDD>
```

Pull requests build images but do not publish them.

## How to Rebase

Replace `<user>` with your GitHub username or organization.

GNOME image:

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/<user>/bluefin-gaming-dx:latest
systemctl reboot
```

Hyprland image:

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/<user>/bluefin-gaming-hypr-dx:latest
systemctl reboot
```

If you do not configure signing, use the unsigned image transport.

GNOME unsigned:

```bash
sudo rpm-ostree rebase ostree-unverified-image:docker://ghcr.io/<user>/bluefin-gaming-dx:latest
systemctl reboot
```

Hyprland unsigned:

```bash
sudo rpm-ostree rebase ostree-unverified-image:docker://ghcr.io/<user>/bluefin-gaming-hypr-dx:latest
systemctl reboot
```

For this repository as published under `OhNoIBrokeIt`, the unsigned Hyprland command is:

```bash
sudo rpm-ostree rebase ostree-unverified-image:docker://ghcr.io/ohnoibrokeit/bluefin-gaming-hypr-dx:latest
systemctl reboot
```

## How to Roll Back

To boot the previous deployment one time:

```bash
sudo rpm-ostree rollback
systemctl reboot
```

To return to upstream Bluefin DX GNOME NVIDIA Open:

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/ublue-os/bluefin-dx-nvidia-open:stable
systemctl reboot
```

## Which Image to Use

Use `bluefin-gaming-dx` when:

- GNOME should remain the daily-driver desktop
- you want the smallest desktop delta from Bluefin DX
- you want native Steam and Proton support without changing login/session behavior

Use `bluefin-gaming-hypr-dx` when:

- Hyprland should be the primary daily-driver environment
- you want SDDM instead of GDM
- you still want GNOME available as a fallback session for HDR, NVIDIA, Gamescope, Steam, or general compatibility troubleshooting

The Hyprland image is intentionally additive. It does not remove GNOME packages.

## Fedora 44 Package Notes

The Fedora 44 package names used by the GNOME image are intentionally plain RPM package names resolved during image composition:

- `gamemode` is the Fedora package. There is no Fedora 44 package named `game-performance` in the standard Fedora repositories used for this image.
- `steam` is installed as a native RPM package from the enabled gaming/RPM Fusion-style repositories available in Universal Blue images.
- `protontricks` and `winetricks` are available as Fedora 44 package names.
- `mangohud.i686` and `gamemode.i686` are included for 32-bit game/runtime coverage.

The Hyprland image adds these Fedora/COPR package names:

- `hyprland`, currently satisfied by the COPR's `hyprland-git` provider
- `xdg-desktop-portal-hyprland`
- `hyprpaper`
- `hyprlock`
- `hypridle`
- `waybar`
- `wofi`
- `sddm`
- `qt6-qtsvg`
- `qt6-qtvirtualkeyboard`
- `qt6-qtmultimedia`
- `qt6-qtdeclarative`
- `qt6-qtwayland`
- `lxpolkit`

If Fedora, RPM Fusion, Bluefin, or the Hyprland COPR changes a package name, the build fails at the `dnf5 install` step. The intended fix is to update the relevant build script and document the naming change here.

## SDDM Astronaut

`bluefin-gaming-hypr-dx` installs the SDDM Astronaut theme from:

```text
https://github.com/Keyitdev/sddm-astronaut-theme
```

The build pins the theme source to:

```text
cd46736b4135a71700d2225d60eb8e85917585eb
```

Astronaut is configured as the default SDDM theme through `/etc/sddm.conf.d/10-bluefin-gaming-hypr-theme.conf`, and the theme metadata is set to `Themes/astronaut.conf`.

## Noctalia

Noctalia is not installed by this image today.

Reason: Noctalia currently builds from source, is in active early/alpha development, and does not have a clean Fedora RPM package source suitable for a stable bootable image. Blocking the OS image build on a fast-moving source build would make the image less reliable.

Manual install path after rebasing to the Hyprland image:

```bash
git clone https://github.com/noctalia-dev/noctalia.git
cd noctalia
sudo dnf install meson gcc-c++ just \
  wayland-devel wayland-protocols-devel \
  libEGL-devel mesa-libGLES-devel \
  freetype-devel fontconfig-devel \
  cairo-devel pango-devel harfbuzz-devel \
  libxkbcommon-devel glib2-devel \
  sdbus-cpp-devel pipewire-devel \
  pam-devel polkit-devel libcurl-devel libwebp-devel librsvg2-devel \
  libqalculate-devel libxml2-devel \
  jemalloc-devel
just configure release "$HOME/.local"
just build release
just install release
```

This keeps Noctalia optional and prevents it from breaking the bootable image.

## Multilib Consistency

`build_files/verify-multilib.sh` enforces that these x86_64 and i686 package versions match after installation:

```text
mesa-filesystem
mesa-dri-drivers
mesa-libgbm
mesa-libEGL
mesa-libGL
mesa-vulkan-drivers
nss
```

This protects Steam and Proton from subtle breakage caused by mismatched 64-bit and 32-bit graphics/security runtime packages.

`build_files/build.sh` first performs a targeted upgrade of the x86_64 Mesa, NSS, and PipeWire packages that commonly collide with newer i686 packages. This lets DNF align the base image's installed x86_64 packages when the Bluefin stable image is slightly behind the Fedora 44 repository metadata, avoiding RPM file conflicts during composition.

The build scripts also verify that the `code` RPM is absent. If VS Code remains installed for any reason, the build fails.

## Why Compose This Into the Image Instead of Layering

Layering Steam, Hyprland, SDDM, and large multilib dependency sets with `rpm-ostree install` works, but it pushes package solving onto every client machine. That makes each workstation responsible for resolving 32-bit Mesa, NSS, Wine, Steam, display-manager, Qt/QML, Hyprland, and portal packages against whatever deployment it currently has.

Composing them in CI is preferable because:

- package resolution happens once, reproducibly, during image build
- failures happen in GitHub Actions before the image reaches your machine
- Mesa/NSS x86_64 and i686 alignment can be verified automatically
- SDDM and GDM service state can be verified automatically
- every machine rebases to the same tested deployment
- rollbacks remain simple because the gaming and desktop stack is part of the deployment
- Bluefin DX updates remain maintainable because the local delta is limited to small build scripts, package lists, and verification checks

This keeps the machine Bluefin-first while making the gaming and optional Hyprland stack first-class.
