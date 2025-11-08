# playa-ffmpeg - Modern FFmpeg Wrapper with vcpkg Integration

**Modified by:** Alex Joss (joss13@gmail.com)

This is a modernized fork with cross-platform build improvements and vcpkg integration.

## Key Modifications

- **vcpkg Integration**: Automatic FFmpeg installation and static linking on Windows/Linux/macOS
- **Rust 2024 Edition**: Updated to latest Rust edition with modern syntax
- **FFmpeg 8.0 Support**: Full support for FFmpeg 8.0 APIs
- **Unified Bootstrap Script**: Single script for building and publishing across all platforms
- **Improved CI/CD**: Updated GitHub Actions workflows, modern action versions
- **Enhanced Examples**: New video-info tool, improved frame dumping
- **Static Linking**: Configured for static linking with vcpkg-provided libraries
- **Visual Studio Setup**: Automatic MSVC environment configuration on Windows

## Quick Start

### Windows
```cmd
bootstrap.cmd build
```

### Linux/macOS
```bash
./bootstrap.sh build
```

See [examples/README.md](examples/README.md) for usage examples.

## Build Options

```bash
bootstrap build           # Build release (default)
bootstrap build --release # Build release (explicit)
bootstrap build --debug   # Build debug
```

## Publishing (Maintainers)

```bash
bootstrap crate          # Dry-run (preview changes)
bootstrap crate publish  # Publish to crates.io
```

Uses [cargo-release](https://github.com/crate-ci/cargo-release) - automatically installed on first use.

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
