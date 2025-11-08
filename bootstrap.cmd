@echo off
:: Bootstrap script for playa-ffmpeg
:: Handles environment setup and runs build/publish commands
::
:: Usage:
::   bootstrap.cmd                        # Show help
::   bootstrap.cmd build                  # Build release (default)
::   bootstrap.cmd build --release        # Build release
::   bootstrap.cmd build --debug          # Build debug
::   bootstrap.cmd crate                  # Dry-run crate publish
::   bootstrap.cmd crate publish          # Publish crate to crates.io

setlocal enabledelayedexpansion

:: Check if cargo is installed
where cargo >nul 2>&1
if errorlevel 1 (
    echo Error: Rust/Cargo not found!
    echo.
    echo Please install Rust from: https://rustup.rs/
    exit /b 1
)

:: Setup Visual Studio environment
echo Setting up build environment...
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if exist "%VSWHERE%" (
    for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -property installationPath`) do (
        set "VCVARS=%%i\VC\Auxiliary\Build\vcvars64.bat"
        if exist "!VCVARS!" (
            call "!VCVARS!" >nul 2>&1
            echo ✓ Visual Studio environment configured
        )
    )
)

:: Setup vcpkg
if exist "C:\vcpkg" (
    set "VCPKG_ROOT=C:\vcpkg"
    set "PKG_CONFIG_PATH=C:\vcpkg\installed\x64-windows-static-md\lib\pkgconfig"
    echo ✓ vcpkg configured
)
echo.

:: Parse command
if "%~1"=="" goto :help
if /i "%~1"=="build" goto :build
if /i "%~1"=="crate" goto :crate
goto :help

:build
    :: Check for debug/release flag
    set "BUILD_MODE=--release"
    if /i "%~2"=="--debug" set "BUILD_MODE="
    if /i "%~2"=="--release" set "BUILD_MODE=--release"

    echo Building playa-ffmpeg %BUILD_MODE%...
    cargo build --examples %BUILD_MODE%
    exit /b %errorlevel%

:crate
    :: Check if cargo-release is installed
    cargo release --version >nul 2>&1
    if errorlevel 1 (
        echo Installing cargo-release...
        cargo install cargo-release
        if errorlevel 1 (
            echo Error: Failed to install cargo-release
            exit /b 1
        )
    )

    if /i "%~2"=="publish" (
        echo Publishing crate to crates.io...
        cargo release --execute
    ) else (
        echo Dry-run crate publish (add 'publish' to actually release)...
        cargo release
    )
    exit /b %errorlevel%

:help
    echo playa-ffmpeg bootstrap
    echo.
    echo Usage:
    echo   bootstrap.cmd                        # Show this help
    echo   bootstrap.cmd build                  # Build release (default)
    echo   bootstrap.cmd build --release        # Build release
    echo   bootstrap.cmd build --debug          # Build debug
    echo   bootstrap.cmd crate                  # Dry-run crate publish
    echo   bootstrap.cmd crate publish          # Publish crate to crates.io
    echo.
    exit /b 0

endlocal
