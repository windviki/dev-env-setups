# Design Document

## Architecture Overview

dev-env-setups is a one-command Linux development environment installer. `setup.sh` acts as the single entry point and drives per-module install functions.

## Core Design

### 1. Entry Script (`setup.sh`)

`setup.sh` is the only script users need to run. It is responsible for:

- **Argument parsing**: handles `--only`, `--skip`, `--cn`, `--docker` and other CLI options.
- **Module selection**: starts with `ALL_MODULES`, filters by `--only`, then removes modules listed in `--skip`.
- **Mode dispatch**: decides between local installation and Dockerfile generation based on `--docker`.
- **Source loading**: loads `lib/common.sh`, `lib/mirrors.sh`, and `lib/modules.sh`.

### 2. Mirror Mechanism

The project uses 4 categories and 14 kinds of mirrors, each with a different technical approach:

#### Category 1: GitHub Proxy (URL prefix rewriting)

**Principle**: prepend a proxy prefix to the original GitHub URL, for example:

```
Original: https://github.com/user/repo
Proxied:  https://ghfast.top/https://github.com/user/repo
```

**Implementation**: after downloading an installer script, apply `sed` to replace
`github.com` and `raw.githubusercontent.com` globally.

```bash
sed "s|https://github\.com|${MIRROR_FOR_GITHUB}/https://github.com|g"
sed "s|https://raw\.githubusercontent\.com|${MIRROR_FOR_GITHUB}/https://raw.githubusercontent.com|g"
```

**Affected modules**: nvm, rustup, gvm, code-server, uv, rbenv, phpbrew, luaenv, rig (9 modules).

**Default proxy service**: `https://ghfast.top`, a publicly available GitHub proxy.

> Users can visit https://github.akams.cn/ to benchmark proxy nodes, then override
> the proxy with `--cn-github-proxy` or `MIRROR_FOR_GITHUB`.

#### Category 2: System Package Mirrors

##### APT Source Mirror
- **Tool**: [LinuxMirrors](https://linuxmirrors.cn) script
- **Mechanism**: replaces the contents of `/etc/apt/sources.list`
- **Default source**: `mirrors.ustc.edu.cn`
- **Implementation**: `sudo bash install_linuxmirrors.sh --source ${MIRROR_APT_SOURCE}`

##### Docker CE Mirror
- **Tool**: Docker's official install script with the built-in `--mirror` parameter
- **Supported values**: `Aliyun`, `AzureChinaCloud`
- **Implementation**: `sh install_docker.sh --mirror ${MIRROR_DOCKER}`

#### Category 3: Package Manager Mirrors (environment variables)

| Package Manager | Mirror Variable | Configuration |
|-----------------|-----------------|---------------|
| **uv (PyPI)** | `UV_DEFAULT_INDEX` | environment variable |
| **npm** | `registry` | `npm config set registry` command |
| **Node.js binaries** | `NVM_NODEJS_ORG_MIRROR` | environment variable |
| **uv Python SDK** | `UV_PYTHON_INSTALL_MIRROR` | environment variable |
| **Go modules** | `GOPROXY` | environment variable |
| **Go binaries** | `GO_BINARY_BASE_URL` | environment variable |

#### Category 4: Toolchain Distribution Mirrors (environment variables + config files)

##### Rust Ecosystem
- **Rustup**: `RUSTUP_DIST_SERVER` + `RUSTUP_UPDATE_ROOT` environment variables
- **Cargo registries**: configured in `~/.cargo/config.toml` via `replace-with`

```toml
[source.crates-io]
replace-with = 'rsproxy'  # can be switched to tuna/ustc/sjtu/rustcc

[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"
```

Supported Cargo mirror sources: `rsproxy`, `tuna`, `ustc`, `sjtu`, `rustcc`, `rustcc2`.

##### Ruby Ecosystem
- **Ruby source tarballs**: `RUBY_BUILD_MIRROR_URL` environment variable (used by ruby-build)
- **RubyGems**: `gem sources` + `bundle config` commands

##### PHP Ecosystem
- **PHP source tarballs**: phpbrew `--old-src-url` compile parameter. (Current install path uses the ondrej PPA pre-built packages; phpbrew is installed as an optional version manager.)

### 3. Mirror Precedence

When `--cn` is used together with specific mirror overrides:

1. `--cn` activates all mirror defaults.
2. Specific `--cn-xxx` options override the corresponding defaults.
3. Environment variables `MIRROR_XXX` can override them further.

Priority: command-line options > environment variables > script defaults.

### 4. Installation Modes

#### Mode A: Local Installation (default)

Runs directly in the current shell. The script:

1. Detects the OS type and version.
2. Detects whether it is running inside a Docker container (to decide whether sudo is needed).
3. Executes each module install function in order.
4. Writes shell profile snippets (`.bashrc`, `.zshrc`, `.profile`, etc.).

#### Mode B: Dockerfile Generation (`--docker`)

Generates a self-contained Dockerfile:

1. `FROM ${BASE_IMAGE}` specifies the base image.
2. Installs base system dependencies.
3. `COPY . /opt/dev-env-setups` copies the project.
4. `RUN bash setup.sh --cn --only "module list"` installs modules inside the image.
5. `ENV PATH=...` sets environment variables.

Users can customize the generated Dockerfile before `docker build`.

### 5. Module Dependencies

- The `base` module should be installed first (provides git, curl, build-essential, etc.).
- `docker` depends on ca-certificates and curl from `base`.
- All language modules depend on curl, git and build-essential from `base`.
- `sdkman` requires unzip, zip, tar, curl, sed from `base`.
- `code-server` can fall back to the npm-installed Node.js.
- `chsrc` and `xcmd` are completely independent.

### 6. Fault Tolerance

- A failed module never stops subsequent modules.
- Docker daemon is not started inside a Docker container.
- Language SDK installation failures are downgraded to warnings.
- Non-root users automatically use sudo; inside Docker containers commands run directly.

## Extending with a New Module

Adding a new module requires 3 steps:

1. Add it to `ALL_MODULES` and `MODULE_DESC` in `lib/modules.sh`.
2. Implement `install_<module>()` (signature: `install_xxx(use_cn)`).
3. Add a case branch in `run_install()` in `setup.sh`.
