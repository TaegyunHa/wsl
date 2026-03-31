#!/usr/bin/env bash
set -euo pipefail

# WSL1 specific option to prevent apt upgrade fail
if grep -qi "microsoft" /proc/sys/kernel/osrelease 2>/dev/null && ! grep -q "WSL2" /proc/sys/kernel/osrelease 2>/dev/null; then
    echo "WSL1 detected, applying systemd workaround..."
    sudo apt-mark hold systemd
    sudo apt-mark hold systemd-dev
    if [ ! -d /var/lib/dpkg/info_silent ]; then
        sudo mv /var/lib/dpkg/info /var/lib/dpkg/info_silent
        sudo mkdir /var/lib/dpkg/info
        sudo apt-get update
        sudo apt-get -f install
        sudo bash -c 'mv /var/lib/dpkg/info/* /var/lib/dpkg/info_silent/ 2>/dev/null || true'
        sudo rm -rf /var/lib/dpkg/info
        sudo mv /var/lib/dpkg/info_silent /var/lib/dpkg/info
    fi
fi

# Update the system
sudo apt update || true
sudo apt upgrade -y

# Setup local config directory
mkdir -p ~/.config

# Setup local binary directory
mkdir -p ~/.local/bin
if ! grep -q '.local/bin' ~/.bashrc; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
fi

# Setup C++
echo "installing C++ tools..."
sudo apt install -y build-essential gdb cmake ninja-build
sudo apt install -y libboost-all-dev valgrind clang clang-format clang-tidy

# Install tools
echo "installing dev tools..."
sudo apt install -y curl git tmux libssl-dev libbz2-dev libffi-dev zlib1g-dev \
    libreadline-dev libsqlite3-dev liblzma-dev tk-dev unzip wget

# Install pyenv
echo "installing pyenv..."
if [ ! -d "$HOME/.pyenv" ]; then
    curl https://pyenv.run | bash
else
    echo "pyenv already installed, skipping."
fi
if ! grep -q 'PYENV_ROOT' ~/.bashrc; then
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    # Manual init preferred — source pyenv init selectively as needed
    # echo 'eval "$(pyenv init - bash)"' >> ~/.bashrc
fi
# Setup pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
pyenv install -s 3.13
pyenv global 3.13

# Install uv
echo "installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install ripgrep
RG_VERSION="14.1.1"
if ! dpkg -s ripgrep 2>/dev/null | grep -q "$RG_VERSION"; then
    echo "installing ripgrep..."
    curl -Lo /tmp/ripgrep.deb "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep_${RG_VERSION}-1_amd64.deb"
    sudo dpkg -i /tmp/ripgrep.deb
else
    echo "ripgrep $RG_VERSION already installed, skipping."
fi

# Install fd
echo "installing fd-find..."
sudo apt-get install -y fd-find
ln -sf "$(which fdfind)" ~/.local/bin/fd

# Install tree
echo "installing tree..."
sudo apt-get install -y tree

# Install neovim
if ! command -v nvim &>/dev/null; then
    echo "installing neovim..."
    curl -Lo /tmp/nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
    sudo rm -rf /opt/nvim-linux-x86_64
    sudo tar -C /opt -xzf /tmp/nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
else
    echo "neovim already installed, skipping."
fi
if ! grep -q 'alias vim=nvim' ~/.bashrc; then
    echo 'alias vim=nvim' >> ~/.bashrc
fi
if ! grep -q 'alias code=' ~/.bashrc; then
    echo "alias code='/mnt/c/Users/taegyun.ha/AppData/Local/Programs/Microsoft\ VS\ Code/bin/code'" >> ~/.bashrc
fi

# Setup neovim config
[ -d ~/.config/nvim ] || git clone --depth=1 https://github.com/TaegyunHa/nvim.git ~/.config/nvim

# Setup tmux config
[ -d ~/.config/tmux ] || git clone --depth=1 --recursive https://github.com/TaegyunHa/tmux.git ~/.config/tmux

# Install zoxide
if ! command -v zoxide &>/dev/null; then
    echo "installing zoxide..."
    sudo apt-get install -y zoxide
else
    echo "zoxide already installed, skipping."
fi
if ! grep -q 'zoxide init' ~/.bashrc; then
    echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
fi

# Install claude
echo "installing claude..."
curl -fsSL https://claude.ai/install.sh | bash

# Cleanup temp files
rm -f /tmp/ripgrep.deb /tmp/nvim-linux-x86_64.tar.gz
