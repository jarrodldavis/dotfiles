# dotfiles

> Important dotfiles, managed by [Dotbot](https://github.com/anishathalye/dotbot/)

## Requirements

| Software | Version    | Reason                    | Installation Notes        | Last Tested With               |
| -------- | ---------- | ------------------------- | ------------------------- | ------------------------------ |
| macOS    | latest     | host operating system     |                           | 10.14.6 (Mojave)               |
| `bash`   | 3.2+       | command line shell        | pre-installed with macOS  | 3.2.57, 5.0.9                  |
| Python   | 2.x or 3.x | Dotbot                    | pre-installed with macOS  | 2.7.16                         |
| Xcode    | latest     | `git` and Homebrew        | alternative: [Xcode CLDT] | [Xcode CLDT] for macOS 10.14.6 |
| `curl`   | latest     | [automatic boostrapping]  | pre-installed with macOS  | 7.54.0                         |

### Xcode Command Line Developer Tools

If you don't have Xcode installed, you can instead use the Xcode Command Line Developer Tools. The installer will
prompt you to install them automatically if Xcode isn't installed, but you can install them manually using
`xcode-select --install`.

## Install

These dotfiles can be installed either automatically or by manually checking out this git repository.

### Automatic Bootstrapping

Run the following command to download and execute the bootstrap script. This will install the Xcode Command Line
Developer Tools, clone this repository to a local directory of your choosing, and run the install script.

```bash
bash -c "$(curl -fsSL https://github.com/jarrodldavis/dotfiles/raw/personal/macos/install/bootstrap)"
```

#### Environment Variables

Instead of responding to the prompts for the local directory and remote git repository, you can use the following
environment variables:

| Key               | Value                                   | Default                                        |
| ----------------- | --------------------------------------- | ---------------------------------------------- |
| `SELECTED_FOLDER` | the local directory to clone to         | `$HOME/.dotfiles`                              |
| `SELECTED_REPO`   | the remote git repository to clone from | `https://github.com/jarrodldavis/dotfiles.git` |

### Manual Installation

- Make sure Xcode or the Xcode Command Line Developer Tools are installed
- Clone this repository to the directory of your choosing (e.g. `~/.dotfiles`)
- In the freshly-cloned directory, run the `./install/core` script

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
$ ./install/core
```

### Environment Variables

For both installation methods, the installer script uses the following environment variables:

| Key               | Value         | Use                                    | Default   |
| ----------------- | ------------- |--------------------------------------- | --------- |
| `SKIP_SHELL_EXIT` | _(any value)_ | skip closing outdated `bash` processes | _(unset)_ |

[automatic boostrapping]: #automatic-bootstrapping
[Xcode CLDT]: #xcode-command-line-developer-tools
