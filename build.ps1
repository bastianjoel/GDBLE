# GDBLE Build Script with Platform/Architecture Suffix (Windows)
# This script builds the GDBLE library for all platforms and renames
# the output files with standard platform and architecture suffixes.

$ErrorActionPreference = "Stop"

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

Write-ColorOutput Green "GDBLE Build Script"
Write-Output "===================="

# Check if cargo is installed
if (-not (Get-Command cargo -ErrorAction SilentlyContinue)) {
    Write-ColorOutput Red "Error: cargo is not installed"
    exit 1
}

# Function to build for a specific target
function Build-Target {
    param(
        [string]$target,
        [string]$platform,
        [string]$arch,
        [string]$artifactName
    )
    
    Write-ColorOutput Yellow "Building for ${platform} (${arch})..."
    
    # Install target if not already installed
    $installedTargets = rustup target list --installed
    if ($installedTargets -notmatch $target) {
        Write-Output "Installing target: $target"
        rustup target add $target
    }
    
    # Build
    if ($platform -eq "android") {
        cargo build --release --target $target --no-default-features --features "android"
    } else {
        cargo build --release --target $target
    }
    
    # Rename and copy
    $src = "target/${target}/release/${artifactName}"
    $extension = [System.IO.Path]::GetExtension($artifactName)
    $dest = "target/${target}/release/libgdble.${platform}.${arch}${extension}"
    
    if (Test-Path $src) {
        Copy-Item $src $dest
        Write-ColorOutput Green "✓ Built: ${dest}"
        
        # Copy to demo/addons/gdble
        $demoDest = "demo\addons\gdble\$(Split-Path $dest -Leaf)"
        if (-not (Test-Path "demo\addons\gdble")) {
            New-Item -ItemType Directory -Path "demo\addons\gdble" -Force | Out-Null
        }
        Copy-Item $dest $demoDest
        Write-ColorOutput Green "✓ Copied to: ${demoDest}"
    } else {
        Write-ColorOutput Red "✗ Failed to build: ${src}"
        return $false
    }
    return $true
}

# Build for Windows (current platform)
Write-ColorOutput Yellow "`nBuilding for Windows (x86_64)..."
Build-Target "x86_64-pc-windows-msvc" "windows" "x86_64" "gdble.dll"

# Build for Android
Write-ColorOutput Yellow "`nBuilding for Android (ARM64)..."
if (-not (Test-Path env:ANDROID_NDK_HOME)) {
    Write-ColorOutput Red "ANDROID_NDK_HOME not set. Skipping Android ARM64 build."
    Write-Output "Set ANDROID_NDK_HOME environment variable to build for Android."
} else {
    $env:ANDROID_NDK = $env:ANDROID_NDK_HOME
    Build-Target "aarch64-linux-android" "android" "arm64" "libgdble.so"
    
    Write-ColorOutput Yellow "`nBuilding for Android (x86_64)..."
    Build-Target "x86_64-linux-android" "android" "x86_64" "libgdble.so"
}

# Build for other platforms (requires cross-compilation setup)
Write-Output "`nNote: Building for macOS and Linux requires cross-compilation setup."
Write-Output "See https://rust-lang.github.io/rustup/cross-compilation.html for details."
Write-Output "`nSkipping cross-platform builds on Windows."

Write-Output "`nNote: Android ARMv7 (32-bit) is not supported due to godot-ffi compatibility issues."
Write-Output "Use Android ARM64 or x86_64 instead."

Write-ColorOutput Green "`n===================="
Write-ColorOutput Green "Build complete!"
Write-Output ""
Write-Output "Built files:"
Get-ChildItem -Path target -Recurse -Filter "libgdble.*.*.*" -ErrorAction SilentlyContinue | 
    ForEach-Object { $_.FullName }
Get-ChildItem -Path target -Recurse -Filter "gdble.*.*.*" -ErrorAction SilentlyContinue | 
    ForEach-Object { $_.FullName }