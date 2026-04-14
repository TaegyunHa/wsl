#!/usr/bin/env bash
set -euo pipefail

# Must be run with sudo (or as root via su) so apt commands work.
if [ "$EUID" -ne 0 ]; then
    echo "Error: run this script with sudo: sudo $0" >&2
    exit 1
fi

# When invoked via "sudo setup.sh", $SUDO_USER holds the original username.
# Fall back to $USER when run directly as root.
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)

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
sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config"

# Setup local binary directory
sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.local/bin"
sed -i '/\.local\/bin/d' "$REAL_HOME/.bashrc"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$REAL_HOME/.bashrc"

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
rm -rf "$REAL_HOME/.pyenv"
sudo -u "$REAL_USER" env HOME="$REAL_HOME" bash -c 'curl -fsSL https://pyenv.run | bash'
# Remove any stale pyenv entries then re-add unconditionally
sed -i '/PYENV_ROOT/d' "$REAL_HOME/.bashrc"
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$REAL_HOME/.bashrc"
echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> "$REAL_HOME/.bashrc"
# Setup pyenv
export PYENV_ROOT="$REAL_HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
sudo -u "$REAL_USER" env PYENV_ROOT="$REAL_HOME/.pyenv" PATH="$REAL_HOME/.pyenv/bin:$PATH" pyenv install 3.13
sudo -u "$REAL_USER" env PYENV_ROOT="$REAL_HOME/.pyenv" PATH="$REAL_HOME/.pyenv/bin:$PATH" pyenv global 3.13

# Install uv
echo "installing uv..."
sudo -u "$REAL_USER" env HOME="$REAL_HOME" sh -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'

# Install ripgrep
echo "installing ripgrep..."
curl -Lo /tmp/ripgrep_14.1.1-1_amd64.deb https://github.com/BurntSushi/ripgrep/releases/download/14.1.1/ripgrep_14.1.1-1_amd64.deb
sudo dpkg -i /tmp/ripgrep_14.1.1-1_amd64.deb

# Install fd
echo "installing fd-find..."
sudo apt-get install -y fd-find
ln -sf "$(which fdfind)" "$REAL_HOME/.local/bin/fd"

# Install tree
echo "installing tree..."
sudo apt-get install -y tree

# Install zoxide
echo "installing zoxide..."
sudo -u "$REAL_USER" env HOME="$REAL_HOME" sh -c 'curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh'
if ! grep -q 'zoxide init bash' "$REAL_HOME/.bashrc"; then
    echo 'eval "$(zoxide init bash)"' >> "$REAL_HOME/.bashrc"
fi

# Install neovim
echo "installing neovim..."
curl -Lo /tmp/nvim-linux-x86_64.tar.gz https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
sudo rm -rf /opt/nvim-linux-x86_64
sudo tar -C /opt -xzf /tmp/nvim-linux-x86_64.tar.gz
sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
if ! grep -q 'alias vim=nvim' "$REAL_HOME/.bashrc"; then
    echo 'alias vim=nvim' >> "$REAL_HOME/.bashrc"
fi

# Setup neovim config
[ -d "$REAL_HOME/.config/nvim" ] || sudo -u "$REAL_USER" git clone --depth=1 https://github.com/TaegyunHa/nvim.git "$REAL_HOME/.config/nvim"

# Setup tmux config
[ -d "$REAL_HOME/.config/tmux" ] || sudo -u "$REAL_USER" git clone --depth=1 --recursive https://github.com/TaegyunHa/tmux.git "$REAL_HOME/.config/tmux"

# Install claude
echo "installing claude..."
sudo -u "$REAL_USER" env HOME="$REAL_HOME" bash -c 'curl -fsSL https://claude.ai/install.sh | bash'
