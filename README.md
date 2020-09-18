# dotfiles

> Important dotfiles, managed by [Dotbot]

## Prerequisites

- macOS (last tested with macOS Catalina 10.15.6)
  - Bash
  - Python 2.x or 3.x
  - curl

Bash, Python, and curl are pre-installed with macOS.

## Install

The installer script uses [Dotbot] to install [Homebrew] (along with other tools) and link important configuration files ("dotfiles") into their respective places.

### Automatic Boostrapping

Run the following command to download and execute the bootstrap script.

```bash
bash -c "$(curl -fsSL https://github.com/jarrodldavis/dotfiles/raw/personal/macos/install)"
```

This will clone this repository to `$HOME/ghq/github.com/jarrodldavis/dotfiles`, then run Dotbot as usual.

### Manual Installation

You can manually clone this repository and run the `install` script from that repository.

```bash
git clone https://github.com/jarrodldavis/dotfiles.git
cd dotfiles
./install
```


[Dotbot]: https://github.com/anishathalye/dotbot
[Homebrew]: https://brew.sh
