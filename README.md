# WSL

This repository contains bash script and various setup to configure WSL environment

## Setup

> **Prerequisites:** WSL2 requires Windows 10 version 1903+ (build 18362) or Windows 11.

### Enable WSL on Windows

Run the command below on powershell with administrator privilege

```pwsh
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

### Install Debian

```pwsh
wsl --install -d Debian
```

### Set Debian as default

```pwsh
wsl --set-default Debian
```

### (Optional) Using WSL 1

```pwsh
wsl --set-default-version 1
wsl --set-version Debian 1
```

### Start wsl

```pwsh
wsl
```

## WSL1 vs WSL2

> [WSL version comparison](https://learn.microsoft.com/en-us/windows/wsl/compare-versions)

Feature | WSL1 | WSL2
--------|------|-----
Integration between Windows and Linux | ✅ | ✅
Fast boot times | ✅ | ✅
Small resource foot print compared to traditional Virtual Machines | ✅ | ✅
Runs with current versions of VMware and VirtualBox | ✅ | ❌
Managed VM | ❌ | ✅
Full Linux Kernel | ❌ | ✅
Full system call compatibility | ❌ | ✅
Performance across OS file systems | ✅ | ❌
systemd support | ❌ | ✅
IPv6 support | ✅ | ✅

## Development Environment Setup

### Clone this repository (inside WSL)

```bash
git clone https://github.com/your-org/wsl.git
cd wsl
```

### Run the setup script

The script installs packages and applies configuration for the development environment. Run it with `sudo` from inside the cloned repository:

```bash
sudo ./setup.sh
exec bash
```

`exec bash` reloads the shell so that newly installed tools and updated environment variables (e.g. from `.bashrc`) take effect immediately.
