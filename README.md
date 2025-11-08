# playa-ffmpeg - Modern FFmpeg Wrapper with vcpkg Integration

**Modified by:** Alex Joss (joss13@gmail.com)

This is a modernized fork with cross-platform build improvements and vcpkg integration.

## Key Modifications

- **vcpkg Integration**: Automatic FFmpeg installation and static linking on Windows/Linux/macOS
- **Rust 2024 Edition**: Updated to latest Rust edition with modern syntax
- **FFmpeg 8.0 Support**: Full support for FFmpeg 8.0 APIs
- **Cross-platform Build Scripts**:
  - `build.ps1` - Windows (PowerShell)
  - `build.sh` - Linux/macOS (unified script)
  - `build-mac.sh` - macOS-specific (zsh optimized)
- **Improved CI/CD**: Updated GitHub Actions workflows, modern action versions
- **Enhanced Examples**: New video-info tool, improved frame dumping
- **Static Linking**: Configured for static linking with vcpkg-provided libraries
- **Visual Studio Setup**: Automatic MSVC environment configuration on Windows

## Quick Start

### Windows
```powershell
.\build.ps1
```

### Linux/macOS
```bash
./build.sh
```

See [examples/README.md](examples/README.md) for usage examples.

## Publishing (Maintainers)

Uses [cargo-release](https://github.com/crate-ci/cargo-release). Install: `cargo install cargo-release`

**Dry-run (default):**
```powershell
.\publish.ps1        # preview patch release
.\publish.ps1 minor  # preview minor release
```

**Actual release:**
```powershell
.\publish.ps1 patch rel  # publish patch: 8.0.0 → 8.0.1
.\publish.ps1 minor rel  # publish minor: 8.0.0 → 8.1.0
.\publish.ps1 major rel  # publish major: 8.0.0 → 9.0.0
```

Linux/macOS: same, use `./publish.sh` instead

---

[![Crates.io](https://img.shields.io/crates/v/playa-ffmpeg.svg)](https://crates.io/crates/playa-ffmpeg)
[![Documentation](https://docs.rs/playa-ffmpeg/badge.svg)](https://docs.rs/playa-ffmpeg)
[![build](https://github.com/ssoj13/playa-ffmpeg/workflows/build/badge.svg)](https://github.com/ssoj13/playa-ffmpeg/actions)
[![License](https://img.shields.io/crates/l/playa-ffmpeg.svg)](LICENSE)

This is a fork of [ffmpeg-next](https://crates.io/crates/ffmpeg-next) (originally based on the [ffmpeg](https://crates.io/crates/ffmpeg) crate by [meh.](https://github.com/meh/rust-ffmpeg)).

This fork focuses on modern Rust (2024 edition) with FFmpeg 8.0 support and simplified cross-platform builds via vcpkg.

## Documentation

- [API docs](https://docs.rs/playa-ffmpeg/) - Rust API documentation
- [FFmpeg user manual](https://ffmpeg.org/ffmpeg-all.html) - Official FFmpeg manual
- [FFmpeg Doxygen](https://ffmpeg.org/doxygen/trunk/) - C API reference

See [CHANGELOG.md](CHANGELOG.md) for version history and upgrade notes.
