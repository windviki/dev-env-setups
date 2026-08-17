# dev-env-setups

One-command development environment setup for Linux, designed to be China-mainland friendly with automatic mirror configuration.

[中文文档](README.zh-CN.md)

## Features

- **One command** installs 16 development modules: Python, Node.js, Rust, Go, Java, Ruby, PHP, Lua, R, SQLite, Perl, Docker, code-server, and more.
- **China mirror support** (`--cn`) with 14 configurable mirrors for GitHub, APT, PyPI, npm, Rust, Go, RubyGems, PHP, etc.
- **Local install mode** or **Dockerfile generation mode** (`--docker`).
- **Flexible module selection** with `--only` / `--skip`.
- **Proxy speed detection** helper (`lib/proxy-test.sh`).

## Quick Start

```bash
# Install everything (international network)
./setup.sh

# Install everything (China mainland network, automatic mirrors)
./setup.sh --cn

# Install only Python + Node.js
./setup.sh --cn --only uv,nvm

# Install everything except Docker
./setup.sh --skip docker

# Generate a Dockerfile instead of installing locally
./setup.sh --cn --docker > Dockerfile
docker build -t dev-env:latest .
```

## Requirements

- **OS**: Ubuntu 22.04+ / Debian 11+ / CentOS 7+ / Fedora / Rocky Linux
- **Software**: bash, curl, wget, git
- **Permissions**: sudo or root

## Modules

| Module | Description | Installs |
|--------|-------------|----------|
| `base` | System base environment | build-essential, git, curl, toolchain, APT mirror setup |
| `docker` | Docker CE | Docker Engine, CLI, Compose, Buildx |
| `uv` | Python environment | uv package manager + Python 3.11 |
| `nvm` | Node.js environment | nvm version manager + Node.js LTS + global npm packages |
| `rustup` | Rust environment | rustup toolchain manager + Rust stable |
| `gvm` | Go environment | gvm version manager + Go 1.24.13 (binary) |
| `sdkman` | Java environment | sdkman JDK manager + Java 25.0.2-ms |
| `code-server` | Web IDE | code-server + GitHub Copilot extension |
| `chsrc` | Mirror switcher | chsrc software source switcher |
| `xcmd` | Shell tools | x-cmd shell tool collection |
| `rbenv` | Ruby environment | rbenv + ruby-build + latest stable Ruby (source build) |
| `phpbrew` | PHP environment | ondrej/php PPA PHP + Composer + phpbrew |
| `luaenv` | Lua environment | luaenv + lua-build + Lua 5.4.x + LuaRocks |
| `rig` | R environment | r-lib/rig version manager + latest stable R |
| `sqlite3` | SQLite | SQLite3 system install (apt-get) |
| `perl` | Perl | Perl system install (apt-get) |

## CLI Options

```
--only MODULES        Install only the specified modules (comma-separated)
--skip MODULES        Skip the specified modules (comma-separated)
--cn                  Enable China mainland mirror acceleration
--docker              Generate a Dockerfile instead of installing locally
--base-image IMAGE    Docker base image (default: ubuntu:22.04)
--dry-run             Preview operations without installing
-h, --help            Show help
```

## China Mirror Configuration

All mirrors can be overridden via command-line options or environment variables.

| Option | Environment Variable | Default | Description |
|--------|----------------------|---------|-------------|
| `--cn-github-proxy` | `MIRROR_FOR_GITHUB` | `https://ghfast.top` | GitHub proxy |
| `--cn-apt-source` | `MIRROR_APT_SOURCE` | `mirrors.ustc.edu.cn` | APT source mirror |
| `--cn-docker-mirror` | `MIRROR_DOCKER` | `Aliyun` | Docker CE mirror |
| `--cn-pypi-index` | `MIRROR_PYPI_INDEX` | `https://pypi.tuna.tsinghua.edu.cn/simple` | PyPI mirror |
| `--cn-npm-registry` | `MIRROR_NPM_REGISTRY` | `https://registry.npmmirror.com` | npm registry |
| `--cn-node-mirror` | `MIRROR_NODE` | `https://npmmirror.com/mirrors/node` | Node.js binaries |
| `--cn-rustup-dist` | `MIRROR_RUSTUP_DIST` | `https://mirrors.tuna.tsinghua.edu.cn/rustup` | Rustup distribution |
| `--cn-rustup-update` | `MIRROR_RUSTUP_UPDATE` | `https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup` | Rustup updater |
| `--cn-cargo-registry` | `MIRROR_CARGO_REGISTRY` | `rsproxy` | Cargo registry |
| `--cn-go-proxy` | `MIRROR_GO_PROXY` | `https://goproxy.cn,direct` | Go module proxy |
| `--cn-go-binary` | `MIRROR_GO_BINARY` | `https://mirrors.aliyun.com/golang/` | Go binary downloads |
| `--cn-ruby-build-mirror` | `MIRROR_RUBY_BUILD` | `https://mirrors.aliyun.com/ruby` | Ruby source tarballs |
| `--cn-rubygems-source` | `MIRROR_RUBYGEMS_SOURCE` | `https://gems.ruby-china.com` | RubyGems source |
| `--cn-php-source` | `MIRROR_PHP_SOURCE` | `https://mirrors.aliyun.com/php-src` | PHP source tarballs |

> The default GitHub proxy is a public third-party service. You can override it with any prefix-style proxy, or set `MIRROR_FOR_GITHUB=""` to access GitHub directly.

## Mirror Mechanisms

1. **GitHub proxy** — prepend a proxy prefix to `github.com` / `raw.githubusercontent.com` URLs (nvm, rustup, gvm, code-server, uv, rbenv, phpbrew, luaenv, rig).
2. **Package manager mirrors** — PyPI via `UV_DEFAULT_INDEX`, npm via `npm config set registry`, Node binaries via `NVM_NODEJS_ORG_MIRROR`.
3. **Toolchain distribution mirrors** — Rust via `RUSTUP_DIST_SERVER` / `RUSTUP_UPDATE_ROOT`, Cargo via `~/.cargo/config.toml`, Go via `GOPROXY` / `GO_BINARY_BASE_URL`.
4. **System source mirrors** — APT via linuxmirrors, Docker CE via `--mirror`.

See [docs/design.md](docs/design.md) for details.

## Directory Structure

```
dev-env-setups/
├── setup.sh                    # Main one-command installer
├── lib/
│   ├── common.sh               # Shared utility functions
│   ├── modules.sh              # Module install logic
│   ├── mirrors.sh              # Mirror configuration management
│   └── proxy-test.sh           # GitHub proxy speed detection
├── refs/install_*.sh           # Upstream installer reference copies
├── docs/
│   ├── design.md               # Design documentation (Chinese)
│   ├── design.en.md            # Design documentation (English)
│   ├── user-guide.md           # User guide (Chinese)
│   ├── user-guide.en.md        # User guide (English)
│   ├── handbook.md             # Manual installation handbook (Chinese)
│   └── handbook.en.md          # Manual installation handbook (English)
├── tests/
│   ├── test_local.sh           # Local unit tests (syntax, args, modules)
│   ├── test_docker.sh          # Docker integration test
│   ├── test_docker_timed.sh    # Timed full Docker build test
│   └── analyze_build_log.py    # Docker build log timing analyzer
├── docker/
│   └── Dockerfile.example      # Example generated full Dockerfile
├── README.md                   # This file
├── README.zh-CN.md             # Chinese documentation
└── LICENSE
```

## Testing

```bash
# Unit tests (syntax and structure checks)
bash tests/test_local.sh

# Docker integration test (builds an image and verifies all modules)
bash tests/test_docker.sh

# Timed full Docker build with per-module timing
bash tests/test_docker_timed.sh

# Manual dry run
./setup.sh --dry-run --cn --only base,uv
```

## Contributing

Pull requests and issues are welcome. Please keep both Chinese and English documentation in sync.

## License

[MIT](LICENSE)
