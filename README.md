# Automated WireGuard Installer for macOS (Apple Silicon M-Series)

## Introduction

This project provides a Bash-based automation script that installs and configures **WireGuard tools** on macOS systems.  
It is optimized for Apple Silicon (M1/M2/M3/M4) machines.

The script ensures a fully automated setup by:
- Checking system compatibility
- Installing required dependencies
- Installing WireGuard tools
- Verifying installation success

---

## Installation Method (GitHub via curl)

The script can be executed directly from this GitHub repository using:


curl -fsSL https://raw.githubusercontent.com/<username>/<repo>/main/install.sh | bash
## Here is how it works:

---

The installation process begins with a system check that detects the device architecture (arm64 expected for Apple Silicon), displays the macOS version, and warns if the system is not compatible. It then performs a Homebrew setup by checking if it is already installed and installing it if necessary, followed by configuring the shell environment through `.zprofile` and `.bash_profile`.

After setup, the script installs WireGuard tools using Homebrew, including `wg` for command-line control and `wg-quick` for managing network interfaces. Once installed, a verification step confirms that `wg` is properly installed, checks its version, and warns if `wg-quick` is missing from the system PATH.

The script requires macOS (preferably Apple Silicon), an internet connection, and administrative privileges. Homebrew is automatically installed if not present. For security, the installer uses the `curl | bash` method, so it should only be executed from trusted sources after reviewing the script.

A successful run outputs status messages such as system architecture detection, installation progress, and a final confirmation message indicating completion.

This is merely for testing purposes we are coming up with better solution on where to host it or would be better if we dont have to curl.

---
