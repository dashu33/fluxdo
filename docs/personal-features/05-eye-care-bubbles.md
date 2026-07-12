# 05 护眼气泡 — 个人功能档案

源仓库改动已在 `D:\FLUXDO\fluxdo-pr` 落地。
生成物 `lib/l10n/slang/` 与 `app_localizations_compat.g.dart` 被 `.gitignore`，**不要手改提交**；PR / 本地应用后请执行：

```powershell
cd D:\FLUXDO\fluxdo-pr
dart run tool/gen_l10n.dart
```

## 功能
- 阅读设置 → **护眼气泡** 开关（默认关闭，`pref_eye_care_bubbles`）
- 楼主：绿色渐变卡片 `#d8edcc → #eaf6df`，边框 `#9fca88`（仅完整短帖用渐变）
- 回帖：暖黄卡片 `#fff8df`，边框 `#ead9a6`
- 长帖分段：`start/middle/end` 统一纯色 `card`，避免每段重画渐变造成绿色断层
- 引用块：开启护眼时用半透明白叠色，避免灰色盖住绿/黄底
- 覆盖：线性列表 `PostItem`、长帖分段、树形 `NestedPostCard`

## 改动文件（tracked）
见同目录 `05-eye-care-bubbles-changed-files.txt`。

## 归档到 fluxdo-personal-features

在 **本机终端** 执行（Claude 会话里对仓库外写权限不稳定）：

```powershell
$src = "D:\FLUXDO\fluxdo-pr"
$dst = "D:\FLUXDO\fluxdo-personal-features\05-eye-care-bubbles"
New-Item -ItemType Directory -Force -Path "$dst\files" | Out-Null
$files = Get-Content "$src\docs\personal-features\05-eye-care-bubbles-changed-files.txt"
$files | Set-Content -Encoding utf8 "$dst\changed-files.txt"
Copy-Item -Force "$src\docs\personal-features\05-eye-care-bubbles.md" "$dst\APPLY.md"
foreach ($f in $files) {
  $from = Join-Path $src ($f -replace '/', '\')
  if (-not (Test-Path $from)) { Write-Warning "missing $from"; continue }
  $to = Join-Path "$dst\files" ($f -replace '/', '\')
  New-Item -ItemType Directory -Force -Path (Split-Path $to) | Out-Null
  Copy-Item -Force $from $to
}
# 生成 diff（不含 gitignore 的 slang 生成物；应用后 gen_l10n）
git -C $src diff -- `
  lib/providers/preferences_provider.dart `
  lib/settings/definitions/reading_defs.dart `
  lib/l10n/modules/appearance `
  lib/widgets/post/post_item `
  lib/pages/topic_detail_page/widgets/topic_post_list.dart `
  lib/widgets/nested/nested_post_card.dart `
  lib/widgets/content/discourse_html_content/builders/eye_care_quote_style.dart `
  lib/widgets/content/discourse_html_content/builders/blockquote_builder.dart `
  lib/widgets/content/discourse_html_content/builders/quote_card_builder.dart `
  test/providers/preferences_provider_test.dart `
  test/widgets/post/eye_care_bubble_test.dart `
  > "$dst\0001-eye-care-bubbles-full.diff"

# 更新总 README
$readme = "D:\FLUXDO\fluxdo-personal-features\README.md"
$block = @"

## 5) 护眼气泡
目录: 05-eye-care-bubbles
- 阅读设置护眼气泡开关（默认关）
- 楼主绿 / 回帖暖黄楼层卡片
- 长帖分段纯色（避免渐变断层）
- 线性列表 + 长帖分段 + 树形视图
应用: 复制 files/ 覆盖后 `dart run tool/gen_l10n.dart`，或 git apply 0001-eye-care-bubbles-full.diff 再 gen_l10n
"@
if ((Get-Content $readme -Raw) -notmatch '05-eye-care-bubbles') {
  Add-Content -Path $readme -Value $block
}
Write-Host "Archived -> $dst"
```

## 验证
```powershell
cd D:\FLUXDO\fluxdo-pr
dart run tool/gen_l10n.dart
flutter test test/providers/preferences_provider_test.dart test/widgets/post/eye_care_bubble_test.dart
```

## 清理临时脚本（可选）
`tool/fix_eye_care_indent.dart` 仅为会话内修补缩进用，可删。
