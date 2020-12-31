# dotfiles

> An installer script for [Homebrew], other useful tools, and important dotfiles

## Prerequisites

- A UNIX-ish operating system, one of:
  - macOS (tested with macOS Big Sur 11.1)
  - Debian
  - Ubuntu
  - CentOS
  - Fedora
  - Arch Linux
- Bash, dash, or other POSIX-compatible shell (`/bin/sh`)
- curl (for automatic bootstrapping)
- git (for manual installation)

Bash, dash, and curl are pre-installed on macOS.

## Install

The installer script installs [Homebrew], links important configuration files ("dotfiles") into their respective
places, and installs additional tools using [Homebrew Bundle].

### Automatic Boostrapping

Run the following command to download and execute the bootstrap script.

```sh
/bin/sh -c "$(curl -fsSL https://github.com/jarrodldavis/dotfiles/raw/personal/macos/install.sh)"
```

This will clone this repository to `$HOME/ghq/github.com/jarrodldavis/dotfiles` as part of the installation process.

### Manual Installation

You can manually clone this repository and run the `install.sh` script from that repository.

```sh
git clone https://github.com/jarrodldavis/dotfiles.git
```

```sh
cd dotfiles
```

```sh
./install.sh
```

Alternatively, you can copy the [contents of `install.sh`] to a file on disk and run it using `sh ./install.sh`.

## Options

All installer options are specified as environment variables:

```sh
INSTALLER_EXTRA_VERBOSE=1 ./install.sh
```

### `INSTALLER_EXTRA_VERBOSE`

Output additional information about external commands executed by the script.

### `INSTALLER_CONTINUE_HOMEBREW_BUNDLE`
In Docker-based [Visual Studio Code] [Remote Development] environments ([Development Containers] and [GitHub
Codespaces]), the Homebrew Bundle step is skipped by default to get new environments up and running as quickly as
possible. Use this option to re-run the installer and install all dependencies from Homebrew Bundle.

### `INSTALLER_SKIP_HOMEBREW_BUNDLE`
On macOS and non-Docker Linux environments, you can skip the default Homebrew Bundle step if you want to set up
everything else as quickly as possible.


[Homebrew]:                 https://brew.sh
[Homebrew Bundle]:          https://github.com/Homebrew/homebrew-bundle
[contents of `install.sh`]: https://github.com/jarrodldavis/dotfiles/raw/personal/macos/install.sh
[Visual Studio Code]:       https://code.visualstudio.com
[Remote Development]:       https://code.visualstudio.com/docs/remote/remote-overview
[Development Containers]:   https://code.visualstudio.com/docs/remote/containers
[GitHub Codespaces]:        https://code.visualstudio.com/docs/remote/codespaces
