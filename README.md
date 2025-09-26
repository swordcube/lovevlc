<a href="https://github.com/swordcube/lovevlc">
    <img src="./assets/logo.png" align="center" />
</a>

# lovevlc

![](https://img.shields.io/github/repo-size/swordcube/lovevlc) ![](https://badgen.net/github/open-issues/swordcube/lovevlc) ![](https://badgen.net/badge/license/MIT/green)

A lightweight LÖVE library for extending video playback functionality via [libVLC](https://www.videolan.org/vlc/libvlc.html)

> [!NOTE]  
> This library only works for LÖVE 12.0+, you can download it from the main [LÖVE GitHub Repository](https://github.com/love2d/love) [Actions](https://github.com/love2d/love/actions).
> 
> Download the latest *successful* build, and find the appropriate version for your OS and architecture (`love-windows-x64` for example)

### Supported Platforms

- **Windows** (x86_64 only)
- **Linux**

### Planned Platforms

- **macOS** (x86_64 and arm64 only)

### Dependencies

On ***Linux*** you need to install `vlc` from your distro's package manager.

<details>
<summary>Commands list</summary>

#### Debian based distributions ([Debian](https://debian.org)):
```bash
sudo apt-get install vlc libvlc-dev libvlccore-dev vlc-bin
```

#### Arch based distributions ([Arch](https://archlinux.org)):
```bash
sudo pacman -S vlc
```

#### Fedora based distributions ([Fedora](https://getfedora.org)):
```bash
sudo dnf install vlc
```

#### Red Hat Enterprise Linux (RHEL):
```bash
sudo dnf install epel-release
sudo dnf install vlc
```

#### openSUSE based distributions ([openSUSE](https://www.opensuse.org)):
```bash
sudo zypper install vlc
```

#### Gentoo based distributions ([Gentoo](https://gentoo.org)):
```bash
sudo emerge media-video/vlc
```

#### Slackware based distributions ([Slackware](https://www.slackware.com)):
```bash
sudo slackpkg install vlc
```

#### Void Linux ([Void Linux](https://voidlinux.org)):
```bash
sudo xbps-install -S vlc
```

#### NixOS ([NixOS](https://nixos.org)):
```bash
nix-env -iA nixpkgs.vlc
```