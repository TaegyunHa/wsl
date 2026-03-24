#!/usr/bin/env bash
set -euo pipefail

# WSL1 specific option to prevent apt upgrade fail
if grep -qi "microsoft" /proc/sys/kernel/osrelease 2>/dev/null && ! grep -q "WSL2" /proc/sys/kernel/osrelease 2>/dev/null; then
    echo "WSL1 detected, applying systemd workaround..."
    sudo apt-mark hold systemd
    sudo apt-mark hold systemd-dev
    sudo mv /var/lib/dpkg/info /var/lib/dpkg/info_silent
    sudo mkdir /var/lib/dpkg/info
    sudo apt-get update
    sudo apt-get -f install
    sudo bash -c 'mv /var/lib/dpkg/info/* /var/lib/dpkg/info_silent/ 2>/dev/null || true'
    sudo rm -rf /var/lib/dpkg/info
    sudo mv /var/lib/dpkg/info_silent /var/lib/dpkg/info
fi

# Update the system
sudo apt update && sudo apt upgrade -y

# Setup local config directory
mkdir -p ~/.config

# Setup local binary directory
mkdir -p ~/.local/bin
if ! grep -q 'LOCAL/bin' ~/.bashrc; then
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
curl -fsSL https://pyenv.run | bash
if ! grep -q 'PYENV_ROOT' ~/.bashrc; then
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
    echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
    # echo 'eval "$(pyenv init - bash)"' >> ~/.bashrc
fi
# Setup pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
pyenv install 3.13
pyenv global 3.13

# Install uv
echo "installing uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install ripgrep
echo "installing ripgrep..."
curl -Lo /tmp/ripgrep_14.1.1-1_amd64.deb https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep_14.1.1-1_amd64.deb
sudo dpkg -i /tmp/ripgrep_14.1.1-1_amd64.deb

# Install fd
echo "installing fd-find..."
sudo apt-get install -y fd-find
ln -sf "$(which fdfind)" ~/.local/bin/fd

# Install tree
echo "installing tree..."
sudo apt-get install -y tree

# Install neovim
echo "installing neovim..."
curl -Lo /tmp/nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf /tmp/nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
if ! grep -q 'alias vim=nvim' ~/.bashrc; then
    echo 'alias vim=nvim' >> ~/.bashrc
fi

# Setup neovim config
[ -d ~/.config/nvim ] || git clone --depth=1 https://github.com/TaegyunHa/nvim.git ~/.config/nvim

# Setup tmux config
[ -d ~/.config/tmux ] || git clone --depth=1 --recursive https://github.com/TaegyunHa/tmux.git ~/.config/tmux

# Install claude
echo "installing claude..."
curl -fsSL https://claude.ai/install.sh | bash
