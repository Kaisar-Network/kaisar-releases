#!/bin/bash

# Script to install and set up the Kaisar CLI on Ubuntu

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run this script with sudo: sudo ./kaisar-provider-setup.sh"
  exit 1
fi

# Install Node.js and npm (version 18.x)
echo "Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt update
apt install -y nodejs

# Check Node.js and npm versions
node -v
npm -v

# Install pm2 globally
echo "Installing pm2..."
npm install -g pm2

# Check and install curl if not present
if ! command -v curl &> /dev/null; then
  echo "Installing curl..."
  apt install -y curl
fi

# Get latest version info from Kaisar API
echo "Checking latest Kaisar Provider CLI version..."
API_URL="https://app-api.kaisar.io/kavm/check-version/0?app=provider-cli&platform=linux"
VERSION_INFO=$(curl -fsSL "$API_URL")
DOWNLOAD_URL=$(echo "$VERSION_INFO" | grep -oP '"downloadUrl"\s*:\s*"\K[^"]+')
LATEST_VERSION=$(echo "$VERSION_INFO" | grep -oP '"latestVersion"\s*:\s*"\K[^"]+')

if [ -z "$DOWNLOAD_URL" ]; then
  echo "Error: Could not fetch download URL from API."
  exit 1
fi

# Prepare install directory
INSTALL_DIR="/opt/kaisar-provider-cli-$LATEST_VERSION"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Tạo thư mục lưu data chuẩn Linux và cấp quyền
DATA_DIR="/var/lib/kaisar-provider-cli"
sudo mkdir -p "$DATA_DIR"
sudo chown $(whoami) "$DATA_DIR"

# Download and extract the release package
echo "Downloading Kaisar Provider CLI package..."
curl -L "$DOWNLOAD_URL" -o kaisar-provider.tar.gz
if [ $? -ne 0 ]; then
  echo "Error: Unable to download package."
  exit 1
fi

echo "Extracting package..."
tar -xzf kaisar-provider.tar.gz
rm kaisar-provider.tar.gz

# Install dependencies (if package.json exists)
if [ -f package.json ]; then
  echo "Installing dependencies..."
  npm install --production
else
  echo "Error: package.json not found in extracted package."
  exit 1
fi

# Link CLI globally với biến môi trường KAISAR_DATA_DIR
export KAISAR_DATA_DIR="$DATA_DIR"
echo "Linking CLI globally..."
npm link
if [ $? -ne 0 ]; then
  echo "Error: Unable to link CLI globally. Please check your npm permissions."
  exit 1
fi

# Verify installation
echo "Verifying installation..."
kaisar hello
if [ $? -eq 0 ]; then
  echo "Installation successful! You can now use the CLI with the 'kaisar' command."
  echo "Example: kaisar start (to start the Provider Application)"
  echo "Example: kaisar status (to check the status of the Provider Application)"
else
  echo "Error: Installation failed. Please check the logs above."
  exit 1
fi
