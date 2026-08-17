# Manual Installation Handbook

> This document is a step-by-step reference for installing each tool manually.
> For one-command automatic installation, use [setup.sh](../setup.sh) instead.

## Preparation

Visit https://github.akams.cn/ and click node speed test to find the fastest
GitHub mirror for China. For example, currently `https://ghfast.top`.
From this point on, any URL containing `https://github.com` should be replaced
with the mirror proxy address.

```bash
export MIRROR_FOR_GITHUB=https://ghfast.top
# Note: use double quotes so variables are expanded
sed -i "s|https://github\.com|${MIRROR_FOR_GITHUB}/https://github.com|g" /tmp/the-target-file
sed -i "s|https://raw\.githubusercontent\.com|${MIRROR_FOR_GITHUB}/https://raw.githubusercontent.com|g" /tmp/the-target-file
```

You can add the `MIRROR_FOR_GITHUB` environment variable to `~/.zshrc` and `~/.bashrc`.

## System

- Download the system source replacement tool:
```bash
curl -sSL https://linuxmirrors.cn/main.sh > /tmp/install_linuxmirrors.sh
```
- `chmod +x` the script.
- Replace system sources:
```bash
sudo bash /tmp/install_linuxmirrors.sh \
  --source mirrors.ustc.edu.cn \
  --protocol http \
  --use-intranet-source false \
  --install-epel true \
  --backup true \
  --upgrade-software false \
  --clean-cache false \
  --ignore-backup-tips
```
- Install base dependencies:
```bash
sudo apt-get update
sudo apt-get install -y net-tools iputils-ping telnet zip unzip
sudo apt-get install -y build-essential binutils gcc make cmake
sudo apt-get install -y git git-core curl openssl libssl-dev wget vim pkg-config autoconf automake g++ ccache tcl-dev libexpat1-dev libpcre3-dev libcap-dev libcap2 bison flex
```

## Docker

- Download the install script:
```bash
curl -fsSL https://get.docker.com > /tmp/install_docker.sh
```
- `chmod +x` and run with sudo (Aliyun mirror):
```bash
sudo sh /tmp/install_docker.sh --mirror Aliyun
```

> **Note**: use `--mirror Aliyun` in China, or `--mirror AzureChinaCloud`.

## Python

Install uv first, then install Python. uv manages virtual environments and package dependencies.

### uv

- Download the install script:
```bash
curl -LsSf https://astral.sh/uv/install.sh > /tmp/install_uv.sh
```
- In China, use sed to replace github.com with the mirror address:
```bash
sed -i "s|https://github\.com|${MIRROR_FOR_GITHUB}/https://github.com|g" /tmp/install_uv.sh
sed -i "s|https://raw\.githubusercontent\.com|${MIRROR_FOR_GITHUB}/https://raw.githubusercontent.com|g" /tmp/install_uv.sh
```
- In China, add environment variables for uv's Python downloads and PyPI mirror:
```bash
export UV_INSTALLER_GHE_BASE_URL=${MIRROR_FOR_GITHUB}/https://github.com
export UV_PYTHON_INSTALL_MIRROR=${MIRROR_FOR_GITHUB}/https://github.com/indygreg/python-build-standalone/releases/download
export UV_DEFAULT_INDEX=https://pypi.tuna.tsinghua.edu.cn/simple
```
- `chmod +x` and run:
```bash
chmod +x /tmp/install_uv.sh
bash /tmp/install_uv.sh
```

### Python

- Install the desired version with uv:
```bash
export PATH="$HOME/.local/bin:$PATH"
uv python install 3.11.14
```

## JavaScript & Node.js & npm

Install nvm to manage Node.js versions, then install the LTS release.

### nvm

- Download the install script:
```bash
curl -fsSL ${MIRROR_FOR_GITHUB}/https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh -o /tmp/install_nvm.sh
```
- In China, replace github.com URLs with the mirror address (same sed commands as above).
- Add environment variables:
```bash
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
```

> **Important**: nvm defaults to `git clone`. If the network is poor (git timeout),
> set `METHOD=script` to force curl/wget downloads:
> ```bash
> METHOD=script bash /tmp/install_nvm.sh
> ```
> In Docker/CI environments, use the script method to avoid git connection issues.

- `chmod +x` and run the install script.

### Install Node.js and npm

```bash
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'
```
- Configure npm:
```bash
npm config set registry https://registry.npmmirror.com
```
- Install global packages:
```bash
npm install -g typescript bun yarn pnpm@latest-11
```

## Rust

Use rustup for Rust version management.

### rustup

- Download the install script:
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/install_rustup.sh
```
- In China, replace github.com URLs with the mirror address.
- Add environment variables:
```bash
export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
export RUSTUP_UPDATE_ROOT=https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup
```
- Create or edit `~/.cargo/config.toml`:
```toml
# Put this in `$HOME/.cargo/config.toml`
[source.crates-io]
registry = "https://github.com/rust-lang/crates.io-index"

# Replace with your preferred mirror
replace-with = 'rsproxy'

# Tsinghua University
[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"

# University of Science and Technology of China
[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"

# Shanghai Jiao Tong University
[source.sjtu]
registry = "https://mirrors.sjtug.sjtu.edu.cn/git/crates.io-index"

# Rustcc community - deprecated!
# [source.rustcc]
# registry = "https://code.aliyun.com/rustcc/crates.io-index.git"

# Rustcc source 1
[source.rustcc]
registry = "git://crates.rustcc.com/crates.io-index"

# Rustcc source 2
[source.rustcc2]
registry = "git://crates.rustcc.cn/crates.io-index"

# ByteDance source
[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"

[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"

[net]
git-fetch-with-cli = true
```

> **Optional mirror sources**: `rsproxy` (ByteDance), `tuna` (Tsinghua),
> `ustc` (USTC), `sjtu` (SJTU), `rustcc`/`rustcc2` (Rustcc community).

- `chmod +x` and run:
```bash
chmod +x /tmp/install_rustup.sh
bash /tmp/install_rustup.sh -y
```

### Rust

```bash
source "$HOME/.cargo/env"
rustup toolchain install stable
rustup default stable
```

## Go

Use gvm to manage Go environments.

### gvm

- Download the install script:
```bash
curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer > /tmp/install_gvm.sh
```
- In China, replace github.com URLs with the mirror address.
- Add environment variables to `~/.zshrc` and `~/.bash_profile`:
```bash
export GO111MODULE=on
export GOPROXY=https://goproxy.cn,direct
export GO_BINARY_BASE_URL=https://mirrors.aliyun.com/golang/
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
export GOROOT_BOOTSTRAP=$GOROOT
```
- `chmod +x` and run the install script.
- **In China**, replace github.com URLs in `~/.gvm/scripts/install`:
```bash
sed -i "s|https://github\.com|${MIRROR_FOR_GITHUB}/https://github.com|g" ~/.gvm/scripts/install
```
- `source ~/.bash_profile`

### Go

```bash
gvm install go1.24.13 --binary
gvm use go1.24.13 --default
```

> **Note**: `--binary` downloads pre-built binaries from `GO_BINARY_BASE_URL`,
> which is faster and does not require a Go compiler to bootstrap.

## Java

Use sdkman for JDK version management.

### sdkman

- Download the install script:
```bash
curl -s "https://get.sdkman.io" > /tmp/install_sdkman.sh
```
- `chmod +x` and run.
- `source "$HOME/.sdkman/bin/sdkman-init.sh"`

> **Note**: sdkman has no official China mirror. Its API server
> `https://api.sdkman.io/2` may be slow in China. Consider installing with a
> proxy available, or use chsrc to switch the sdkman source.

### JDK

```bash
sdk version
sdk ls java
sdk install java 25.0.2-ms
sdk default java 25.0.2-ms
```

## code-server

- Download the install script:
```bash
curl -fsSL https://code-server.dev/install.sh > /tmp/install_code_server.sh
```
- In China, replace github.com URLs with the mirror address.
- `chmod +x` and run.

> **Recommendation**: use `--method standalone` to avoid dependency on system
> package managers:
> ```bash
> bash /tmp/install_code_server.sh --method standalone
> ```

## Others

### chsrc

- Download the install script:
```bash
curl https://chsrc.run/posix > /tmp/install_chsrc.sh
```
- `chmod +x` and run.

> **Note**: chsrc downloads from gitee.com, so it is naturally China-friendly.

### x-cmd

- Download the install script:
```bash
curl https://get.x-cmd.com > /tmp/install_xcmd.sh
```
- `chmod +x` and run.

> **Note**: x-cmd downloads from Aliyun OSS, so it is naturally China-friendly.

---

## Appendix: Notes on the Reference Installer Files

The `refs/install_*.sh` files in this repository are reference copies of the
official upstream installers, **restored to their original URLs with no
hard-coded proxy addresses**. `setup.sh` does not use these copies at runtime;
instead it downloads the latest installer from the official source and applies
mirror replacement dynamically.

**Recommendation**: use the one-command `setup.sh` script. It fetches the
latest installers from official sources and handles mirror replacement on the
fly, so you do not need the old copies under `refs/`.
