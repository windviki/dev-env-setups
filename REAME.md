# 环境搭建指南

## 准备

访问 https://github.akams.cn/，点击节点测速，获取一个目前最快的国内github镜像地址。比如目前是 https://ghfast.top
之后安装步骤、或者安装脚本内容涉及到 https://github.com 的网址，都应该被替换为 https://ghfast.top/https://github.com

```
export MIRROR_FOR_GITHUB=https://ghfast.top
sed -i 's|https://github.com|$MIRROR_FOR_GITHUB/https://github.com|g' /tmp/the-target-file-contains-github
```
可将MIRROR_FOR_GITHUB环境变量添加到 ~/.zshrc 和 ~/.bash_profile 里。

## 系统

- 下载系统源替换工具
```
curl -sSL https://linuxmirrors.cn/main.sh > /tmp/install_linuxmirrors.sh
```
- chmod +x 设置权限
- 替换系统源
```
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
```
sudo apt-get update
sudo apt-get install -y net-tools iputils-ping telnet zip unzip
sudo apt-get install -y build-essential binutils gcc make cmake
sudo apt-get install -y git git-core curl openssl libssl-dev wget vim pkg-config autoconf automake g++ ccache tcl-dev libexpat1-dev libpcre3-dev libcap-dev libcap2 bison flex
```

## docker

- 下载一键安装脚本
```
curl -fsSL https://get.docker.com > /tmp/install_docker.sh
```
- chmod +x 设置权限，并 sudo 执行该安装脚本（采用阿里云镜像）
```
sudo sh /tmp/install_docker.sh --mirror Aliyun
```

## Python

先安装uv，再安装Python。采用uv管理项目的虚拟环境和包依赖。

### uv

- 下载一键安装脚本
```
curl -LsSf https://astral.sh/uv/install.sh > /tmp/install_uv.sh
```
- 针对国内环境，需要采用sed替换该脚本中的 github.com 为国内镜像地址（$MIRROR_FOR_GITHUB/https://github.com）
- 针对国内环境，追加环境变量修改uv安装python的地址和pypi镜像地址：
```
export UV_INSTALLER_GHE_BASE_URL=${MIRROR_FOR_GITHUB}/https://github.com
export UV_PYTHON_INSTALL_MIRROR=${MIRROR_FOR_GITHUB}/https://github.com/indygreg/python-build-standalone/releases/download
export UV_DEFAULT_INDEX=https://pypi.tuna.tsinghua.edu.cn/simple
```
- chmod +x 设置权限，并执行该安装脚本

### Python

- 采用uv安装需要的版本：
```
uv python install 3.11.14
```

## Javascript & node.js & npm

先安装nvm管理nodejs版本，再安装lts的nodejs和npm环境。

### nvm

- curl -o- $MIRROR_FOR_GITHUB/https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh > /tmp/install_nvm.sh
- 针对国内环境，需要采用sed替换该脚本中的 github.com 为国内镜像地址（$MIRROR_FOR_GITHUB/https://github.com）
- 追加环境变量：
```
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node
```
- chmod +x 设置权限，并执行该安装脚本

### 安装node.js和npm

- 安装LTS的nodejs环境
```
nvm install --lts
nvm use --lts
nvm alias default 'lts/*'
```
- npm设置：
```
npm config set registry https://registry.npmmirror.com
```
- 安装必要的包：
```
npm install -g typescript bun yarn pnpm@latest-11
```

## Rust

采用rustup进行rust版本的管理。

### rustup

- 下载安装脚本
```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > /tmp/install_rustup.sh
```
- 针对国内环境，需要采用sed替换该脚本中的 github.com 为国内镜像地址（$MIRROR_FOR_GITHUB/https://github.com）
- 追加环境变量：
```
export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
export RUSTUP_UPDATE_ROOT=https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup
```
- 创建或编辑 ~/.cargo/config.toml 文件，内容为
```
# 放到 `$HOME/.cargo/config` 文件中
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
- chmod +x 设置权限，并执行该安装脚本

### Rust

```
rustup toolchain install stable
```

## Go

采用gvm对go环境进行管理。

### gvm

- 下载安装脚本
```
curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer > /tmp/install_gvm.sh
```
- 针对国内环境，需要采用sed替换该脚本中的 github.com 为国内镜像地址（$MIRROR_FOR_GITHUB/https://github.com）
- 编辑环境变量：在 ~/.zshrc 和 ~/.bash_profile 文件内添加如下内容：
```
export GO111MODULE=on
export GOPROXY=https://goproxy.cn,direct
export GO_BINARY_BASE_URL=https://mirrors.aliyun.com/golang/
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
export GOROOT_BOOTSTRAP=$GOROOT
```
- chmod +x 设置权限，并执行该安装脚本
- 针对国内环境，需要采用sed替换 ~/.gvm/scripts/install 脚本中的 github.com 为国内镜像地址（$MIRROR_FOR_GITHUB/https://github.com）
- source ~/.bash_profile 生效

### go

```
gvm install go1.24.13 --binary
gvm use go1.24.13 --default
```

## Java

采用sdkman进行jdk的版本管理。

### sdkman

- 下载安装脚本
```
curl -s "https://get.sdkman.io" > /tmp/install_sdkman.sh
```
- chmod +x 设置权限，并执行该安装脚本
- source "$HOME/.sdkman/bin/sdkman-init.sh"

### JDK
```
sdk version
sdk ls java
sdk install java 25.0.2-ms
sdk default java 25.0.2-ms
```

## code-server

- 下载安装脚本
```
curl -fsSL https://code-server.dev/install.sh > /tmp/install_code_server.sh
```
- 针对国内环境，需要采用sed替换该脚本中的 github.com 为国内镜像地址（$MIRROR_FOR_GITHUB/https://github.com）
- chmod +x 设置权限，并执行该安装脚本

## 其他

### chsrc 换源工具

- 下载安装脚本
```
curl https://chsrc.run/posix > /tmp/install_chsrc.sh
```
- chmod +x 设置权限，并执行该安装脚本

### x-cmd shell工具集合

- 下载安装脚本
```
curl https://get.x-cmd.com > /tmp/install_xcmd.sh
```
- chmod +x 设置权限，并执行该安装脚本
