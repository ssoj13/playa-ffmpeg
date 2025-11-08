# Unified vcpkg setup script for rust-ffmpeg on Windows
# Usage: .\build.ps1

$ErrorActionPreference = "Stop"

Write-Host "=== rust-ffmpeg vcpkg setup ===" -ForegroundColor Cyan
Write-Host ""

$VCPKG_ROOT = "C:\vcpkg"
$TRIPLET = "x64-windows-static-md"

Write-Host "Detected: Windows"
Write-Host "vcpkg triplet: $TRIPLET"
Write-Host ""

# Check if vcpkg is already installed
if (Test-Path $VCPKG_ROOT) {
    Write-Host "vcpkg already installed at $VCPKG_ROOT" -ForegroundColor Green
} else {
    Write-Host "Installing vcpkg..." -ForegroundColor Yellow
    git clone https://github.com/microsoft/vcpkg.git $VCPKG_ROOT
    Set-Location $VCPKG_ROOT
    .\bootstrap-vcpkg.bat
    Write-Host "vcpkg installed" -ForegroundColor Green
}

# Set up Visual Studio environment (MSVC toolchain)
Write-Host ""
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

# Set environment variables
Write-Host ""
Write-Host "Setting up vcpkg environment..." -ForegroundColor Yellow

$currentVcpkgRoot = [Environment]::GetEnvironmentVariable("VCPKG_ROOT", "User")
if ($currentVcpkgRoot -ne $VCPKG_ROOT) {
    [Environment]::SetEnvironmentVariable("VCPKG_ROOT", $VCPKG_ROOT, "User")
    $env:VCPKG_ROOT = $VCPKG_ROOT
    Write-Host "Set VCPKG_ROOT=$VCPKG_ROOT" -ForegroundColor Green
} else {
    Write-Host "VCPKG_ROOT already set" -ForegroundColor Green
}

# Set PKG_CONFIG_PATH for vcpkg
$pkgConfigPath = "$VCPKG_ROOT\installed\$TRIPLET\lib\pkgconfig"
if (Test-Path $pkgConfigPath) {
    $env:PKG_CONFIG_PATH = $pkgConfigPath
    Write-Host "Set PKG_CONFIG_PATH=$pkgConfigPath" -ForegroundColor Green
}

# Check for LLVM (required for bindgen)
Write-Host ""
Write-Host "Checking for LLVM..." -ForegroundColor Yellow

# Check vcpkg LLVM first
$vcpkgLlvmPath = "$VCPKG_ROOT\installed\$TRIPLET\tools\llvm\clang.exe"
$llvmFound = $false

if (Test-Path $vcpkgLlvmPath) {
    Write-Host "LLVM found in vcpkg: $vcpkgLlvmPath" -ForegroundColor Green
    $env:LIBCLANG_PATH = "$VCPKG_ROOT\installed\$TRIPLET\tools\llvm"
    $llvmFound = $true
} else {
    # Check PATH
    $llvmPath = Get-Command clang -ErrorAction SilentlyContinue
    if ($null -ne $llvmPath) {
        Write-Host "LLVM found in PATH: $($llvmPath.Source)" -ForegroundColor Green
        $llvmFound = $true
    }
}

if (-not $llvmFound) {
    Write-Host "LLVM not found. Installing via vcpkg..." -ForegroundColor Yellow
    & "$VCPKG_ROOT\vcpkg.exe" install llvm:$TRIPLET

    if (Test-Path $vcpkgLlvmPath) {
        Write-Host "LLVM installed" -ForegroundColor Green
        $env:LIBCLANG_PATH = "$VCPKG_ROOT\installed\$TRIPLET\tools\llvm"
    } else {
        Write-Host "LLVM installation failed. Please install manually:" -ForegroundColor Red
        Write-Host "  vcpkg install llvm:$TRIPLET" -ForegroundColor Red
        Write-Host "  Or download from: https://releases.llvm.org/download.html" -ForegroundColor Red
        exit 1
    }
}

# Install FFmpeg via vcpkg
Write-Host ""
Write-Host "Installing FFmpeg ${TRIPLET} via vcpkg..." -ForegroundColor Yellow
Write-Host "This may take 30-60 minutes on first run..." -ForegroundColor Yellow

& "$VCPKG_ROOT\vcpkg.exe" install ffmpeg:$TRIPLET

Write-Host "FFmpeg installed" -ForegroundColor Green

# Return to project directory
Set-Location $PSScriptRoot

# Build rust-ffmpeg
Write-Host ""
Write-Host "Building rust-ffmpeg..." -ForegroundColor Yellow

cargo build --release

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Green
Write-Host ""

# Show library info
Write-Host "Binary location: target\release\"
Write-Host "Binary size:"

$libPath = Get-ChildItem "target\release\ffmpeg_next.dll" -ErrorAction SilentlyContinue
if ($libPath) {
    $size = $libPath.Length / 1MB
    Write-Host "  ffmpeg_next.dll: $([math]::Round($size, 2)) MB"
} else {
    Write-Host "  (library built)"
}

Write-Host ""
Write-Host "Environment:"
Write-Host "  VCPKG_ROOT=$env:VCPKG_ROOT"
Write-Host ""
Write-Host "You can now build with: cargo build --release"
