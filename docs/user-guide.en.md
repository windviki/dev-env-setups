# User Guide

## Getting Started

### Basic Usage

```bash
# Clone the project
git clone <repo-url> && cd dev-env-setups

# Install the full development environment (international network)
./setup.sh
```

### China Mainland Users

```bash
# Test proxy speed and choose the best GitHub proxy:
# visit https://github.akams.cn/ to get the fastest node.

# One-command install with default mirrors
./setup.sh --cn

# Use a custom GitHub proxy
./setup.sh --cn --cn-github-proxy https://ghfast.top

# Customize multiple mirrors
./setup.sh --cn \
  --cn-apt-source mirrors.aliyun.com \
  --cn-pypi-index https://mirrors.aliyun.com/pypi/simple/ \
  --cn-cargo-registry tuna
```

### Selective Installation

```bash
# Install only Python and Node.js
./setup.sh --cn --only uv,nvm

# Install everything except Docker and Java
./setup.sh --skip docker,sdkman

# Minimal installation: base + Python + Node.js
./setup.sh --only base,uv,nvm
```

### Preview Mode

```bash
# Preview operations without installing
./setup.sh --cn --only base,uv,nvm --dry-run
```

## Docker Image Build

### Generate a Dockerfile

```bash
# Generate a full development environment Dockerfile
./setup.sh --cn --docker > Dockerfile

# Use a custom base image
./setup.sh --cn --docker --base-image debian:12 > Dockerfile

# Minimal image with Python + Node.js only
./setup.sh --cn --docker --only base,uv,nvm > Dockerfile
```

### Build the Image

```bash
docker build -t dev-env:latest .
docker run -it dev-env:latest bash
```

## Module Details

### base - System Base Environment

Installs the compiler toolchain, network tools, git and other core dependencies. Replaces APT sources via the linuxmirrors tool.

**Requires**: curl  
**Time**: ~2 min

### docker - Docker CE

Installs Docker Engine, CLI, Compose and Buildx through Docker's official script.

**Requires**: base (curl, ca-certificates)  
**Time**: ~3 min  
**Note**: dockerd is not started inside a Docker container.

### uv - Python Environment

Installs the uv Python package manager, then installs Python 3.11 with uv.

**Requires**: base (curl)  
**Time**: ~1 min  
**Locations**: `~/.local/bin/uv`, `~/.local/share/uv/`

### nvm - Node.js Environment

Installs the nvm version manager, Node.js LTS, and global npm packages (typescript, bun, yarn, pnpm).

**Requires**: base (curl, git)  
**Time**: ~3 min  
**Location**: `~/.nvm/`

### rustup - Rust Environment

Installs the rustup toolchain manager and the Rust stable toolchain. Cargo mirror is configured automatically in China mode.

**Requires**: base (curl, build-essential)  
**Time**: ~3 min  
**Locations**: `~/.rustup/`, `~/.cargo/`

### gvm - Go Environment

Installs the gvm Go version manager and Go 1.24.13 in binary mode.

**Requires**: base (git, curl)  
**Time**: ~2 min  
**Location**: `~/.gvm/`

### sdkman - Java Environment

Installs the sdkman JDK manager and Java 25.0.2-ms.

**Requires**: base (unzip, zip, curl)  
**Time**: ~2 min  
**Location**: `~/.sdkman/`

### code-server - Web IDE

Installs code-server (VS Code for the web) and the GitHub Copilot extension.

**Requires**: base (curl)  
**Time**: ~2 min  
**Location**: `~/.local/lib/code-server-<version>/`

### chsrc - Mirror Switcher

Installs chsrc, a cross-platform software source switcher.

**Requires**: base (curl)  
**Time**: <1 min

### xcmd - Shell Tools

Installs the x-cmd shell tool collection.

**Requires**: base (curl)  
**Time**: <1 min  
**Location**: `~/.x-cmd.root/`

### rbenv - Ruby Environment

Installs rbenv + ruby-build and compiles the latest stable Ruby from source.

**Requires**: base (git, curl, toolchain)  
**Time**: ~28 min (first source build; cached by Docker layers afterwards)  
**Location**: `~/.rbenv/`  
**China mirrors**: source tarballs use `MIRROR_RUBY_BUILD`; gems use `MIRROR_RUBYGEMS_SOURCE`

### phpbrew - PHP Environment

Adds the ondrej/php PPA, installs the latest stable PHP with common extensions, Composer, and the phpbrew version manager.

**Requires**: base (curl, apt)  
**Time**: ~3 min  
**Locations**: PHP system directories, Composer in `/usr/local/bin/`, phpbrew in `~/.phpbrew/`  
**China mirrors**: Composer uses the Aliyun mirror; phpbrew source tarballs use `MIRROR_PHP_SOURCE`

### luaenv - Lua Environment

Installs luaenv + lua-build, then builds the latest Lua 5.4.x and LuaRocks.

**Requires**: base (git, curl, toolchain)  
**Time**: ~3 min  
**Location**: `~/.luaenv/`

### rig - R Environment

Installs the r-lib/rig version manager and uses it to install the latest stable R.

**Requires**: base (curl, apt)  
**Time**: ~3 min  
**Location**: rig in system directories; R versions managed by rig

### sqlite3 - SQLite

Installs SQLite3 and development libraries via apt-get.

**Requires**: base (apt)  
**Time**: <1 min

### perl - Perl

Installs Perl and development libraries via apt-get.

**Requires**: base (apt)  
**Time**: <1 min

## Post-install Configuration

After installation, reopen the terminal or run:

```bash
source ~/.bashrc    # bash
source ~/.zshrc     # zsh
```

Some tools need their environment loaded manually before use:

- **nvm**: `nvm use --lts` or reopen the terminal
- **sdkman**: `source "$HOME/.sdkman/bin/sdkman-init.sh"`
- **gvm**: `source "$HOME/.gvm/scripts/gvm"`

## Troubleshooting

### 1. Network Timeout

```bash
# Use China mainland mirror mode
./setup.sh --cn

# Use a custom GitHub proxy (pick the fastest one)
./setup.sh --cn --cn-github-proxy https://<fast-proxy-url>
```

### 2. Insufficient Permissions

```bash
# Ensure the current user has sudo permission
sudo -v

# Or run as root
sudo ./setup.sh --cn
```

### 3. A Module Fails

```bash
# Skip the problematic module
./setup.sh --skip <failed-module>

# Or install that module separately and retry the full run
```

### 4. Running Inside a Docker Container

```bash
# Inside a container, run as root or skip Docker
./setup.sh --skip docker
```

### 5. Verbose Logging

```bash
# Enable bash verbose output
bash -x ./setup.sh --cn --only base,uv 2>&1 | tee logs/install.log
```
