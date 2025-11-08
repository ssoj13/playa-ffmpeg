# Publish playa-ffmpeg to crates.io
# Usage: .\publish.ps1 [patch|minor|major] [rel]
#        .\publish.ps1           # dry-run patch
#        .\publish.ps1 minor     # dry-run minor
#        .\publish.ps1 patch rel # release patch

param(
    [string]$Level = 'patch',
    [string]$Mode = ''
)

$ErrorActionPreference = "Stop"

# Setup Visual Studio environment
$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vsWhere) {
    $vsInstallPath = & $vsWhere -latest -property installationPath
    if ($vsInstallPath) {
        $vcvarsPath = "$vsInstallPath\VC\Auxiliary\Build\vcvars64.bat"
        if (Test-Path $vcvarsPath) {
            $tempFile = [System.IO.Path]::GetTempFileName()
            cmd /c "`"$vcvarsPath`" && set" > $tempFile
            Get-Content $tempFile | ForEach-Object {
                if ($_ -match "^([^=]+)=(.*)$") {
                    [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
                }
            }
            Remove-Item $tempFile
        }
    }
}

# Setup vcpkg
$env:VCPKG_ROOT = "C:\vcpkg"
$env:PKG_CONFIG_PATH = "C:\vcpkg\installed\x64-windows-static-md\lib\pkgconfig"

# Run cargo-release
if ($Mode -eq 'rel') {
    cargo release $Level --execute
} else {
    Write-Host "DRY-RUN mode (add 'rel' argument to actually publish)" -ForegroundColor Yellow
    cargo release $Level
}
