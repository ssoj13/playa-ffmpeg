#!/bin/bash
# Automated version bump and cargo publish script
# Usage: ./publish.sh [patch|minor|major]

set -e

BUMP_TYPE="${1:-patch}"

if [[ ! "$BUMP_TYPE" =~ ^(patch|minor|major)$ ]]; then
    echo "Usage: $0 [patch|minor|major]"
    exit 1
fi

echo "=== playa-ffmpeg Release Script ==="
echo ""

# Read current version from Cargo.toml
if grep -q 'version *= *"[0-9]\+\.[0-9]\+\.[0-9]\+"' Cargo.toml; then
    CURRENT_VERSION=$(grep 'version *= *"[0-9]\+\.[0-9]\+\.[0-9]\+"' Cargo.toml | head -1 | sed 's/.*"\([0-9.]*\)".*/\1/')
    IFS='.' read -r MAJOR MINOR PATCH <<< "$CURRENT_VERSION"
else
    echo "❌ Failed to parse version from Cargo.toml"
    exit 1
fi

echo "Current version: $CURRENT_VERSION"

# Bump version
case "$BUMP_TYPE" in
    major)
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    minor)
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    patch)
        PATCH=$((PATCH + 1))
        ;;
esac

NEW_VERSION="$MAJOR.$MINOR.$PATCH"
echo "New version:     $NEW_VERSION"
echo ""

# Confirm
read -p "Publish version $NEW_VERSION? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# Check git status
echo "Checking git status..."
if [ -n "$(git status --porcelain)" ]; then
    echo "⚠ Warning: Working directory has uncommitted changes:"
    git status --short
    read -p "Continue anyway? (yes/no): " CONFIRM_DIRTY
    if [ "$CONFIRM_DIRTY" != "yes" ]; then
        echo "Aborted."
        exit 0
    fi
fi

# Update Cargo.toml
echo ""
echo "Updating Cargo.toml..."
sed -i.bak "0,/version *= *\"[0-9.]*\"/s//version = \"$NEW_VERSION\"/" Cargo.toml
rm -f Cargo.toml.bak

# Update Cargo.lock
echo "Updating Cargo.lock..."
cargo update -p playa-ffmpeg --precise "$NEW_VERSION"

# Run tests
echo ""
echo "Running tests..."
if ! cargo test --release; then
    echo "❌ Tests failed. Aborting."
    git checkout Cargo.toml Cargo.lock
    exit 1
fi

# Build release
echo ""
echo "Building release..."
if ! cargo build --release; then
    echo "❌ Build failed. Aborting."
    git checkout Cargo.toml Cargo.lock
    exit 1
fi

# Commit version bump
echo ""
echo "Committing version bump..."
git add Cargo.toml Cargo.lock
git commit -m "Bump version to $NEW_VERSION

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
"

# Create git tag
echo "Creating git tag v$NEW_VERSION..."
git tag -a "v$NEW_VERSION" -m "Release v$NEW_VERSION"

# Push to remote
echo "Pushing to remote..."
git push origin dev
git push origin "v$NEW_VERSION"

# Publish to crates.io
echo ""
echo "Publishing to crates.io..."
if cargo publish; then
    echo ""
    echo "✅ Successfully published playa-ffmpeg v$NEW_VERSION!"
    echo ""
    echo "View on crates.io: https://crates.io/crates/playa-ffmpeg"
    echo "View on docs.rs:   https://docs.rs/playa-ffmpeg/$NEW_VERSION"
else
    echo ""
    echo "❌ Cargo publish failed!"
    echo "⚠ The version has been bumped and tagged locally."
    echo "⚠ You may need to manually resolve the issue and run 'cargo publish' again."
    exit 1
fi
