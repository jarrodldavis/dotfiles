#!/bin/zsh
set -euo pipefail

LOG_TEMPLATE='\033[1;%sm%b\033[0m\033[1;%sm%s\033[0m\n'

function TRAPZERR() {
    printf "$LOG_TEMPLATE" 31 '==> ' 39 "Failing to install package."
}

owner="${1:-}"
repo="${2:-}"

if [[ -z "$owner" ]]; then
  printf "$LOG_TEMPLATE" 31 '==> ' 39 "Owner argument is required."
  exit 1
fi

if [[ -z "$repo" ]]; then
  printf "$LOG_TEMPLATE" 31 '==> ' 39 "Repo argument is required."
  exit 1
fi


printf "$LOG_TEMPLATE" 35 '==> ' 39 "Fetching latest release from \`$owner/$repo\`..."

release="$(curl -fL "https://api.github.com/repos/$owner/$repo/releases/latest")"

function parse_release() {
    # `jq` doesn't like `$release` passed as input but is fine with it passed as a JSON arg.
    jq \
        --null-input \
        --raw-output \
        --argjson release "$release" \
        --arg file_name "${file_name:-}" \
        "$1"
}

version="$(parse_release '$release.tag_name')"
published="$(parse_release '$release.published_at')"
printf "$LOG_TEMPLATE" 36 '==> ' 39 "$version published at $published"

printf "$LOG_TEMPLATE" 35 '==> ' 39 'Resolving Debian archive asset...'

pkg_name="${3:-$repo}"
printf "$LOG_TEMPLATE" 34 '==> ' 39 "Package: $pkg_name"

version_specifier="${version#v}"
printf "$LOG_TEMPLATE" 34 '==> ' 39 "Version: $version_specifier"

arch="$(dpkg-architecture -q DEB_BUILD_ARCH)"
printf "$LOG_TEMPLATE" 34 '==> ' 39 "Architecture: $arch"

file_name="${pkg_name}_${version_specifier}_${arch}.deb"
printf "$LOG_TEMPLATE" 34 '==> ' 39 "Filename: $file_name"

jq_program=$(
<<"EOF"
      [ $release.assets[] | select(.name == $file_name) ]
    | if length > 1 then
        error("more than one asset found")
      elif length < 1 then
        error("no asset found")
      else
        .[0]
      end
    | .browser_download_url
EOF
)

download_url="$(parse_release "$jq_program")"

printf "$LOG_TEMPLATE" 36 '==> ' 39 "$download_url"

printf "$LOG_TEMPLATE" 35 '==> ' 39 'Downloading Debian archive...'
download_path="$(mktemp --suffix="-$pkg_name.deb")"
curl -fL -o "$download_path" "$download_url"
printf "$LOG_TEMPLATE" 36 '==> ' 39 "$download_path"

printf "$LOG_TEMPLATE" 35 '==> ' 39 'Installing Debian package...'
sudo apt-get install "$download_path"

printf "$LOG_TEMPLATE" 32 '==> ' 39 "Successfully installed \`$pkg_name\`!"
