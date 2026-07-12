# 把护眼气泡功能归档到 D:\FLUXDO\fluxdo-personal-features\05-eye-care-bubbles
# 用法（在已配置 Flutter PATH 的 PowerShell 中）:
#   cd D:\FLUXDO\fluxdo-pr
#   powershell -ExecutionPolicy Bypass -File docs\personal-features\archive-05-eye-care-bubbles.ps1

$ErrorActionPreference = 'Stop'
$src = 'D:\FLUXDO\fluxdo-pr'
$dst = 'D:\FLUXDO\fluxdo-personal-features\05-eye-care-bubbles'

$files = @(
  'lib/providers/preferences_provider.dart',
  'lib/settings/definitions/reading_defs.dart',
  'lib/l10n/modules/appearance/appearance_en.arb',
  'lib/l10n/modules/appearance/appearance_zh.arb',
  'lib/l10n/modules/appearance/appearance_zh_HK.arb',
  'lib/l10n/modules/appearance/appearance_zh_TW.arb',
  'lib/widgets/post/post_item/widgets/post_segment_frame.dart',
  'lib/widgets/post/post_item/post_item.dart',
  'lib/widgets/post/post_item/segmented_long_post.dart',
  'lib/pages/topic_detail_page/widgets/topic_post_list.dart',
  'lib/widgets/nested/nested_post_card.dart',
  'lib/widgets/content/discourse_html_content/builders/eye_care_quote_style.dart',
  'lib/widgets/content/discourse_html_content/builders/blockquote_builder.dart',
  'lib/widgets/content/discourse_html_content/builders/quote_card_builder.dart',
  'test/providers/preferences_provider_test.dart',
  'test/widgets/post/eye_care_bubble_test.dart'
)

$genFiles = @(
  'lib/l10n/slang/strings_en.g.dart',
  'lib/l10n/slang/strings_zh.g.dart',
  'lib/l10n/slang/strings_zh_HK.g.dart',
  'lib/l10n/slang/strings_zh_TW.g.dart',
  'lib/l10n/generated/app_localizations_compat.g.dart'
)

New-Item -ItemType Directory -Force -Path "$dst\files" | Out-Null
$files | Set-Content -Encoding utf8 "$dst\changed-files.txt"

foreach ($f in $files) {
  $from = Join-Path $src ($f -replace '/', '\')
  if (-not (Test-Path $from)) { Write-Warning "missing: $from"; continue }
  $to = Join-Path "$dst\files" ($f -replace '/', '\')
  New-Item -ItemType Directory -Force -Path (Split-Path $to) | Out-Null
  Copy-Item -Force $from $to
  Write-Host "copied $f"
}

foreach ($f in $genFiles) {
  $from = Join-Path $src ($f -replace '/', '\')
  if (-not (Test-Path $from)) { continue }
  $to = Join-Path "$dst\files" ($f -replace '/', '\')
  New-Item -ItemType Directory -Force -Path (Split-Path $to) | Out-Null
  Copy-Item -Force $from $to
  Write-Host "copied gen $f"
}

$apply = @'
# 05 护眼气泡

源: D:\FLUXDO\fluxdo-pr

## 功能
- 阅读设置「护眼气泡」开关（默认关，pref_eye_care_bubbles）
- 楼主绿 / 回帖暖黄
- 线性列表 + 长帖分段 + 树形视图

## 应用
```powershell
$src = "D:\FLUXDO\fluxdo-personal-features\05-eye-care-bubbles\files"
$dst = "D:\FLUXDO\fluxdo-pr"
Get-Content "D:\FLUXDO\fluxdo-personal-features\05-eye-care-bubbles\changed-files.txt" | ForEach-Object {
  $from = Join-Path $src ($_ -replace '/', '\')
  $to = Join-Path $dst ($_ -replace '/', '\')
  New-Item -ItemType Directory -Force -Path (Split-Path $to) | Out-Null
  Copy-Item -Force $from $to
}
# $env:Path = "D:\dev\flutter\bin;$env:Path"
# dart run tool/gen_l10n.dart
```

或:
```powershell
git -C D:\FLUXDO\fluxdo-pr apply --3way D:\FLUXDO\fluxdo-personal-features\05-eye-care-bubbles\0001-eye-care-bubbles-full.diff
```
'@
Set-Content -Encoding utf8 -Path "$dst\APPLY.md" -Value $apply

Push-Location $src
try {
  git diff -- $files > "$dst\0001-eye-care-bubbles-full.diff"
} finally {
  Pop-Location
}

# 更新总 README
$readme = 'D:\FLUXDO\fluxdo-personal-features\README.md'
$block = @"

## 5) 护眼气泡
目录: 05-eye-care-bubbles
- 阅读设置护眼气泡开关（默认关）
- 楼主绿 / 回帖暖黄楼层卡片
- 线性列表 + 长帖分段 + 树形视图
应用: 复制 files/ 覆盖后 dart run tool/gen_l10n.dart
  或 git apply --3way D:\FLUXDO\fluxdo-personal-features\05-eye-care-bubbles\0001-eye-care-bubbles-full.diff
归档脚本: D:\FLUXDO\fluxdo-pr\docs\personal-features\archive-05-eye-care-bubbles.ps1
"@
if (Test-Path $readme) {
  $text = Get-Content -Raw $readme
  if ($text -notmatch '05-eye-care-bubbles') {
    Add-Content -Path $readme -Value $block
    Write-Host 'README updated'
  } else {
    Write-Host 'README already has 05 entry'
  }
}

Write-Host ""
Write-Host "Archived -> $dst"
Get-ChildItem -Recurse $dst | Select-Object FullName
