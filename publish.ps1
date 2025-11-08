# Automated cargo-release wrapper for playa-ffmpeg
# Usage: .\publish.ps1 [patch|minor|major] [--dry-run]
#
# This script uses cargo-release to automate version bumping and publishing.
# Install: cargo install cargo-release

param(
    [Parameter(Position=0)]
    [ValidateSet('patch', 'minor', 'major')]
    [string]$Level = 'patch',

    [Parameter()]
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

Write-Host "=== playa-ffmpeg Release Script (cargo-release) ===" -ForegroundColor Cyan
Write-Host ""

# Set up Visual Studio environment (MSVC toolchain)
Write-Host "Setting up Visual Studio environment..." -ForegroundColor Yellow

$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $vsInstallPath = & $vsWhere -latest -property installationPath
    if ($vsInstallPath) {
        $vcvarsPath = "$vsInstallPath\VC\Auxiliary\Build\vcvars64.bat"
        if (Test-Path $vcvarsPath) {
            Write-Host "Found Visual Studio at: $vsInstallPath" -ForegroundColor Green

            # Run vcvars64.bat and capture environment variables
            $tempFile = [System.IO.Path]::GetTempFileName()
            cmd /c "`"$vcvarsPath`" && set" > $tempFile

            Get-Content $tempFile | ForEach-Object {
                if ($_ -match "^([^=]+)=(.*)$") {
                    [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
                }
            }
            Remove-Item $tempFile
            Write-Host "Visual Studio environment loaded" -ForegroundColor Green
        }
    }
} else {
    Write-Host "Visual Studio not found via vswhere" -ForegroundColor Yellow
    Write-Host "Attempting to continue - MSVC may not be available" -ForegroundColor Yellow
}

# Set vcpkg environment
$VCPKG_ROOT = "C:\vcpkg"
if (Test-Path $VCPKG_ROOT) {
    $env:VCPKG_ROOT = $VCPKG_ROOT
    Write-Host "Set VCPKG_ROOT=$VCPKG_ROOT" -ForegroundColor Green

    # Set PKG_CONFIG_PATH for vcpkg
    $TRIPLET = "x64-windows-static-md"
    $pkgConfigPath = "$VCPKG_ROOT\installed\$TRIPLET\lib\pkgconfig"
    if (Test-Path $pkgConfigPath) {
        $env:PKG_CONFIG_PATH = $pkgConfigPath
        Write-Host "Set PKG_CONFIG_PATH=$pkgConfigPath" -ForegroundColor Green
    }
} else {
    Write-Host "Warning: vcpkg not found at $VCPKG_ROOT" -ForegroundColor Yellow
}

Write-Host ""

# Check if cargo-release is installed
Write-Host "Checking for cargo-release..." -ForegroundColor Yellow
$cargoRelease = Get-Command cargo-release -ErrorAction SilentlyContinue

if (-not $cargoRelease) {
    Write-Host "cargo-release not found. Installing..." -ForegroundColor Yellow
    cargo install cargo-release

    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to install cargo-release" -ForegroundColor Red
        exit 1
    }

    Write-Host "cargo-release installed successfully" -ForegroundColor Green
} else {
    Write-Host "cargo-release is installed" -ForegroundColor Green
}

Write-Host ""

# Build cargo-release command
$releaseArgs = @($Level)

if ($DryRun) {
    Write-Host "Running in DRY-RUN mode (no actual changes)" -ForegroundColor Yellow
    Write-Host ""
} else {
    $releaseArgs += "--execute"
}

# Show what will happen
Write-Host "Running: cargo release $($releaseArgs -join ' ')" -ForegroundColor Cyan
Write-Host ""

# Run cargo-release
& cargo release @releaseArgs

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Release completed successfully!" -ForegroundColor Green

    if (-not $DryRun) {
        Write-Host ""
        Write-Host "View on crates.io: https://crates.io/crates/playa-ffmpeg" -ForegroundColor Cyan
        Write-Host "View on docs.rs:   https://docs.rs/playa-ffmpeg" -ForegroundColor Cyan
    }
} else {
    Write-Host ""
    Write-Host "Release failed!" -ForegroundColor Red
    exit 1
}
