$ErrorActionPreference = 'Stop'

$projectPath = 'C:\Users\mortz\Documents\Projects\gymrat'
$flutter = 'C:\Users\mortz\Documents\flutter\bin\flutter.bat'
$sourceRoot = $PSScriptRoot
$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$backupRoot = Join-Path $env:USERPROFILE "Desktop\gymrat_reward_v1_backup_$timestamp"

$files = @(
  'lib\core\localization\gymrat_localizations.dart',
  'lib\features\workout\presentation\workout_complete_screen.dart',
  'lib\features\rewards\presentation\reward_sequence.dart',
  'lib\features\rewards\presentation\pr_celebration.dart',
  'lib\features\rewards\presentation\level_up_celebration.dart'
)

if (-not (Test-Path (Join-Path $projectPath 'pubspec.yaml'))) {
  throw "GymRat project not found at $projectPath"
}

if (-not (Test-Path $flutter)) {
  throw "Flutter not found at $flutter"
}

foreach ($relativePath in $files) {
  $source = Join-Path $sourceRoot $relativePath
  $target = Join-Path $projectPath $relativePath
  $backup = Join-Path $backupRoot $relativePath

  if (-not (Test-Path $source)) {
    throw "Missing installation file: $source"
  }

  if (Test-Path $target) {
    New-Item -ItemType Directory -Path (Split-Path $backup) -Force | Out-Null
    Copy-Item -Path $target -Destination $backup -Force
  }

  New-Item -ItemType Directory -Path (Split-Path $target) -Force | Out-Null
  Copy-Item -Path $source -Destination $target -Force
}

Push-Location $projectPath
try {
  & $flutter pub get
  if ($LASTEXITCODE -ne 0) {
    throw 'flutter pub get failed.'
  }

  & $flutter analyze
  if ($LASTEXITCODE -ne 0) {
    throw 'flutter analyze found an error. Restore from the backup on Desktop.'
  }
}
finally {
  Pop-Location
}

Write-Host ''
Write-Host 'GymRat Reward System v1 installed successfully.' -ForegroundColor Green
Write-Host "Backup: $backupRoot"
Write-Host 'Open Android Studio and run the app in the emulator.'
