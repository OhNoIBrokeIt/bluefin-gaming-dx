# Native App Decisions

## Native packages in the image

These tools should stay native because they need host-level integration with graphics, networking, containers, devices, services, or command-line entrypoints:

- Steam
- Gamescope
- Gamemode
- MangoHud
- Ghostty
- Kitty
- Podman
- Podman Compose
- FreeRDP
- WinBoat
- Slack
- NordVPN
- Proton VPN

Gamescope should remain native because it participates directly in the graphics/session/runtime path. A Flatpak boundary is the wrong place for it.

Podman, Podman Compose, and FreeRDP should remain native for WinBoat. Podman Desktop as a Flatpak is only a GUI/client layer; it does not replace the host container engine, KVM, container networking, sockets, or `/usr/bin/podman` command entrypoints WinBoat expects.

Slack should be native because the Flathub Slack wrapper is unverified and explicitly not affiliated with or supported by Slack Technologies. The image uses Slack's official RPM instead.

VPN clients should be native because routing, DNS, kill switches, split tunneling, NetworkManager integration, and daemon/service behavior are host-level concerns. The image installs both NordVPN and Proton VPN natively.

## Razer/OpenRazer

The Flatpak Razer frontends, such as Polychromatic or RazerGenie, still require native OpenRazer support to control devices reliably.

The native support stack is `openrazer-meta`, which pulls:

- `openrazer-daemon`
- `openrazer-kernel-modules-dkms`
- `python3-openrazer`

Do not add this casually. Unlike normal desktop apps, OpenRazer includes a DKMS kernel module, which can be affected by kernel updates, Secure Boot policy, and image build/kernel compatibility. Treat OpenRazer as a separate deliberate change.

## Ghostty

Ghostty is installed explicitly in the base image. Fedora 44 does not provide it in the standard repositories used by this image, so the build enables the `alternateved/ghostty` COPR.

## After Rebasing

Remove duplicate Flatpaks for packages now provided natively:

```bash
flatpak uninstall com.slack.Slack com.protonvpn.www com.freerdp.FreeRDP
```

NordVPN may require the user to be in the `nordvpn` group:

```bash
sudo usermod -aG nordvpn "$USER"
```

Log out and back in after group changes.
