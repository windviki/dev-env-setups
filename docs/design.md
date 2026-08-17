# 设计文档

## 架构概述

dev-env-setups 是一个 Linux 开发环境一键部署工具。核心由 `setup.sh` 作为统一入口，驱动各模块安装函数完成开发工具链部署。

## 核心设计

### 1. 入口脚本 (setup.sh)

`setup.sh` 是唯用户需要操作的脚本。它负责：

- **参数解析**: 处理 `--only`、`--skip`、`--cn`、`--docker` 等命令行选项
- **模块算法**: 读入 ALL_MODULES，用 `--only` 过滤，再用 `--skip` 过滤
- **模式分发**: 根据 `--docker` 决定本地安装还是输出 Dockerfile
- **源文件加载**: `source lib/common.sh lib/mirrors.sh lib/modules.sh`

### 2. 镜像机制详细分析

本项目涉及 4 大类 14 种镜像，分别采用不同的技术方案：

#### 第一类：GitHub 代理（URL 前缀改写）

**原理**: 在原始 GitHub URL 前添加代理服务器前缀，例如：
```
原始: https://github.com/user/repo
代理: https://ghfast.top/https://github.com/user/repo
```

**实现**: 脚本下载后用 `sed` 全局替换 `github.com` 和 `raw.githubusercontent.com`

```bash
sed "s|https://github\.com|${MIRROR_FOR_GITHUB}/https://github.com|g"
sed "s|https://raw\.githubusercontent\.com|${MIRROR_FOR_GITHUB}/https://raw.githubusercontent.com|g"
```

**涉及模块**: nvm, rustup, gvm, code-server, uv, rbenv, phpbrew, luaenv, rig（9 个）

**默认代理服务**: `https://ghfast.top` —— 一个国内可用的 GitHub 代理。

> 用户可通过访问 https://github.akams.cn/ 测速获取最佳代理地址，然后通过 `--cn-github-proxy` 或 `MIRROR_FOR_GITHUB` 覆盖。

#### 第二类：系统包管理镜像

##### APT 源镜像
- **工具**: [LinuxMirrors](https://linuxmirrors.cn) 脚本
- **机制**: 直接替换 `/etc/apt/sources.list` 内容
- **默认源**: `mirrors.ustc.edu.cn`
- **实现**: 调用 `sudo bash install_linuxmirrors.sh --source ${MIRROR_APT_SOURCE}`

##### Docker CE 镜像
- **工具**: Docker 官方安装脚本内置 `--mirror` 参数
- **支持**: `Aliyun`、`AzureChinaCloud`
- **实现**: `sh install_docker.sh --mirror ${MIRROR_DOCKER}`

#### 第三类：语言包管理镜像（环境变量控制）

| 包管理器 | 镜像变量 | 配置方式 |
|---------|---------|---------|
| **uv (PyPI)** | `UV_DEFAULT_INDEX` | 环境变量 |
| **npm** | `registry` | `npm config set registry` 命令 |
| **Node.js 二进制** | `NVM_NODEJS_ORG_MIRROR` | 环境变量 |
| **uv Python SDK** | `UV_PYTHON_INSTALL_MIRROR` | 环境变量 |
| **Go 模块** | `GOPROXY` | 环境变量 |
| **Go 二进制** | `GO_BINARY_BASE_URL` | 环境变量 |

#### 第四类：工具链分发镜像（环境变量 + 配置文件）

##### Rust 生态
- **Rustup**: `RUSTUP_DIST_SERVER` + `RUSTUP_UPDATE_ROOT` 环境变量
- **Cargo registries**: `~/.cargo/config.toml` 中配置 `replace-with`

```toml
[source.crates-io]
replace-with = 'rsproxy'  # 可切换为 tuna/ustc/sjtu/rustcc

[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"
```

支持的 Cargo 镜像源：`rsproxy`, `tuna`, `ustc`, `sjtu`, `rustcc`, `rustcc2`

##### Ruby 生态
- **Ruby 源码包**: `RUBY_BUILD_MIRROR_URL` 环境变量（ruby-build 使用）
- **RubyGems**: `gem sources` + `bundle config` 命令

##### PHP 生态
- **PHP 源码包**: phpbrew 编译参数 `--old-src-url`（当前版本安装走 ondrej PPA 预编译包，phpbrew 作为可选版本管理器）

### 3. 镜像合并规则

当用户同时传入 `--cn` 和具体覆盖参数时：
1. `--cn` 激活所有镜像默认值
2. 具体的 `--cn-xxx` 参数覆盖对应默认值
3. 可以通过环境变量 `MIRROR_XXX` 进一步覆盖

优先级：命令行参数 > 环境变量 > 脚本默认值

### 4. 安装模式设计

#### 模式 A：本地安装（默认）

直接在当前 shell 环境中执行安装。脚本会：
1. 检测操作系统类型和版本
2. 检测当前是否在 Docker 容器内（决定是否使用 sudo）
3. 按顺序执行各模块安装函数
4. 写入相应的 shell 配置文件（.bashrc, .zshrc, .profile 等）

#### 模式 B：Dockerfile 生成（`--docker`）

生成一个自包含的 Dockerfile：
1. `FROM ${BASE_IMAGE}` 指定基础镜像
2. 安装系统基础依赖
3. `COPY . /opt/dev-env-setups` 复制整个项目
4. `RUN bash setup.sh --cn --only "模块列表"` 在容器内执行安装
5. `ENV PATH=...` 设置环境变量

用户收到 Dockerfile 后可以自定义修改，然后 `docker build`。

### 5. 模块依赖

- **base** 模块建议最先安装（提供 git, curl, build-essential 等）
- **docker** 依赖 base 中的 ca-certificates, curl
- **所有语言模块** 依赖 base 中的 curl, git, build-essential
- **sdkman** 需要 base 中的 unzip, zip, tar, curl, sed
- **code-server** 可以用 nvm 安装的 npm 作为备用
- **chsrc** 和 **xcmd** 完全独立

### 6. 容错策略

- 每个模块安装失败不会中断后续模块
- Docker 环境中不启动 Docker daemon
- 语言 SDK 安装失败降级为 warning，不中断
- 非 root 用户自动使用 sudo，Docker 容器内直接执行

## 扩展方式

添加新模块只需 3 步：

1. 在 `lib/modules.sh` 的 `ALL_MODULES` 和 `MODULE_DESC` 数组中添加
2. 实现 `install_<module>()` 函数（签名：`install_xxx(use_cn)`)
3. 在 `setup.sh` 的 `run_install()` 中添加 case 分支
