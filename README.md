# rust-ffmpeg - Modern Fork with vcpkg Integration

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

[![build](https://github.com/ssoj13/playa-ffmpeg/workflows/build/badge.svg)](https://github.com/ssoj13/playa-ffmpeg/actions)

This is a fork of [ffmpeg-next](https://crates.io/crates/ffmpeg-next) (originally based on the [ffmpeg](https://crates.io/crates/ffmpeg) crate by [meh.](https://github.com/meh/rust-ffmpeg)).

This fork focuses on modern Rust (2024 edition) with FFmpeg 8.0 support and simplified cross-platform builds via vcpkg.

Documentation:

- [docs.rs](https://docs.rs/ffmpeg-next/);
- [FFmpeg user manual](https://ffmpeg.org/ffmpeg-all.html);
- [FFmpeg Doxygen](https://ffmpeg.org/doxygen/trunk/).

*Note on upgrading to v4.3.4 or later: v4.3.4 introduced automatic FFmpeg version detection, obsoleting feature flags `ffmpeg4`, `ffmpeg41`, `ffmpeg42` and `ffmpeg43`. If you manually specify any of these features, now is the time to remove them; if you use `ffmpeg43` through the `default` feature, it's still on for backward-compatibility but it has turned into a no-op, and you don't need to do anything. Deprecation plan: `ffmpeg43` will be dropped from default features come 4.4, and all these features will be removed come 5.0.*

*See [CHANGELOG.md](CHANGELOG.md) for other information on version upgrades.*

A word on versioning: major and minor versions of this crate track major and minor versions of FFmpeg, e.g. 4.2.x of this crate has been updated to support the 4.2.x series of FFmpeg. Patch level is reserved for changes to this crate and does not track FFmpeg patch versions. Since we can only freely bump the patch level, versioning of this crate differs from semver: minor versions may behave like semver major versions and introduce backward-incompatible changes; patch versions may behave like semver minor versions and introduce new APIs. Please peg the version you use accordingly.

**Please realize that this crate is in maintenance-only mode for the most part.** Which means I'll try my best to ensure the crate compiles against all release branches of FFmpeg 3.4 and later (only the latest patch release of each release branch is officially supported) and fix reported bugs, but if a new FFmpeg version brings new APIs that require significant effort to port to Rust, you might have to send me a PR (and just to be clear, I can't really guarantee I'll have the time to review). Any PR to improve existing API is unlikely to be merged, unfortunately.

🤝 **If you have significant, demonstrable experience in Rust and multimedia-related programming, please let me know, I'll be more than happy to invite you as a collaborator.** 🤝
