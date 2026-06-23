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
- installs native Steam, Ghostty, Gamescope, Gamemode, MangoHud, Vulkan tools, Protontricks, Winetricks, Wine runtime packages, Kitty, NordVPN, Proton VPN, Slack, WinBoat, and Steam/Proton multilib dependencies
- removes the Visual Studio Code RPM package `code`

### bluefin-gaming-hypr-dx

Base image:

```text
ghcr.io/<user>/bluefin-gaming-dx:latest
```

Use this image when Hyprland should be the primary daily-driver session while GNOME remains installed as a fallback and troubleshooting session.

This variant keeps everything from `bluefin-gaming-dx` and additionally:

- installs Hyprland
- installs Hyprland GUI utilities and Qt support
- installs `xdg-desktop-portal-hyprland`
- installs Noctalia Shell from Terra
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

Noctalia Shell is resolved from the Terra Fedora repository. The Hyprland image enables Terra only in the Hyprland variant and installs the packaged `noctalia-shell` RPM instead of building Noctalia from source during image composition.

## Gaming Packages

The base gaming image installs:

- Native Steam RPM package
- Ghostty terminal
- Gamescope
- Gamemode
- MangoHud
- Vulkan tools
- Kitty terminal
- NordVPN official RPM
- Proton VPN official Fedora GNOME package
- Slack official RPM
- WinBoat with Podman Compose and FreeRDP runtime support
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
- `ghostty` is resolved from the `alternateved/ghostty` COPR because Fedora 44 does not currently provide it in the standard repositories used by this image.
- `protontricks` and `winetricks` are available as Fedora 44 package names.
- `mangohud.i686` and `gamemode.i686` are included for 32-bit game/runtime coverage.
- `ghostty`, `kitty`, `freerdp`, `podman`, and `podman-compose` are Fedora package names used to support terminal workflows and WinBoat's Podman backend.
- `gnome-shell-extension-appindicator` and `gnome-extensions-app` are included so Slack and Proton VPN can use GNOME tray/AppIndicator support.

WinBoat is not installed from Fedora repositories. The GNOME image downloads the upstream Fedora RPM release asset from:

```text
https://github.com/TibixDev/winboat/releases/download/v0.9.0/winboat-0.9.0-x86_64.rpm
```

The build pins that asset with this SHA-256 digest:

```text
64338d6d61faf761a441fc59d3129aa346ce65905e12af329a08dff40308f5f7
```

WinBoat remains beta software and requires KVM-enabled hardware. The image provides the application, Podman Compose, and FreeRDP 3.x; user-specific Windows setup still happens after first launch.

Slack is installed from Slack's official Linux RPM download rather than the unverified Flathub wrapper:

```text
https://downloads.slack-edge.com/desktop-releases/linux/x64/4.50.136/slack-4.50.136-0.1.el8.x86_64.rpm
```

The build pins that asset with this SHA-256 digest:

```text
efe415e8f2bddf526044dfb0edad8b06bb4053cd8cd42951e2893cfafc818ad2
```

NordVPN is installed from NordVPN's official RPM repository asset:

```text
https://repo.nordvpn.com/yum/nordvpn/centos/x86_64/Packages/n/nordvpn-5.1.0-1.x86_64.rpm
```

The build pins that asset with this SHA-256 digest:

```text
a0e8c7534f6b15968c15b2d6aa4a8541f8fcb0c7ee9e40691841525c6ab8933e
```

Proton VPN is installed from Proton's official Fedora 44 stable repository. The repository package is:

```text
https://repo.protonvpn.com/fedora-44-stable/protonvpn-stable-release/protonvpn-stable-release-1.0.4-1.noarch.rpm
```

The build pins that repository package with this SHA-256 digest:

```text
c3a4ca5943b142997597c1e1248226cfafbabe914c89895e0a8b2890e422657c
```

Proton documents Fedora 44 GNOME as the currently supported Fedora target for its GUI app.

The Hyprland image adds these Fedora/COPR package names:

- `hyprland`, currently satisfied by the COPR's `hyprland-git` provider
- `hyprland-guiutils`
- `hyprland-qt-support`
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
- `noctalia-shell`, from Terra

If Fedora, RPM Fusion, Bluefin, Terra, or the Hyprland COPR changes a package name, the build fails at the `dnf5 install` step. The intended fix is to update the relevant build script and document the naming change here.

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

`bluefin-gaming-hypr-dx` installs `noctalia-shell` from Terra during image composition.

The image intentionally consumes the Terra RPM rather than building Noctalia from source. That keeps the Hyprland image reproducible while still making Noctalia part of the bootable deployment.

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

`build_files/build.sh` first performs a targeted upgrade of the x86_64 Mesa, NSS, and PipeWire packages that commonly collide with newer i686 packages. This lets DNF align the base image's installed x86_64 packages when the Bluefin stable image is slightly behind the Fedora 44 repository metadata, avoiding RPM file conflicts during composition. The same script verifies that Ghostty, Kitty, NordVPN, Proton VPN, Slack, WinBoat, Podman Compose, and FreeRDP entrypoints are present after installation.

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
