$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$entries = Get-Content -LiteralPath "$root\SHA256清单.json" -Raw -Encoding UTF8 | ConvertFrom-Json
foreach ($entry in $entries) {
    $path = [IO.Path]::GetFullPath((Join-Path $root $entry.Path))
    if (-not $path.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase)) { throw '清单路径超出离线包目录。' }
    if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $entry.SHA256) { throw "文件校验失败：$($entry.Path)" }
}
Write-Host "校验通过：$($entries.Count)个文件。可检查复制损坏，不代替软件签名验证。"
