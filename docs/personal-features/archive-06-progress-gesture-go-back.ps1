# 把进度悬浮条「返回」功能归档到 D:\FLUXDO\fluxdo-personal-features\06-progress-gesture-go-back
# 用法:
#   cd D:\FLUXDO\fluxdo-pr
#   powershell -ExecutionPolicy Bypass -File docs\personal-features\archive-06-progress-gesture-go-back.ps1

$ErrorActionPreference = 'Stop'
$src = 'D:\FLUXDO\fluxdo-pr'
$dst = 'D:\FLUXDO\fluxdo-personal-features\06-progress-gesture-go-back'
$files = Get-Content "$src\docs\personal-features\06-progress-gesture-go-back-changed-files.txt"
$genFiles = @(
  'lib/l10n/slang/strings_en.g.dart',
  'lib/l10n/slang/strings_zh.g.dart',
  'lib/l10n/slang/strings_zh_HK.g.dart',
  'lib/l10n/slang/strings_zh_TW.g.dart',
  'lib/l10n/generated/app_localizations_compat.g.dart'
)

New-Item -ItemType Directory -Force -Path "$dst\files" | Out-Null
$files | Set-Content -Encoding utf8 "$dst\changed-files.txt"
Copy-Item -Force "$src\docs\personal-features\06-progress-gesture-go-back.md" "$dst\APPLY.md"

foreach ($f in $files + $genFiles) {
  $from = Join-Path $src ($f -replace '/', '\')
  if (-not (Test-Path $from)) { Write-Warning "missing: $from"; continue }
  $to = Join-Path "$dst\files" ($f -replace '/', '\')
  New-Item -ItemType Directory -Force -Path (Split-Path $to) | Out-Null
  Copy-Item -Force $from $to
  Write-Host "copied $f"
}

Push-Location $src
try {
  git show HEAD -- $files > "$dst\0001-progress-gesture-go-back-full.diff"
} finally {
  Pop-Location
}
Write-Host "archived to $dst"
