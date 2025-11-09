#!/usr/bin/env bash
# Bootstrap script for playa-ffmpeg
# Handles environment setup and runs build/publish commands
#
# Usage:
#   ./bootstrap.sh                        # Show help
#   ./bootstrap.sh build                  # Build release (default)
#   ./bootstrap.sh build --release        # Build release
#   ./bootstrap.sh build --debug          # Build debug
#   ./bootstrap.sh crate                  # Dry-run crate publish
#   ./bootstrap.sh crate publish          # Publish crate to crates.io

set -e

# Check if cargo is installed
if ! command -v cargo &> /dev/null; then
    echo "Error: Rust/Cargo not found!"
    echo ""
    echo "Please install Rust from: https://rustup.rs/"
    exit 1
fi

# Check command
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

show_help() {
    echo "playa-ffmpeg bootstrap"
    echo ""
    echo "Usage:"
    echo "  ./bootstrap.sh                        # Show this help"
    echo "  ./bootstrap.sh build                  # Build release (default)"
    echo "  ./bootstrap.sh build --release        # Build release"
    echo "  ./bootstrap.sh build --debug          # Build debug"
    echo "  ./bootstrap.sh format                 # Format code with cargo fmt"
    echo "  ./bootstrap.sh crate                  # Dry-run crate publish"
    echo "  ./bootstrap.sh crate publish          # Publish crate to crates.io"
    echo ""
}

build_project() {
    local build_mode="--release"

    if [ "$1" = "--debug" ]; then
        build_mode=""
    elif [ "$1" = "--release" ]; then
        build_mode="--release"
    fi

    echo "Building playa-ffmpeg $build_mode..."
    cargo build --examples $build_mode
}

format_code() {
    echo "Formatting code with cargo fmt..."
    cargo fmt
    echo "✓ Code formatted successfully"
}

publish_crate() {
    # Check if cargo-release is installed
    if ! cargo release --version &> /dev/null; then
        echo "Installing cargo-release..."
        cargo install cargo-release
    fi

    if [ "$1" = "publish" ]; then
        echo "Publishing crate to crates.io..."
        cargo release patch --execute --no-confirm
    else
        echo "Dry-run mode (use './bootstrap.sh crate publish' to actually publish)"
        echo "This will NOT modify any files, just show what would happen"
        cargo release patch --no-push --allow-branch HEAD
    fi
}

# Parse command
case "$1" in
    build)
        build_project "$2"
        ;;
    format)
        format_code
        ;;
    crate)
        publish_crate "$2"
        ;;
    *)
        show_help
        exit 1
        ;;
esac
