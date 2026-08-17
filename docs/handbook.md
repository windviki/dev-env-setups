# 环境搭建指南（手动参考手册）

> 本文档是手动逐步安装各开发工具的参考指南，
> 如需一键自动安装，请使用 [setup.sh](../setup.sh)。

## 准备

访问 https://github.akams.cn/，点击节点测速，获取一个目前最快的国内github镜像地址。比如目前是 https://ghfast.top
之后安装步骤、或者安装脚本内容涉及到 https://github.com 的网址，都应该被替换为镜像代理地址。

```bash
export MIRROR_FOR_GITHUB=https://ghfast.top
# 注意：使用双引号以便变量展开
sed -i "s|https://github\.com|${MIRROR_FOR_GITHUB}/https://github.com|g" /tmp/the-target-file
sed -i "s|https://raw\.githubusercontent\.com|${MIRROR_FOR_GITHUB}/https://raw.githubusercontent.com|g" /tmp/the-target-file
```

可将 `MIRROR_FOR_GITHUB` 环境变量添加到 `~/.zshrc` 和 `~/.bashrc` 里。

## 系统

- 下载系统源替换工具
```bash
curl -sSL https://linuxmirrors.cn/main.sh > /tmp/install_linuxmirrors.sh
```
- `chmod +x` 设置权限
- 替换系统源
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
- 安装基础依赖
```bash
sudo apt-get update
sudo apt-get install -y net-tools iputils-ping telnet zip unzip
sudo apt-get install -y build-essential binutils gcc make cmake
sudo apt-get install -y git git-core curl openssl libssl-dev wget vim pkg-config autoconf automake g++ ccache tcl-dev libexpat1-dev libpcre3-dev libcap-dev libcap2 bison flex
```

## docker

- 下载一键安装脚本
```bash
curl -fsSL https://get.docker.com > /tmp/install_docker.sh
```
- `chmod +x` 设置权限，并 `sudo` 执行该安装脚本（采用阿里云镜像）
```bash
sudo sh /tmp/install_docker.sh --mirror Aliyun
```

> **说明**：国内环境推荐 `--mirror Aliyun`，也可用 `--mirror AzureChinaCloud`。

## Python

先安装uv，再安装Python。采用uv管理项目的虚拟环境和包依赖。

### uv

- 下载一键安装脚本
```bash
curl -LsSf https://astral.sh/uv/install.sh > /tmp/install_uv.sh
```
- 针对国内环境，需要采用 sed 替换该脚本中的 github.com 为国内镜像地址。
  > **修正说明**：需要同时替换 `github.com` 和 `raw.githubusercontent.com`。
```bash
sed -i "s|https://github\.com|${MIRROR_FOR_GITHUB}/https://github.com|g" /tmp/install_uv.sh
sed -i "s|https://raw\.githubusercontent\.com|${MIRROR_FOR_GITHUB}/https://raw.githubusercontent.com|g" /tmp/install_uv.sh
```
- 针对国内环境，追加环境变量修改uv安装python的地址和pypi镜像地址：
```bash
export UV_INSTALLER_GHE_BASE_URL=${MIRROR_FOR_GITHUB}/https://github.com
export UV_PYTHON_INSTALL_MIRROR=${MIRROR_FOR_GITHUB}/https://github.com/indygreg/python-build-standalone/releases/download
export UV_DEFAULT_INDEX=https://pypi.tuna.tsinghua.edu.cn/simple
```
- `chmod +x` 设置权限，并执行该安装脚本
```bash
chmod +x /tmp/install_uv.sh
bash /tmp/install_uv.sh
```

### Python

- 采用uv安装需要的版本：
```bash
export PATH="$HOME/.local/bin:$PATH"
uv python install 3.11.14
```

## Javascript & node.js & npm

先安装nvm管理nodejs版本，再安装lts的nodejs和npm环境。

### nvm

- 下载安装脚本：
```bash
curl -fsSL ${MIRROR_FOR_GITHUB}/https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh -o /tmp/install_nvm.sh
```
- 针对国内环境，需要采用 sed 替换该脚本中的 github.com 为国内镜像地址（同上 sed 命令）
- 追加环境变量：
```bash
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
```

> **重要提示**：nvm 默认安装方式为 `git clone`，若网络环境不佳（git 超时），
> 可设置 `METHOD=script` 强制使用 curl/wget 下载脚本文件：
> ```bash
> METHOD=script bash /tmp/install_nvm.sh
> ```
> Docker/CI 环境中推荐使用 script 方法以避免 git 连接问题。

- `chmod +x` 设置权限，并执行该安装脚本

### 安装node.js和npm

- 安装LTS的nodejs环境
```bash
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'
```
- npm设置：
```bash
npm config set registry https://registry.npmmirror.com
```
- 安装必要的包：
```bash
npm install -g typescript bun yarn pnpm@latest-11
```

## Rust

采用rustup进行rust版本的管理。

### rustup

- 下载安装脚本
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/install_rustup.sh
```
- 针对国内环境，需要采用 sed 替换该脚本中的 github.com 为国内镜像地址
- 追加环境变量：
```bash
export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
export RUSTUP_UPDATE_ROOT=https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup
```
- 创建或编辑 `~/.cargo/config.toml` 文件，内容为
```toml
# 放到 `$HOME/.cargo/config.toml` 文件中
[source.crates-io]
registry = "https://github.com/rust-lang/crates.io-index"

# 替换成你偏好的镜像源
replace-with = 'rsproxy'

# 清华大学
[source.tuna]
registry = "https://mirrors.tuna.tsinghua.edu.cn/git/crates.io-index.git"

# 中国科学技术大学
[source.ustc]
registry = "git://mirrors.ustc.edu.cn/crates.io-index"

# 上海交通大学
[source.sjtu]
registry = "https://mirrors.sjtug.sjtu.edu.cn/git/crates.io-index"

# rustcc社区 - 已失效！
# [source.rustcc]
# registry = "https://code.aliyun.com/rustcc/crates.io-index.git"

# rustcc 1号源
[source.rustcc]
registry = "git://crates.rustcc.com/crates.io-index"

# rustcc 2号源
[source.rustcc2]
registry = "git://crates.rustcc.cn/crates.io-index"

# 字节跳动源
[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"

[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"

[net]
git-fetch-with-cli = true
```

> **可选镜像源**：`rsproxy`（字节跳动）、`tuna`（清华）、`ustc`（中科大）、
> `sjtu`（上海交大）、`rustcc`/`rustcc2`（Rustcc社区）

- `chmod +x` 设置权限，并执行该安装脚本
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

采用gvm对go环境进行管理。

### gvm

- 下载安装脚本
```bash
curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer > /tmp/install_gvm.sh
```
- 针对国内环境，需要采用 sed 替换该脚本中的 github.com 为国内镜像地址
- 编辑环境变量：在 `~/.zshrc` 和 `~/.bash_profile` 文件内添加如下内容：
```bash
export GO111MODULE=on
export GOPROXY=https://goproxy.cn,direct
export GO_BINARY_BASE_URL=https://mirrors.aliyun.com/golang/
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
export GOROOT_BOOTSTRAP=$GOROOT
```
- `chmod +x` 设置权限，并执行该安装脚本
- **针对国内环境**，需要采用 sed 替换 `~/.gvm/scripts/install` 脚本中的 github.com 为国内镜像地址：
```bash
sed -i "s|https://github\.com|${MIRROR_FOR_GITHUB}/https://github.com|g" ~/.gvm/scripts/install
```
- `source ~/.bash_profile` 生效

### go

```bash
gvm install go1.24.13 --binary
gvm use go1.24.13 --default
```

> **说明**：`--binary` 方式从 `GO_BINARY_BASE_URL` 下载预编译二进制包，
> 不需要从源码编译 Go，速度更快且不需要先有 Go 编译器。

## Java

采用sdkman进行jdk的版本管理。

### sdkman

- 下载安装脚本
```bash
curl -s "https://get.sdkman.io" > /tmp/install_sdkman.sh
```
- `chmod +x` 设置权限，并执行该安装脚本
- `source "$HOME/.sdkman/bin/sdkman-init.sh"`

> **注意**：sdkman 目前没有官方的国内镜像。其 API 服务器 `https://api.sdkman.io/2`
> 在国内访问可能较慢，建议在有代理的环境下安装，或通过 chsrc 工具切换 sdkman 源。

### JDK
```bash
sdk version
sdk ls java
sdk install java 25.0.2-ms
sdk default java 25.0.2-ms
```

## code-server

- 下载安装脚本
```bash
curl -fsSL https://code-server.dev/install.sh > /tmp/install_code_server.sh
```
- 针对国内环境，需要采用 sed 替换该脚本中的 github.com 为国内镜像地址
- `chmod +x` 设置权限，并执行该安装脚本

> **推荐**：使用 `--method standalone` 参数，避免依赖系统包管理器：
> ```bash
> bash /tmp/install_code_server.sh --method standalone
> ```

## 其他

### chsrc 换源工具

- 下载安装脚本
```bash
curl https://chsrc.run/posix > /tmp/install_chsrc.sh
```
- `chmod +x` 设置权限，并执行该安装脚本

> **说明**：chsrc 从 gitee.com 下载，天然支持国内网络环境，无需额外配置镜像。

### x-cmd shell工具集合

- 下载安装脚本
```bash
curl https://get.x-cmd.com > /tmp/install_xcmd.sh
```
- `chmod +x` 设置权限，并执行该安装脚本

> **说明**：x-cmd 从阿里云 OSS 下载，天然支持国内网络环境。

---

## 附录：原始项目文件的注意事项

本仓库中的 `refs/install_*.sh` 文件是各工具官方安装器的参考副本，
**已还原为官方原始 URL，未硬编码任何代理地址**。setup.sh 运行时不会使用
这些副本，而是从官方源获取最新安装脚本并动态处理镜像替换。

**推荐做法**：使用一键脚本 `setup.sh`，它会从官方源获取最新安装脚本并动态
处理镜像替换，无需依赖 `refs/` 下的旧副本。
