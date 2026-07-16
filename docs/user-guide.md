# 用户指南

## 快速入门

### 最基本的用法

```bash
# 克隆项目
git clone <repo-url> && cd dev-env-setups

# 安装全部开发环境（国际网络）
./setup.sh
```

### 中国大陆用户

```bash
# 测试网络速度选择最佳代理
# 访问 https://github.akams.cn/ 获取最快的 GitHub 代理地址

# 使用默认镜像一键安装
./setup.sh --cn

# 指定自定义 GitHub 代理
./setup.sh --cn --cn-github-proxy https://ghfast.top

# 自定义多个镜像
./setup.sh --cn \
  --cn-apt-source mirrors.aliyun.com \
  --cn-pypi-index https://mirrors.aliyun.com/pypi/simple/ \
  --cn-cargo-registry tuna
```

### 选择性安装

```bash
# 只安装 Python 和 Node.js
./setup.sh --cn --only uv,nvm

# 安装所有，但不装 Docker 和 Java
./setup.sh --skip docker,sdkman

# 最小化安装：系统基础 + Python + Node.js
./setup.sh --only base,uv,nvm
```

### 预览模式

```bash
# 查看将要执行的操作但不实际安装
./setup.sh --cn --only base,uv,nvm --dry-run
```

## Docker 镜像构建

### 生成 Dockerfile

```bash
# 生成完整开发环境 Dockerfile
./setup.sh --cn --docker > Dockerfile

# 指定自定义基础镜像
./setup.sh --cn --docker --base-image debian:12 > Dockerfile

# 只包含 Python + Node.js 的精简镜像
./setup.sh --cn --docker --only base,uv,nvm > Dockerfile
```

### 构建镜像

```bash
docker build -t dev-env:latest .
docker run -it dev-env:latest bash
```

## 模块介绍

### base - 系统基础环境

安装编译工具链、网络工具、git 等核心依赖。通过 linuxmirrors 工具替换 APT 源。

**前置**: curl  
**耗时**: ~2分钟

### docker - Docker CE

通过 Docker 官方脚本安装 Docker Engine、CLI、Compose、Buildx。

**前置**: base（curl, ca-certificates）  
**耗时**: ~3分钟  
**注意**: Docker 容器内不会启动 dockerd 服务

### uv - Python 环境

安装 uv Python 包管理器，然后通过 uv 安装 Python 3.11.14。

**前置**: base（curl）  
**耗时**: ~1分钟  
**安装位置**: `~/.local/bin/uv`, `~/.local/share/uv/`

### nvm - Node.js 环境

安装 nvm 版本管理器，安装 Node.js LTS，安装全局 npm 包（typescript, bun, yarn, pnpm）。

**前置**: base（curl, git）  
**耗时**: ~3分钟  
**安装位置**: `~/.nvm/`

### rustup - Rust 环境

安装 rustup 工具链管理器和 Rust stable 工具链。国内环境自动配置 Cargo 镜像。

**前置**: base（curl, build-essential）  
**耗时**: ~3分钟  
**安装位置**: `~/.rustup/`, `~/.cargo/`

### gvm - Go 环境

安装 gvm Go 版本管理器，以二进制模式安装 Go 1.24.13。

**前置**: base（git, curl）  
**耗时**: ~2分钟  
**安装位置**: `~/.gvm/`

### sdkman - Java 环境

安装 sdkman JDK 版本管理器和 Java 25.0.2-ms。

**前置**: base（unzip, zip, curl）  
**耗时**: ~2分钟  
**安装位置**: `~/.sdkman/`

### code-server - Web IDE

安装 code-server（VS Code Web 版）和 GitHub Copilot 扩展。

**前置**: base（curl）  
**耗时**: ~2分钟  
**安装位置**: `~/.local/lib/code-server-<version>/`

### chsrc - 换源工具

安装全平台软件源切换工具，可用于后续手动切换各类软件源。

**前置**: base（curl）  
**耗时**: <1分钟

### xcmd - Shell 工具

安装 x-cmd Shell 工具集合。

**前置**: base（curl）  
**耗时**: <1分钟  
**安装位置**: `~/.x-cmd.root/`

## 安装后配置

安装完成后，请重新打开终端或执行：

```bash
source ~/.bashrc    # bash
source ~/.zshrc     # zsh
```

以下工具需要手动加载环境后才可使用：
- **nvm**: `nvm use --lts` 或重新打开终端
- **sdkman**: `source "$HOME/.sdkman/bin/sdkman-init.sh"`
- **gvm**: `source "$HOME/.gvm/scripts/gvm"`

## 故障排查

### 1. 网络连接超时

```bash
# 使用国内镜像模式
./setup.sh --cn

# 自定义 GitHub 代理（选择速度最快的）
./setup.sh --cn --cn-github-proxy https://<fast-proxy-url>
```

### 2. 权限不足

```bash
# 确保当前用户有 sudo 权限
sudo -v

# 或在 root 下运行
sudo ./setup.sh --cn
```

### 3. 某个模块安装失败

```bash
# 跳过有问题的模块
./setup.sh --skip <failed-module>

# 单独安装该模块后再全量重试
```

### 4. Docker 容器中运行

```bash
# 容器中需要以 root 运行或使用 `--skip docker`
./setup.sh --skip docker
```

### 5. 查看详细日志

```bash
# 启用 bash 详细输出
bash -x ./setup.sh --cn --only base,uv 2>&1 | tee logs/install.log
```
