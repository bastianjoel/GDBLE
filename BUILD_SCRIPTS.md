# Build Scripts

This directory contains build scripts that compile the GDBLE library with standard platform and architecture suffixes.

## Available Scripts

### `build.sh` (Linux/macOS)
Bash script for building on Linux and macOS systems.

### `build.ps1` (Windows)
PowerShell script for building on Windows systems.

## Usage

### Linux/macOS
```bash
chmod +x build.sh
./build.sh
```

### Windows
```powershell
.\build.ps1
```

## Android Build Requirements

To build for Android, you need to set the `ANDROID_NDK_HOME` environment variable:

```bash
export ANDROID_NDK_HOME=/path/to/ndk
```

Download Android NDK from: https://developer.android.com/ndk/downloads

**Note:** You also need to configure Cargo to use the Android NDK linkers. Create a `.cargo/config.toml` file with the appropriate linker paths. See the [Cargo Configuration](#cargo-configuration) section below.

## Output Files

The scripts create libraries with the following naming convention:

- **Windows**: `gdble.windows.x86_64.dll`
- **macOS x86_64**: `libgdble.macos.x86_64.dylib`
- **macOS ARM64**: `libgdble.macos.arm64.dylib`
- **Android ARM64**: `libgdble.android.arm64.so`
- **Android ARMv7**: `libgdble.android.armv7.so` (Not supported due to godot-ffi compatibility issues)
- **Android x86_64**: `libgdble.android.x86_64.so`

## Known Issues

### Android ARMv7 (32-bit) Architecture
Building for Android ARMv7 (`armv7-linux-androideabi`) is currently **not supported** due to compatibility issues with the `godot-ffi` library. The library contains code that causes compilation errors on 32-bit ARM architectures due to memory size calculation overflows.

**Error Details:**
```
error[E0080]: attempt to compute `48_usize - 88_usize`, which would overflow
```

**Workaround:**
- Use Android ARM64 (aarch64-linux-android) for ARM devices
- Use Android x86_64 for x86 emulators/devices

## Manual Build

If you prefer to build manually, you can use cargo directly:

```bash
# Windows
cargo build --release --target x86_64-pc-windows-msvc

# macOS x86_64
cargo build --release --target x86_64-apple-darwin

# macOS ARM64
cargo build --release --target aarch64-apple-darwin

# Android ARM64
cargo build --release --target aarch64-linux-android --no-default-features --features "android"

# Android ARMv7 (NOT SUPPORTED)
# cargo build --release --target armv7-linux-androideabi --no-default-features --features "android"

# Android x86_64
cargo build --release --target x86_64-linux-android --no-default-features --features "android"
```

## Cargo Configuration

For Android builds, you need to configure Cargo to use the Android NDK linkers. Create a `.cargo/config.toml` file in your project root:

```toml
[target.aarch64-linux-android]
ar = "D:\\AndroidSDK\\ndk\\27.0.12077973\\toolchains\\llvm\\prebuilt\\windows-x86_64\\bin\\llvm-ar.exe"
linker = "D:\\AndroidSDK\\ndk\\27.0.12077973\\toolchains\\llvm\\prebuilt\\windows-x86_64\\bin\\aarch64-linux-android21-clang.cmd"

[target.armv7-linux-androideabi]
ar = "D:\\AndroidSDK\\ndk\\27.0.12077973\\toolchains\\llvm\\prebuilt\\windows-x86_64\\bin\\llvm-ar.exe"
linker = "D:\\AndroidSDK\\ndk\\27.0.12077973\\toolchains\\llvm\\prebuilt\\windows-x86_64\\bin\\armv7-linux-androideabi21-clang.cmd"

[target.x86_64-linux-android]
ar = "D:\\AndroidSDK\\ndk\\27.0.12077973\\toolchains\\llvm\\prebuilt\\windows-x86_64\\bin\\llvm-ar.exe"
linker = "D:\\AndroidSDK\\ndk\\27.0.12077973\\toolchains\\llvm\\prebuilt\\windows-x86_64\\bin\\x86_64-linux-android21-clang.cmd"
```

**Note:** Adjust the paths according to your Android NDK installation location and version.

## Cross-Compilation

For cross-compilation, you need to install the appropriate Rust targets:

```bash
rustup target add aarch64-linux-android
rustup target add armv7-linux-androideabi
rustup target add x86_64-linux-android
rustup target add x86_64-apple-darwin
rustup target add aarch64-apple-darwin
rustup target add x86_64-pc-windows-msvc
```

For more information on cross-compilation, see: https://rust-lang.github.io/rustup/cross-compilation.html