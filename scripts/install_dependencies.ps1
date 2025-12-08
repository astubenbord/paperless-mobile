# PowerShell script equivalent to install_dependencies.sh
$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir

Push-Location $rootDir

# Install dependencies for packages
$packagesDir = Join-Path $rootDir "packages"
if (Test-Path $packagesDir) {
    Get-ChildItem -Path $packagesDir -Directory | ForEach-Object {
        Push-Location $_.FullName
        Write-Host "Installing dependencies for $($_.Name)"
        flutter packages pub get
        dart run build_runner build --delete-conflicting-outputs
        Pop-Location
    }
}

# Install main dependencies
flutter packages pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs

Pop-Location
