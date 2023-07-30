# dotfiles

> An installer script for [Homebrew], other system dependencies, and important dotfiles

## Prerequisites

- A UNIX-ish operating system, one of:
  - macOS (tested with macOS Ventura 13.5)
  - Debian (tested with `bookworm` in [Visual Studio Code]'s [Development Containers])
  - Others (untested)
- Bash (for [Homebrew] installation)
- dash or other POSIX-compatible shell (`/bin/sh`)
- curl (for automatic bootstrapping)
- git (for manual installation)

Bash, dash, and curl are pre-installed on macOS.

## Install

The installer script installs [Homebrew], links important configuration files ("dotfiles") into
their respective places, and installs additional system dependencies using [Homebrew Bundle].

### Automatic Boostrapping

Run the following command to download and execute the bootstrap script.

```sh
/bin/sh -c "$(curl -fsSL https://github.com/jarrodldavis/dotfiles/raw/main/install.sh)"
```

This will clone this repository to `~/.dotfiles` as part of the installation process.

### Manual Installation

You can manually clone this repository and run the `install.sh` script from that repository.

```sh
git clone https://github.com/jarrodldavis/dotfiles.git ~/.dotfiles
```

```sh
cd ~/.dotfiles
```

```sh
./install.sh
```

Alternatively, you can copy the [contents of `install.sh`] to a file on disk and run it using `sh
./install.sh`.

## Options

All installer options are specified as environment variables. Unless otherwise specified, the
presence of an environment variable with a non-empty value enables the corresponding option; the
option is disabled otherwise.

```sh
DOTFILES_SKIP_MAS=1 ./install.sh
```

### `DOTFILES_SKIP_MAS`

On macOS, skip installation of App Store (`mas`) dependencies.

## Maintenance

### Homebrew

[Homebrew Bundle] is used to record the CLI tools, GUI applications, and Visual Studio Code
extensions that should be installed. To record the installation or removal of these system
dependencies, update `configs/Brewfile` and `configs/Brewfile.lock.json` using
`~/.dotfiles/scripts/update-homebrew-bundle.sh`.

### Global `.gitignore`

`configs/gitignore` can be updated to use the latest templates from [`github/gitignore`] using
`~/.dotfiles/scripts/update-global-gitignore.sh`.

[Homebrew]:                     https://brew.sh
[Visual Studio Code]:           https://code.visualstudio.com
[Development Containers]:       https://code.visualstudio.com/docs/remote/containers
[contents of `install.sh`]:     https://github.com/jarrodldavis/dotfiles/raw/main/install.sh
[Homebrew Bundle]:              https://github.com/Homebrew/homebrew-bundle
[`github/gitignore`]:           https://github.com/github/gitignore
