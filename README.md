# dev-env-setups - 一键开发环境搭建

全自动 Linux 开发环境安装脚本集合，支持 Python/Node.js/Rust/Go/Java/Docker/code-server 等核心开发工具链的一键部署。

## 快速开始

```bash
# 国际网络环境 - 安装全部模块
./setup.sh

# 中国大陆网络环境 - 安装全部模块（自动配置镜像加速）
./setup.sh --cn

# 只安装 Python + Node.js
./setup.sh --cn --only uv,nvm

# 安装全部但跳过 Docker
./setup.sh --skip docker

# 生成 Dockerfile
./setup.sh --cn --docker > Dockerfile
docker build -t dev-env:latest .
```

## 前置要求

- **操作系统**: Ubuntu 22.04+ / Debian 11+ / CentOS 7+ / Fedora / Rocky Linux
- **软件**: bash, curl, wget, git
- **权限**: sudo 或 root

## 包含模块

| 模块 | 说明 | 安装内容 |
|------|------|---------|
| `base` | 系统基础环境 | build-essential, git, curl, 编译工具链, APT源配置 |
| `docker` | Docker CE | Docker Engine, CLI, Compose, Buildx |
| `uv` | Python 环境 | uv 包管理器 + Python 3.11.14 |
| `nvm` | Node.js 环境 | nvm 版本管理 + Node.js LTS + npm 全局包 |
| `rustup` | Rust 环境 | rustup 工具链管理 + Rust stable |
| `gvm` | Go 环境 | gvm 版本管理 + Go 1.24.13 |
| `sdkman` | Java 环境 | sdkman JDK管理 + Java 25.0.2-ms |
| `code-server` | Web IDE | VS Code Server + GitHub Copilot 扩展 |
| `chsrc` | 换源工具 | 全平台软件源切换工具 |
| `xcmd` | Shell 工具 | x-cmd Shell 工具集合 |

## 命令行选项

```
--only MODULES       只安装指定模块（逗号分隔）
--skip MODULES       跳过指定模块（逗号分隔）
--cn                 启用中国大陆网络环境镜像加速
--docker             生成 Dockerfile 而非本地安装
--base-image IMAGE   Docker基础镜像（默认: ubuntu:22.04）
--dry-run            仅预览操作，不实际安装
```

### 国内镜像参数

所有镜像均可通过命令行或环境变量自定义覆盖：

| 参数 | 环境变量 | 默认值 | 说明 |
|------|---------|--------|------|
| `--cn-github-proxy` | `MIRROR_FOR_GITHUB` | `https://ghfast.top` | GitHub 代理 |
| `--cn-apt-source` | `MIRROR_APT_SOURCE` | `mirrors.ustc.edu.cn` | APT源镜像 |
| `--cn-docker-mirror` | `MIRROR_DOCKER` | `Aliyun` | Docker CE 镜像 |
| `--cn-pypi-index` | `MIRROR_PYPI_INDEX` | `https://pypi.tuna.tsinghua.edu.cn/simple` | PyPI 镜像 |
| `--cn-npm-registry` | `MIRROR_NPM_REGISTRY` | `https://registry.npmmirror.com` | npm 镜像 |
| `--cn-node-mirror` | `MIRROR_NODE` | `https://npmmirror.com/mirrors/node` | Node.js 二进制 |
| `--cn-rustup-dist` | `MIRROR_RUSTUP_DIST` | `https://mirrors.tuna.tsinghua.edu.cn/rustup` | Rustup 分发 |
| `--cn-rustup-update` | `MIRROR_RUSTUP_UPDATE` | `https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup` | Rustup 更新 |
| `--cn-cargo-registry` | `MIRROR_CARGO_REGISTRY` | `rsproxy` | Cargo 镜像 |
| `--cn-go-proxy` | `MIRROR_GO_PROXY` | `https://goproxy.cn,direct` | Go 代理 |
| `--cn-go-binary` | `MIRROR_GO_BINARY` | `https://mirrors.aliyun.com/golang/` | Go 二进制 |

## 镜像机制概述

本项目涉及的镜像分 4 大类、11 种：

### 1. GitHub 代理类（URL前缀改写）
- **机制**: 在 `https://github.com` / `https://raw.githubusercontent.com` 前添加代理前缀
- **影响模块**: nvm, rustup, gvm, code-server, uv
- **示例**: `https://ghfast.top/https://github.com/user/repo.git`

### 2. 包管理镜像类（环境变量控制）
- **PyPI**: 通过 `UV_DEFAULT_INDEX` 环境变量
- **npm**: 通过 `npm config set registry` 命令
- **Node.js 二进制**: 通过 `NVM_NODEJS_ORG_MIRROR` 环境变量

### 3. 工具链分发镜像类（环境变量 + 配置文件）
- **Rustup**: `RUSTUP_DIST_SERVER` + `RUSTUP_UPDATE_ROOT`
- **Cargo**: `~/.cargo/config.toml` 中 `replace-with` 配置
- **Go**: `GOPROXY` + `GO_BINARY_BASE_URL`

### 4. 系统源镜像类
- **APT**: linuxmirrors 工具脚本替换 `/etc/apt/sources.list`
- **Docker CE**: `--mirror` 参数指定

详见 [设计文档](docs/design.md)

## 目录结构

```
dev-env-setups/
├── setup.sh                    # 一键安装主脚本
├── lib/
│   ├── common.sh               # 公共工具函数
│   ├── modules.sh              # 模块安装逻辑
│   └── mirrors.sh              # 镜像配置管理
├── refs/install_*.sh            # 各工具官方安装脚本（参考保留）
├── docs/
│   ├── design.md               # 设计文档
│   └── user-guide.md           # 用户指南
├── tests/
│   ├── test_docker.sh          # Docker 环境集成测试
│   └── test_local.sh           # 本地环境单元测试
├── docker/
│   └── Dockerfile.test         # 测试用 Dockerfile
└── logs/                       # 日志目录
```

## 测试

```bash
# 单元测试（语法和结构检查）
bash tests/test_local.sh

# Docker 环境集成测试（构建镜像并验证所有模块）
bash tests/test_docker.sh

# 手动测试
./setup.sh --dry-run --cn --only base,uv
```

## 贡献

欢迎提交 PR 和 Issue。

## License

MIT
