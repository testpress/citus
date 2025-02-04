#!/bin/bash

set -e  # Exit on any error

unknown_os() {
  echo "Unsupported Ubuntu version. Contact https://www.citusdata.com/about/contact_us."
  exit 1
}

arch_check() {
  if [ "$(uname -m)" != "x86_64" ]; then
    echo "Citus repository supports only x86_64 architecture."
    exit 1
  fi
}

install_package() {
  local pkg="$1"
  if ! dpkg -s "$pkg" &>/dev/null; then
    echo "Installing $pkg..."
    apt-get install -y --no-install-recommends "$pkg" &>/dev/null
  fi
}

detect_ubuntu_codename() {
  source /etc/os-release
  case "$VERSION_CODENAME" in
    noble)
      codename="jammy"  # Map noble to jammy
      ;;
    focal|jammy)
      codename="$VERSION_CODENAME"
      ;;
    *)
      unknown_os
      ;;
  esac
  echo "Detected Ubuntu version: $codename"
}

setup_citus_repository() {
  repo_name="community"
  apt_source_path="/etc/apt/sources.list.d/citusdata_${repo_name}.list"
  gpg_key_url="https://repos.citusdata.com/${repo_name}/gpgkey"
  apt_config_url="https://repos.citusdata.com/${repo_name}/config_file.list?os=ubuntu&dist=${codename}&source=script"

  echo "Setting up Citus repository..."
  curl -fsSL "$apt_config_url" -o "$apt_source_path" || unknown_os
  curl -fsSL "$gpg_key_url" | gpg --dearmor > /etc/apt/keyrings/citusdata_${repo_name}-archive-keyring.gpg
  chmod 0644 /etc/apt/keyrings/citusdata_${repo_name}-archive-keyring.gpg
}

main() {
  apt-get update -qq
  arch_check
  install_package "curl"
  install_package "gnupg"
  install_package "apt-transport-https"
  detect_ubuntu_codename
  setup_citus_repository
  apt-get update -qq
  echo "Citus repository is now set up. You can install packages."
}

main
