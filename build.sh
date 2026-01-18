#!/bin/bash

# GDBLE Build Script with Platform/Architecture Suffix
# This script builds the GDBLE library for all platforms and renames
# the output files with standard platform and architecture suffixes.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}GDBLE Build Script${NC}"
echo "===================="

# Check if cargo is installed
if ! command -v cargo &> /dev/null; then
    echo -e "${RED}Error: cargo is not installed${NC}"
    exit 1
fi

# Function to build for a specific target
build_target() {
    local target=$1
    local platform=$2
    local arch=$3
    local artifact_name=$4
    
    echo -e "${YELLOW}Building for ${platform} (${arch})...${NC}"
    
    # Install target if not already installed
    if ! rustup target list --installed | grep -q "$target"; then
        echo "Installing target: $target"
        rustup target add "$target"
    fi
    
    # Build
    if [ "$platform" == "android" ]; then
        cargo build --release --target "$target" --no-default-features --features "android"
    else
        cargo build --release --target "$target"
    fi
    
    # Rename and copy
    local src="target/${target}/release/${artifact_name}"
    local dest="target/${target}/release/libgdble.${platform}.${arch}.${artifact_name##*.}"
    
    if [ -f "$src" ]; then
        cp "$src" "$dest"
        echo -e "${GREEN}✓ Built: ${dest}${NC}"
        
        # Copy to demo/addons/gdble
        local demo_dest="demo/addons/gdble/$(basename "$dest")"
        mkdir -p "demo/addons/gdble"
        cp "$dest" "$demo_dest"
        echo -e "${GREEN}✓ Copied to: ${demo_dest}${NC}"
    else
        echo -e "${RED}✗ Failed to build: ${src}${NC}"
        return 1
    fi
}

# Build for all platforms
echo -e "\n${YELLOW}Building for Windows (x86_64)...${NC}"
build_target "x86_64-pc-windows-msvc" "windows" "x86_64" "gdble.dll"

echo -e "\n${YELLOW}Building for macOS (x86_64)...${NC}"
build_target "x86_64-apple-darwin" "macos" "x86_64" "libgdble.dylib"

echo -e "\n${YELLOW}Building for macOS (ARM64)...${NC}"
build_target "aarch64-apple-darwin" "macos" "arm64" "libgdble.dylib"

echo -e "\n${YELLOW}Building for Android (ARM64)...${NC}"
if [ -z "$ANDROID_NDK_HOME" ]; then
    echo -e "${RED}ANDROID_NDK_HOME not set. Skipping Android builds.${NC}"
    echo "Set ANDROID_NDK_HOME to build for Android."
else
    export ANDROID_NDK=$ANDROID_NDK_HOME
    build_target "aarch64-linux-android" "android" "arm64" "libgdble.so"
    
    echo -e "\n${YELLOW}Building for Android (x86_64)...${NC}"
    build_target "x86_64-linux-android" "android" "x86_64" "libgdble.so"
fi

echo -e "\n${GREEN}====================${NC}"
echo -e "${GREEN}Build complete!${NC}"
echo ""
echo "Built files:"
find target -name "libgdble.*.*.*" -o -name "gdble.*.*.*" | sort