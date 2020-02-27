# dotfiles

> Important dotfiles, managed by [Dotbot]

## Prerequisites

- macOS (last tested with macOS Catalina 10.15.3)
  - ZSH
  - Python 2.x or 3.x
  - curl (if using automatic bootstrapping)
- Xcode or the Xcode Command Line Developer Tools (if installing manually)

ZSH, Python, and curl are pre-installed with macOS.

Xcode can be downloaded from the Mac App Store, or the Xcode Command Line Developer Tools can be installed by running this command:

```zsh
xcode-select --install
```

## Install

### Automatic Boostrapping

Run the following command to download and execute the bootstrap script. This will install [Homebrew] (along with the Xcode Command Line Developer Tools), then use [`ghq`] the clone the appropriate `dotfiles` repository.

```zsh
zsh -c "$(curl -fsSL https://github.com/jarrodldavis/dotfiles/raw/personal/macos/install)"
```

### Manual Installation

You can manually clone this repository and run the `install` script from that repository &ndash; but note that the installation script will disregard your local repository path and use `ghq` to clone the repository anyway.

### Username Detection

The repository will be selected based on [your git configuration or macOS account username][username-search].

If you need to override the username detected by `ghq`, you can (temporarily) set the `GITHUB_USER` environment variable before invoking the installation script:

```zsh
GITHUB_USER=jarrodldavis zsh -c "$(curl -fsSL https://github.com/jarrodldavis/dotfiles/raw/personal/macos/install)"
```

[dotbot]: https://github.com/anishathalye
[homebrew]: https://brew.sh
[`ghq`]: https://github.com/x-motemen/ghq
[username-search]: https://github.com/x-motemen/ghq/blob/60adea92502f6d99e29c92644d8f1256682424ec/url.go#L112-L151
