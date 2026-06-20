# bluefin-gaming-dx

`bluefin-gaming-dx` is a Universal Blue image-template style custom image derived from:

```text
ghcr.io/ublue-os/bluefin-dx-nvidia-open:stable
```

The goal is to keep Bluefin DX GNOME, the Bluefin developer experience, and NVIDIA Open driver compatibility intact while adding native Steam and common gaming runtime packages at image build time.

This is not a Bazzite rebase. It stays Bluefin-derived and does not install Hyprland or switch desktop environments.

## What This Adds

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

## What This Preserves

- GNOME from Bluefin DX
- Bluefin DX developer tooling
- NVIDIA Open driver compatibility from `bluefin-dx-nvidia-open`
- HDR support provided by the base image stack
- Gamescope support
- Bluefin update cadence, because the image derives directly from the current Bluefin stable base

## What This Removes

- `code` Visual Studio Code RPM package

This image is intended for terminal-first development workflows using tools such as Claude Code, Codex, Python, TypeScript, GitHub, and Docker. VS Code is not required and is removed during image composition if the base image includes it.

## Repository Structure

```text
bluefin-gaming-dx/
├── .github/
│   └── workflows/
│       └── build.yml
├── build_files/
│   ├── build.sh
│   └── verify-multilib.sh
├── .gitignore
├── Containerfile
├── Justfile
└── README.md
```

## How to Fork

1. Create a new GitHub repository named `bluefin-gaming-dx`.
2. Copy these files into that repository.
3. Enable GitHub Actions for the repository.
4. In repository settings, make sure GitHub Actions has permission to write packages.
5. Optional but recommended: create a cosign key pair and add the private key as the `SIGNING_SECRET` repository secret.

Generate a signing key:

```bash
COSIGN_PASSWORD="" cosign generate-key-pair
```

Add the private key as a GitHub Actions secret named `SIGNING_SECRET`. Do not commit `cosign.key`.

The workflow still builds and publishes without `SIGNING_SECRET`; it only skips signing.

## How to Build Locally

From the repository root:

```bash
podman build --pull=newer --tag bluefin-gaming-dx:latest .
```

Or with `just`:

```bash
just build
```

## How to Publish

Push the repository to GitHub on the default branch. The workflow builds and publishes:

```text
ghcr.io/<user>/bluefin-gaming-dx:latest
ghcr.io/<user>/bluefin-gaming-dx:stable
ghcr.io/<user>/bluefin-gaming-dx:<YYYYMMDD>
ghcr.io/<user>/bluefin-gaming-dx:latest.<YYYYMMDD>
```

Pull requests build the image but do not publish it.

## How to Rebase

Replace `<user>` with your GitHub username or organization:

```bash
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/<user>/bluefin-gaming-dx:latest
```

Reboot after the rebase:

```bash
systemctl reboot
```

If you do not configure signing, use the unsigned image transport:

```bash
sudo rpm-ostree rebase ostree-unverified-image:docker://ghcr.io/<user>/bluefin-gaming-dx:latest
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

## Fedora 44 Package Notes

The Fedora 44 package names used here are intentionally plain RPM package names resolved during image composition:

- `gamemode` is the Fedora package. There is no Fedora 44 package named `game-performance` in the standard Fedora repositories used for this image.
- `steam` is installed as a native RPM package from the enabled gaming/RPM Fusion-style repositories available in Universal Blue images.
- `protontricks` and `winetricks` are available as Fedora 44 package names.
- `mangohud.i686` and `gamemode.i686` are included for 32-bit game/runtime coverage.

If Fedora, RPM Fusion, or Bluefin changes a package name, the build fails at the `dnf5 install` step. The intended fix is to update `build_files/build.sh` and document the naming change here.

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

The same build script also verifies that the `code` RPM is absent before cleanup. If VS Code remains installed for any reason, the build fails.

## Why Compose This Into the Image Instead of Layering

Layering Steam and large multilib dependency sets with `rpm-ostree install` works, but it pushes package solving onto every client machine. That makes each workstation responsible for resolving 32-bit Mesa, NSS, Wine, Steam, and runtime packages against whatever deployment it currently has.

Composing them in CI is preferable because:

- package resolution happens once, reproducibly, during image build
- failures happen in GitHub Actions before the image reaches your machine
- Mesa/NSS x86_64 and i686 alignment can be verified automatically
- every machine rebases to the same tested deployment
- rollbacks remain simple because the gaming stack is part of the deployment, not a pile of local layered state
- Bluefin DX updates remain maintainable because the only local delta is this small package list and verification script

This keeps the machine Bluefin-first while making the gaming stack first-class.
