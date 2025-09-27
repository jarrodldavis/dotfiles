# dotfiles

> An installer script for [Homebrew], other system dependencies, and important configuration files

## Prerequisites

- A UNIX-ish operating system, one of:
  - macOS
    - tested with Sequoia 15.6
  - Debian
    - tested with `bookworm` in [Visual Studio Code]'s [Development Containers]
    - tested with `bookworm` in [Windows Subsystem for Linux] (WSL)
  - Others (untested)
- dash or other POSIX-compatible shell (`/bin/sh`)
- Bash (for [Homebrew] installation)
- Zsh (for additional installation scripts)
- curl (for automatic bootstrapping)
- git (for manual installation)
- On Linux, all [Homebrew system requirements]

`/bin/sh`, Bash, Zsh, and curl are pre-installed on macOS.

## Install

The installer script installs [Homebrew], clones this repository to `~/.dotfiles`, links important
configuration files ("dotfiles") into their respective locations, and installs additional system
dependencies using [Homebrew Bundle].

### Automatic Boostrapping

Run the following command to download and execute the bootstrap script.

```sh
/bin/sh -s < <(curl -fsSL https://github.com/jarrodldavis/dotfiles/raw/main/install.sh)
```

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

Alternatively, you can copy the [contents of `install.sh`] to a file on disk and run it using
`sh ./install.sh`.

> [!IMPORTANT]
> The installer script _always_ clones this repository to `~/.dotfiles`, even if it was
manually cloned to a different location.

## Options

All installer options are specified as environment variables. Unless otherwise specified, the
presence of an environment variable with a non-empty value enables the corresponding option; the
option is disabled otherwise.

```sh
DOTFILES_REINSTALL=1 DOTFILES_SKIP_MAS=1 ./install.sh
```

> [!WARNING]
> The installer script only checks for **any non-empty value** in an environment variable, so even
> typically "falsy" values like `0` or `NO` will enable the option.

### `DOTFILES_REINSTALL`

Force the removal and reinstallation of Homebrew and all Homebrew Formulae.

Homebrew Casks are not fully removed, but will be adopted or overwritten upon reinstallation.
Visual Studio Code extensions will not be removed, but any missing extensions will be reinstalled.

### `DOTFILES_SKIP_MAS`

On macOS, skip installation of Mac App Store (`mas`) dependencies.

## Maintenance

> [!NOTE]
> These maintenance actions are performed automatically before each commit using a git pre-commit
> hook. Due to dependency requirements, some updates are only performed on macOS.

### Homebrew

[Homebrew Bundle] is used to record the CLI tools (Homebrew Formulae), GUI applications
(Homebrew Casks), and Visual Studio Code extensions that should be installed. To record the
installation or removal of these system dependencies, update `configs/Brewfile` using
`~/.dotfiles/scripts/update-homebrew-bundle.sh`.

### Global `.gitignore`

`configs/gitignore` can be updated to use the latest templates from [`github/gitignore`] using
`~/.dotfiles/scripts/update-global-gitignore.sh`. This script can only run on macOS due to
dependency requirements.

[Homebrew]:                     https://brew.sh
[Visual Studio Code]:           https://code.visualstudio.com
[Development Containers]:       https://code.visualstudio.com/docs/remote/containers
[Windows Subsystem for Linux]:  https://learn.microsoft.com/en-us/windows/wsl/
[Homebrew system requirements]: https://docs.brew.sh/Homebrew-on-Linux#requirements
[contents of `install.sh`]:     https://github.com/jarrodldavis/dotfiles/raw/main/install.sh
[Homebrew Bundle]:              https://docs.brew.sh/Brew-Bundle-and-Brewfile
[`github/gitignore`]:           https://github.com/github/gitignore
