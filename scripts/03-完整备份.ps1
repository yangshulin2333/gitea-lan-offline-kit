. "$PSScriptRoot\公共函数.ps1"
Assert-Admin
$root = Get-InstallRoot
$service = Assert-OwnedService $root
$config = "$root\custom\conf\app.ini"
foreach ($pair in @(@('database','PATH'),@('repository','ROOT'),@('lfs','PATH'),@('server','APP_DATA_PATH'),@('log','ROOT_PATH'))) {
    $location = Get-IniValue $config $pair[0] $pair[1]
    if (-not $location) { throw "缺少明确的数据路径：$($pair[0])/$($pair[1])，请人工检查。" }
    $absolute = [IO.Path]::GetFullPath($location)
    if (-not $absolute.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase)) { throw '发现安装目录外的数据路径，不能使用本备份脚本。' }
}
if ((Get-IniValue $config database DB_TYPE) -ne 'sqlite3') { throw '本脚本仅支持SQLite3。' }
$destination = Read-Host '请输入备份根目录，例如 D:\packages（应在另一块物理磁盘）'
if ($destination -notmatch '^[A-Za-z]:\\') { throw '请使用本地磁盘绝对路径。' }
$destination = [IO.Path]::GetFullPath($destination).TrimEnd('\')
if ($destination -eq $root -or $destination.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase)) { throw '备份不能放在服务器目录内部。' }
if (Get-ChildItem -LiteralPath $root -Recurse -Force | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }) { throw '服务器目录含链接或联接，请人工检查备份范围。' }
$target = Join-Path $destination ('Gitea备份-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
if (Test-Path -LiteralPath $target) { throw '备份目标已存在。' }
New-Item -ItemType Directory -Path $target -Force | Out-Null
Invoke-Native icacls.exe @($target,'/inheritance:r','/grant:r','*S-1-5-32-544:(OI)(CI)F','*S-1-5-18:(OI)(CI)F')
Write-Host '备份期间服务短暂停止，请确保团队已暂停操作。'
if ((Read-Host '输入 BACKUP 开始') -cne 'BACKUP') { throw '已取消。' }
$running = $service.State -eq 'Running'
if ($running) { Stop-Service gitea }
try {
    & robocopy.exe $root "$target\服务器文件" /E /COPY:DAT /DCOPY:DAT /R:1 /W:1 /XJ /NFL /NDL /NP
    if ($LASTEXITCODE -ge 8) { throw '复制失败，保留不完整副本，请检查剩余空间和错误。' }
    $files = Get-ChildItem -LiteralPath "$target\服务器文件" -File -Recurse -Force
    $manifest = foreach ($file in $files) {
        $relative = $file.FullName.Substring(("$target\服务器文件\").Length)
        $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
        if ($hash -ne (Get-FileHash -LiteralPath (Join-Path $root $relative) -Algorithm SHA256).Hash) { throw "备份校验失败：$relative" }
        [pscustomobject]@{Path=$relative;SHA256=$hash}
    }
    $manifest | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath "$target\SHA256清单.json" -Encoding UTF8
    '完整副本已校验。包含账号数据库及密钥，仅供管理员保管。恢复前请阅读部署手册；不能发给普通成员。' | Set-Content "$target\说明.txt" -Encoding UTF8
} finally { if ($running) { Start-Service gitea } }
Write-Host "备份完成：$target。这是目录备份，请连同SHA256清单一起保管。"
