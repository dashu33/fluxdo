# 06 进度悬浮条「返回」动作

源: D:\FLUXDO\fluxdo-pr

## 功能
- ProgressGestureAction 新增 goBack
- 进度悬浮条滑动手势 / 长按半圆菜单可选「返回」
- 触发后 Navigator.maybePop() 退出帖子页
- 解决手机上顶部返回不便的问题

## 应用
```powershell
$src = "D:\FLUXDO\fluxdo-personal-features\06-progress-gesture-go-back\files"
$dst = "D:\FLUXDO\fluxdo-pr"
Get-Content "D:\FLUXDO\fluxdo-personal-features\06-progress-gesture-go-back\changed-files.txt" | ForEach-Object {
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
git -C D:\FLUXDO\fluxdo-pr apply --3way D:\FLUXDO\fluxdo-personal-features\06-progress-gesture-go-back\0001-progress-gesture-go-back-full.diff
# 或
git -C D:\FLUXDO\fluxdo-pr am --3way D:\FLUXDO\fluxdo-personal-features\06-progress-gesture-go-back\0001-feat-add-go-back-progress-gesture-action.patch
```
