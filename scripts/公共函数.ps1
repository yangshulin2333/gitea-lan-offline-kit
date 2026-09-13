Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function Assert-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw '请以管理员身份打开 Windows PowerShell，再运行脚本。' }
}
function Invoke-Native {
    param([string]$Program, [string[]]$Arguments)
    & $Program @Arguments | Out-Host
    if ($LASTEXITCODE -ne 0) { throw "$Program 执行失败，退出码 $LASTEXITCODE" }
}
function Get-InstallRoot {
    $value = Read-Host '请输入服务器安装目录，例如 D:\Gitea（不是离线包目录）'
    if ($value -notmatch '^[A-Za-z]:\\[A-Za-z0-9_\\-]+$') { throw '请选择本地磁盘上的纯英文目录，例如 D:\Gitea；不要使用盘符根目录、网络盘或空格。' }
    return [IO.Path]::GetFullPath($value).TrimEnd('\')
}
function Get-IniValue {
    param([string]$Path, [string]$Section, [string]$Key)
    $current = ''
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line -match '^\s*\[([^]]+)\]') { $current = $Matches[1] }
        elseif ($current -eq $Section -and $line -match ('^\s*' + [regex]::Escape($Key) + '\s*=\s*(.*?)\s*$')) { return $Matches[1] }
    }
    return ''
}
function Assert-OwnedService {
    param([string]$Root)
    $service = Get-CimInstance Win32_Service -Filter "Name='gitea'"
    $expected = '"' + $Root + '\gitea.exe" web --work-path "' + $Root + '" --config "' + $Root + '\custom\conf\app.ini"'
    if (-not $service -or $service.PathName -ne $expected) { throw '服务路径与输入目录不一致，停止操作，避免影响其他实例。' }
    return $service
}
