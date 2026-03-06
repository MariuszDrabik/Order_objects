param(
    [string]$Version = "1.0.0",
    [string]$AddonName = "order_objects"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$distDir = Join-Path $projectRoot "dist"
$stagingDir = Join-Path $distDir $AddonName
$zipName = "$AddonName-$Version-blender4.zip"
$zipPath = Join-Path $distDir $zipName

$filesToPackage = @(
    "__init__.py",
    "auto_load.py",
    "ui_hello.py"
)

foreach ($file in $filesToPackage) {
    $fullPath = Join-Path $projectRoot $file
    if (-not (Test-Path $fullPath)) {
        throw "Missing required file: $file"
    }
}

if (Test-Path $stagingDir) {
    Remove-Item $stagingDir -Recurse -Force
}

New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

foreach ($file in $filesToPackage) {
    Copy-Item (Join-Path $projectRoot $file) -Destination (Join-Path $stagingDir $file) -Force
}

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Compress-Archive -Path $stagingDir -DestinationPath $zipPath -Force

Write-Host "ZIP created:" $zipPath
Write-Host "Install in Blender: Edit > Preferences > Add-ons > Install..."
