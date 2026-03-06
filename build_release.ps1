param(
    [string]$Version = "1.0.0",
    [string]$AddonName = "order_objects"
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$distDir = Join-Path $projectRoot "dist"
$tmpRoot = Join-Path $distDir (".build_tmp_{0}_{1}" -f $AddonName, $PID)
$stagingDir = Join-Path $tmpRoot $AddonName
$zipName = "$AddonName-$Version-blender4.zip"
$zipPath = Join-Path $distDir $zipName

$filesToPackage = @(
    "__init__.py",
    "auto_load.py",
    "ui_hello.py",
    "README.md",
    "LICENSE"
)

foreach ($file in $filesToPackage) {
    $fullPath = Join-Path $projectRoot $file
    if (-not (Test-Path $fullPath)) {
        throw "Missing required file: $file"
    }
}

New-Item -ItemType Directory -Path $distDir -Force | Out-Null

if (Test-Path $tmpRoot) {
    throw "Temporary build directory already exists: $tmpRoot"
}

New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null

foreach ($file in $filesToPackage) {
    Copy-Item (Join-Path $projectRoot $file) -Destination (Join-Path $stagingDir $file) -Force
}

if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

Compress-Archive -Path $stagingDir -DestinationPath $zipPath -Force

# Controlled cleanup without recursive delete.
foreach ($file in $filesToPackage) {
    $stagedFile = Join-Path $stagingDir $file
    if (Test-Path $stagedFile) {
        Remove-Item $stagedFile -Force
    }
}
Remove-Item $stagingDir -Force
Remove-Item $tmpRoot -Force

Write-Host "ZIP created:" $zipPath
Write-Host "Install in Blender: Edit > Preferences > Add-ons > Install..."
