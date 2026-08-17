# dev-env-setups

一键式 Linux 开发环境搭建脚本，面向中国大陆用户友好，自动配置国内镜像加速。

[English Documentation](README.md)

## 功能特性

- **一条命令**安装 16 个开发模块：Python、Node.js、Rust、Go、Java、Ruby、PHP、Lua、R、SQLite、Perl、Docker、code-server 等。
- **国内镜像支持**（`--cn`），提供 14 项可配置镜像：GitHub、APT、PyPI、npm、Rust、Go、RubyGems、PHP 等。
- 支持**本地安装模式**和 **Dockerfile 生成模式**（`--docker`）。
- 通过 `--only` / `--skip` 灵活选择模块。
- 附带 GitHub 代理测速工具（`lib/proxy-test.sh`）。

## 快速开始

```bash
# 安装全部模块（国际网络环境）
./setup.sh

# 安装全部模块（中国大陆网络环境，自动配置镜像）
./setup.sh --cn

# 只安装 Python + Node.js
./setup.sh --cn --only uv,nvm

# 安装全部但跳过 Docker
./setup.sh --skip docker

# 生成 Dockerfile 用于构建开发环境镜像
./setup.sh --cn --docker > Dockerfile
docker build -t dev-env:latest .
```

## 前置要求

- **操作系统**：Ubuntu 22.04+ / Debian 11+ / CentOS 7+ / Fedora / Rocky Linux
- **软件**：bash、curl、wget、git
- **权限**：sudo 或 root

## 包含模块

| 模块 | 说明 | 安装内容 |
|------|------|---------|
| `base` | 系统基础环境 | build-essential、git、curl、编译工具链、APT 源配置 |
| `docker` | Docker CE | Docker Engine、CLI、Compose、Buildx |
| `uv` | Python 环境 | uv 包管理器 + Python 3.11 |
| `nvm` | Node.js 环境 | nvm 版本管理器 + Node.js LTS + npm 全局包 |
| `rustup` | Rust 环境 | rustup 工具链管理 + Rust stable |
| `gvm` | Go 环境 | gvm 版本管理 + Go 1.24.13（二进制安装） |
| `sdkman` | Java 环境 | sdkman JDK 管理 + Java 25.0.2-ms |
| `code-server` | Web IDE | code-server + GitHub Copilot 扩展 |
| `chsrc` | 换源工具 | chsrc 全平台软件源切换工具 |
| `xcmd` | Shell 工具 | x-cmd Shell 工具集合 |
| `rbenv` | Ruby 环境 | rbenv + ruby-build + 最新稳定版 Ruby（源码编译） |
| `phpbrew` | PHP 环境 | ondrej/php PPA 预编译 PHP + Composer + phpbrew |
| `luaenv` | Lua 环境 | luaenv + lua-build + Lua 5.4.x + LuaRocks |
| `rig` | R 环境 | r-lib/rig 版本管理器 + 最新稳定版 R |
| `sqlite3` | SQLite | SQLite3 系统级安装（apt-get） |
| `perl` | Perl | Perl 系统级安装（apt-get） |

## 命令行选项

```
--only MODULES        只安装指定模块（逗号分隔）
--skip MODULES        跳过指定模块（逗号分隔）
--cn                  启用中国大陆网络环境镜像加速
--docker              生成 Dockerfile 而非本地安装
--base-image IMAGE    Docker 基础镜像（默认：ubuntu:22.04）
--dry-run             仅预览操作，不实际安装
-h, --help            显示帮助信息
```

## 国内镜像参数

所有镜像均可通过命令行参数或环境变量覆盖：

| 参数 | 环境变量 | 默认值 | 说明 |
|------|---------|--------|------|
| `--cn-github-proxy` | `MIRROR_FOR_GITHUB` | `https://ghfast.top` | GitHub 代理 |
| `--cn-apt-source` | `MIRROR_APT_SOURCE` | `mirrors.ustc.edu.cn` | APT 源镜像 |
| `--cn-docker-mirror` | `MIRROR_DOCKER` | `Aliyun` | Docker CE 镜像 |
| `--cn-pypi-index` | `MIRROR_PYPI_INDEX` | `https://pypi.tuna.tsinghua.edu.cn/simple` | PyPI 镜像 |
| `--cn-npm-registry` | `MIRROR_NPM_REGISTRY` | `https://registry.npmmirror.com` | npm 镜像 |
| `--cn-node-mirror` | `MIRROR_NODE` | `https://npmmirror.com/mirrors/node` | Node.js 二进制镜像 |
| `--cn-rustup-dist` | `MIRROR_RUSTUP_DIST` | `https://mirrors.tuna.tsinghua.edu.cn/rustup` | Rustup 分发服务器 |
| `--cn-rustup-update` | `MIRROR_RUSTUP_UPDATE` | `https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup` | Rustup 更新服务器 |
| `--cn-cargo-registry` | `MIRROR_CARGO_REGISTRY` | `rsproxy` | Cargo 镜像源 |
| `--cn-go-proxy` | `MIRROR_GO_PROXY` | `https://goproxy.cn,direct` | Go 模块代理 |
| `--cn-go-binary` | `MIRROR_GO_BINARY` | `https://mirrors.aliyun.com/golang/` | Go 二进制下载 |
| `--cn-ruby-build-mirror` | `MIRROR_RUBY_BUILD` | `https://mirrors.aliyun.com/ruby` | Ruby 源码包镜像 |
| `--cn-rubygems-source` | `MIRROR_RUBYGEMS_SOURCE` | `https://gems.ruby-china.com` | RubyGems 镜像 |
| `--cn-php-source` | `MIRROR_PHP_SOURCE` | `https://mirrors.aliyun.com/php-src` | PHP 源码包镜像 |

> 默认 GitHub 代理为公共第三方服务。你可以使用任意前缀式代理覆盖，或设置 `MIRROR_FOR_GITHUB=""` 直连 GitHub。

## 镜像机制概述

1. **GitHub 代理类**：在 `github.com` / `raw.githubusercontent.com` 前添加代理前缀（影响 nvm、rustup、gvm、code-server、uv、rbenv、phpbrew、luaenv、rig）。
2. **包管理镜像类**：PyPI 通过 `UV_DEFAULT_INDEX`，npm 通过 `npm config set registry`，Node 二进制通过 `NVM_NODEJS_ORG_MIRROR`。
3. **工具链分发镜像类**：Rust 通过 `RUSTUP_DIST_SERVER` / `RUSTUP_UPDATE_ROOT`，Cargo 通过 `~/.cargo/config.toml`，Go 通过 `GOPROXY` / `GO_BINARY_BASE_URL`。
4. **系统源镜像类**：APT 通过 linuxmirrors 工具，Docker CE 通过 `--mirror` 参数。

详见[设计文档](docs/design.md)。

## 目录结构

```
dev-env-setups/
├── setup.sh                    # 一键安装主脚本
├── lib/
│   ├── common.sh               # 公共工具函数
│   ├── modules.sh              # 模块安装逻辑
│   ├── mirrors.sh              # 镜像配置管理
│   └── proxy-test.sh           # GitHub 代理测速工具
├── refs/install_*.sh           # 各工具官方安装脚本（参考副本）
├── docs/
│   ├── design.md               # 设计文档（中文）
│   ├── design.en.md            # 设计文档（英文）
│   ├── user-guide.md           # 用户指南（中文）
│   ├── user-guide.en.md        # 用户指南（英文）
│   ├── handbook.md             # 手动安装手册（中文）
│   └── handbook.en.md          # 手动安装手册（英文）
├── tests/
│   ├── test_local.sh           # 本地单元测试（语法、参数、模块选择）
│   ├── test_docker.sh          # Docker 环境集成测试
│   ├── test_docker_timed.sh    # Docker 完整构建耗时测试
│   └── analyze_build_log.py    # Docker 构建日志耗时分析
├── docker/
│   └── Dockerfile.example      # 完整开发环境 Dockerfile 示例
├── README.md                   # 英文文档
├── README.zh-CN.md             # 本文档
└── LICENSE
```

## 测试

```bash
# 单元测试（语法和结构检查）
bash tests/test_local.sh

# Docker 环境集成测试（构建镜像并验证所有模块）
bash tests/test_docker.sh

# Docker 完整构建耗时测试（逐模块计时）
bash tests/test_docker_timed.sh

# 手动预览
./setup.sh --dry-run --cn --only base,uv
```

## 贡献

欢迎提交 PR 和 Issue。请保持中英文文档同步更新。

## License

[MIT](LICENSE)
