# dotfiles

> Important dotfiles, managed by [Dotbot](https://github.com/anishathalye/dotbot/)

## Requirements

- macOS (currently tested on 10.14 Mojave)
- `bash` (the one pre-installed in macOS should work fine for initial usage)
- Xcode or Xcode Command Line Developer Tools (for initial `git` usage and Homebrew package installation)

## Install

### Automatic Bootstrapping

Run the following command to download and execute the bootstrap script. This will install the Xcode Command Line
Developer Tools, clone this repository to a local directory of your choosing, and run the install script.

```bash
exec bash -c "$(curl -fsSL https://github.com/jarrodldavis/dotfiles/raw/personal/macos/scripts/bootstrap)"
```

### Manual Installation

- Make sure Xcode or the Xcode Command Line Tools are installed
- Clone this repository to the directory of your choosing (e.g. `~/.dotfiles`)
- In the freshly-cloned directory, run the `./install` script

Example:

```bash
$ xcode-select --install
xcode-select: note: install requested for command line developer tools
$ git clone https://github.com/jarrodldavis/dotfiles.git .dotfiles
Cloning into '.dotfiles'...
remote: Enumerating objects: 117, done.
remote: Counting objects: 100% (117/117), done.
remote: Compressing objects: 100% (72/72), done.
remote: Total 1228 (delta 66), reused 88 (delta 43), pack-reused 1111
Receiving objects: 100% (1228/1228), 354.84 KiB | 2.07 MiB/s, done.
Resolving deltas: 100% (758/758), done.
$ cd .dotfiles
$ ./install
```
