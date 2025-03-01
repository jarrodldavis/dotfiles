# dotfiles

> An installer script for [Homebrew], other system dependencies, and important dotfiles

## Prerequisites

- A UNIX-ish operating system, one of:
  - macOS (tested with macOS Sonoma 14.3)
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

## Profiles

During installation, the installer will ask which available profiles
(from `configs/brew/*.Brewfile`) should be selected. The selections are saved per installation in
`configs/brew/selected.txt` and used to determine what [Homebrew Bundle] installs.

The currently available profiles are:

### `core`

- intended for all installations
- contains foundational development utilities and productivity apps
- includes all VSCode extensions

### `host`

- intended for the main host operating system of a machine
- contains virtualization/containerization apps
- includes apps that work best on the host or generally do not need to be duplicated in virtual
  environments

### `neumont`

- intended for academic-specific virtual machines
- contains apps needed specifically for schoolwork

## Options

All installer options are specified as environment variables. Unless otherwise specified, the
presence of an environment variable with a non-empty value enables the corresponding option; the
option is disabled otherwise.

```sh
DOTFILES_SKIP_MAS=1 ./install.sh
```

### `DOTFILES_SKIP_MAS`

On macOS, skip installation of App Store (`mas`) dependencies.

### `DOTFILES_REINSTALL`

Force the removal and reinstallation of Homebrew and any Homebrew-installed system dependencies.

## Maintenance

### Homebrew

[Homebrew Bundle] is used to record the CLI tools, GUI applications, and Visual Studio Code
extensions that should be installed. These system dependencies are recorded in distinct profiles in
the `configs/brew` directory. To record any uninstalled or newly installed system dependencies, update
`configs/brew/Brewfile.{full,new,old}` using `~/.dotfiles/scripts/update-homebrew-bundle.sh`, then
update the appropriate `*.Brewfile` profiles.

### Global `.gitignore`

`configs/gitignore` can be updated to use the latest templates from [`github/gitignore`] using
`~/.dotfiles/scripts/update-global-gitignore.sh`.

[Homebrew]:                     https://brew.sh
[Visual Studio Code]:           https://code.visualstudio.com
[Development Containers]:       https://code.visualstudio.com/docs/remote/containers
[contents of `install.sh`]:     https://github.com/jarrodldavis/dotfiles/raw/main/install.sh
[Homebrew Bundle]:              https://github.com/Homebrew/homebrew-bundle
[`github/gitignore`]:           https://github.com/github/gitignore
