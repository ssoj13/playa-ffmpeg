#!/bin/bash
# Publish playa-ffmpeg to crates.io
# Usage: ./publish.sh [patch|minor|major] [rel]
#        ./publish.sh           # dry-run patch
#        ./publish.sh minor     # dry-run minor
#        ./publish.sh patch rel # release patch

set -e

LEVEL="${1:-patch}"
MODE="${2:-}"

# Run cargo-release
if [ "$MODE" = "rel" ]; then
    cargo release "$LEVEL" --execute
else
    echo "DRY-RUN mode (add 'rel' argument to actually publish)"
    cargo release "$LEVEL"
fi
