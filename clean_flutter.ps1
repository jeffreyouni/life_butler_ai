<#
  clean_flutter.ps1
  递归清理 Flutter / Dart 项目的产物。
  用法：
    实际删除：   .\clean_flutter.ps1
    预演(DryRun)：.\clean_flutter.ps1 -DryRun
#>

[CmdletBinding()]
param(
  [switch]$DryRun
)

Write-Host "Cleaning Flutter/Dart project..." -ForegroundColor Cyan

# --- 工具函数 ---
function Remove-PathSafe([string]$PathToRemove) {
  if (Test-Path -LiteralPath $PathToRemove) {
    if ($DryRun) {
      Write-Host "[DryRun] Would remove: $PathToRemove"
    } else {
      try {
        Remove-Item -LiteralPath $PathToRemove -Recurse -Force -ErrorAction Stop
        Write-Host "Removed: $PathToRemove" -ForegroundColor Yellow
      } catch {
        Write-Warning "Failed to remove $PathToRemove : $($_.Exception.Message)"
      }
    }
  }
}

# --- 1) 优先清已知固定路径 ---
$rootSpecificPaths = @(
  # Android
  "android/.gradle",
  "android/app/build",

  # iOS
  "ios/Pods",
  "ios/.symlinks",
  "ios/Flutter/Flutter.framework",
  "ios/Flutter/Flutter.podspec",

  # Web
  "web/.dart_tool"
)

foreach ($p in $rootSpecificPaths) { Remove-PathSafe $p }

# --- 2) 递归删除“按目录名匹配”的构建目录（任意子目录层级） ---
$dirNamesToRemove = @(
  ".dart_tool",
  ".flutter-plugins",
  ".flutter-plugins-dependencies",
  ".packages",
  ".pub",
  ".pub-cache",
  "build",
  ".gradle",
  "Pods",
  ".symlinks"
)

# 获取任意层级中的目标目录名
$dirsFound = Get-ChildItem -Path . -Recurse -Directory -Force -ErrorAction SilentlyContinue |
  Where-Object { $dirNamesToRemove -contains $_.Name } |
  Sort-Object FullName -Descending -Unique  # 先删子目录，避免父目录先删导致错误

foreach ($d in $dirsFound) {
  Remove-PathSafe $d.FullName
}

# --- 3) 递归删除常见临时/锁文件 ---
$filesToRemove = @(
  "pubspec.lock",                 # 如是 App 想锁依赖可注释掉
  "pubspec_overrides.yaml",
  "Podfile.lock",
  "*.iml",                        # IntelliJ/Android Studio
  ".DS_Store",                    # macOS
  "*.bak",                        # 备份
  "flutter_export_environment.sh" # 构建生成
)

# 注意：-Include 在没有通配符路径时可能不生效，这里为稳定起见显式加 '\*'
$rootPath = (Resolve-Path .).Path
foreach ($pattern in $filesToRemove) {
  $files = Get-ChildItem -Path "$rootPath\*" -Recurse -File -Include $pattern -Force -ErrorAction SilentlyContinue
  foreach ($f in $files) {
    if ($DryRun) {
      Write-Host "[DryRun] Would remove file: $($f.FullName)"
    } else {
      try {
        Remove-Item -LiteralPath $f.FullName -Force -ErrorAction Stop
        Write-Host "Removed file: $($f.FullName)" -ForegroundColor Yellow
      } catch {
        Write-Warning "Failed to remove file $($f.FullName): $($_.Exception.Message)"
      }
    }
  }
}

if ($DryRun) {
  Write-Host "Dry run completed. No files were actually deleted." -ForegroundColor Cyan
} else {
  Write-Host "Flutter project cleaned. Ready for GitHub commit!" -ForegroundColor Green
}
