# Automated version bump and cargo publish script
# Usage: .\publish.ps1 [patch|minor|major]

param(
    [Parameter(Position=0)]
    [ValidateSet('patch', 'minor', 'major')]
    [string]$BumpType = 'patch'
)

$ErrorActionPreference = "Stop"

Write-Host "=== playa-ffmpeg Release Script ===" -ForegroundColor Cyan
Write-Host ""

# Read current version from Cargo.toml
$cargoToml = Get-Content "Cargo.toml" -Raw
if ($cargoToml -match 'version\s*=\s*"(\d+)\.(\d+)\.(\d+)"') {
    $major = [int]$matches[1]
    $minor = [int]$matches[2]
    $patch = [int]$matches[3]
    $currentVersion = "$major.$minor.$patch"
} else {
    Write-Host "Failed to parse version from Cargo.toml" -ForegroundColor Red
    exit 1
}

Write-Host "Current version: $currentVersion" -ForegroundColor Yellow

# Bump version
switch ($BumpType) {
    'major' {
        $major++
        $minor = 0
        $patch = 0
    }
    'minor' {
        $minor++
        $patch = 0
    }
    'patch' {
        $patch++
    }
}

$newVersion = "$major.$minor.$patch"
Write-Host "New version:     $newVersion" -ForegroundColor Green
Write-Host ""

# Confirm
$confirm = Read-Host "Publish version $newVersion? (yes/no)"
if ($confirm -ne 'yes') {
    Write-Host "Aborted." -ForegroundColor Yellow
    exit 0
}

# Check git status
Write-Host "Checking git status..." -ForegroundColor Yellow
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "Warning: Working directory has uncommitted changes:" -ForegroundColor Yellow
    Write-Host $gitStatus
    $confirmDirty = Read-Host "Continue anyway? (yes/no)"
    if ($confirmDirty -ne 'yes') {
        Write-Host "Aborted." -ForegroundColor Yellow
        exit 0
    }
}

# Update Cargo.toml
Write-Host ""
Write-Host "Updating Cargo.toml..." -ForegroundColor Yellow
$cargoToml = $cargoToml -replace 'version\s*=\s*"\d+\.\d+\.\d+"', "version = `"$newVersion`""
$cargoToml | Set-Content "Cargo.toml" -NoNewline

# Update Cargo.lock
Write-Host "Updating Cargo.lock..." -ForegroundColor Yellow
cargo update -p playa-ffmpeg --precise $newVersion

# Run tests
Write-Host ""
Write-Host "Running tests..." -ForegroundColor Yellow
cargo test --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Tests failed. Aborting." -ForegroundColor Red
    git checkout Cargo.toml Cargo.lock
    exit 1
}

# Build release
Write-Host ""
Write-Host "Building release..." -ForegroundColor Yellow
cargo build --release
if ($LASTEXITCODE -ne 0) {
    Write-Host "Build failed. Aborting." -ForegroundColor Red
    git checkout Cargo.toml Cargo.lock
    exit 1
}

# Commit version bump
Write-Host ""
Write-Host "Committing version bump..." -ForegroundColor Yellow
git add Cargo.toml Cargo.lock
git commit -m "Bump version to $newVersion

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
"

# Create git tag
Write-Host "Creating git tag v$newVersion..." -ForegroundColor Yellow
git tag -a "v$newVersion" -m "Release v$newVersion"

# Push to remote
Write-Host "Pushing to remote..." -ForegroundColor Yellow
git push origin dev
git push origin "v$newVersion"

# Publish to crates.io
Write-Host ""
Write-Host "Publishing to crates.io..." -ForegroundColor Yellow
cargo publish

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Successfully published playa-ffmpeg v$newVersion!" -ForegroundColor Green
    Write-Host ""
    Write-Host "View on crates.io: https://crates.io/crates/playa-ffmpeg" -ForegroundColor Cyan
    Write-Host "View on docs.rs:   https://docs.rs/playa-ffmpeg/$newVersion" -ForegroundColor Cyan
} else {
    Write-Host ""
    Write-Host "Cargo publish failed!" -ForegroundColor Red
    Write-Host "The version has been bumped and tagged locally." -ForegroundColor Yellow
    Write-Host "You may need to manually resolve the issue and run 'cargo publish' again." -ForegroundColor Yellow
    exit 1
}
