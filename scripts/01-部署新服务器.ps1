. "$PSScriptRoot\公共函数.ps1"
Assert-Admin
if (-not [Environment]::Is64BitOperatingSystem -or $env:PROCESSOR_ARCHITECTURE -ne 'AMD64') { throw '本包仅支持 x64 Windows，请使用64位 Windows PowerShell。' }
if (Get-Service gitea -ErrorAction SilentlyContinue) { throw '已有 gitea 服务。本工具仅用于全新部署，不覆盖现有系统。' }
$root = Get-InstallRoot
if (Test-Path -LiteralPath $root) { throw '目录已存在。请选择全新目录；不要删除旧数据来通过检查。' }
$git = Join-Path $env:ProgramFiles 'Git\cmd\git.exe'
if (-not (Test-Path -LiteralPath $git)) { throw '请先安装包内 Git for Windows，使用默认安装目录，然后重开管理员终端。' }
$source = Join-Path (Split-Path $PSScriptRoot) '服务端\gitea.exe'
if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne 'D9ED1FC48EC33A8CB97D7FED3882B4E159EFC3FCAE3A77D0D240E250D5BF6E21') { throw 'Gitea程序校验失败，请重新复制原始离线包。' }
if (Get-NetTCPConnection -State Listen -LocalPort 3000 -ErrorAction SilentlyContinue) { throw '3000端口已被占用，请先查明用途。' }
$ip = Read-Host '请输入本机稳定的局域网IPv4地址（例如192.168.10.10）'
$parsed = $null
if (-not [Net.IPAddress]::TryParse($ip,[ref]$parsed) -or $parsed.AddressFamily -ne 'InterNetwork' -or $ip -eq '127.0.0.1') { throw '需要有效局域网IPv4地址。' }
if (-not (Get-NetIPAddress -AddressFamily IPv4 | Where-Object IPAddress -eq $ip)) { throw '该地址不是本机当前地址。' }
Write-Host "安装到 $root，预定局域网地址 http://${ip}:3000/。初始化阶段仅监听本机。"
foreach ($part in @('custom\conf','data','repositories','log','service-home')) { New-Item -ItemType Directory -Path (Join-Path $root $part) -Force | Out-Null }
# 清除父目录继承，仅管理员、SYSTEM及服务身份可访问服务器数据。
Invoke-Native icacls.exe @($root,'/inheritance:r','/grant:r','*S-1-5-32-544:(OI)(CI)F','*S-1-5-18:(OI)(CI)F','*S-1-5-19:(OI)(CI)M')
Copy-Item -LiteralPath $source -Destination "$root\gitea.exe"
$ini = @"
APP_NAME = 团队代码仓库
RUN_USER = LOCAL SERVICE
RUN_MODE = prod
[server]
HTTP_ADDR = 127.0.0.1
HTTP_PORT = 3000
DOMAIN = $ip
ROOT_URL = http://${ip}:3000/
APP_DATA_PATH = $root\data
DISABLE_SSH = true
LFS_START_SERVER = true
OFFLINE_MODE = true
[database]
DB_TYPE = sqlite3
PATH = $root\data\gitea.db
[repository]
ROOT = $root\repositories
[lfs]
PATH = $root\data\lfs
[git]
PATH = $git
[security]
INSTALL_LOCK = false
[service]
DISABLE_REGISTRATION = true
REQUIRE_SIGNIN_VIEW = true
[mailer]
ENABLED = false
[openid]
ENABLE_OPENID_SIGNIN = false
ENABLE_OPENID_SIGNUP = false
[cron.update_checker]
ENABLED = false
[actions]
ENABLED = false
[log]
MODE = file
LEVEL = info
ROOT_PATH = $root\log
"@
[IO.File]::WriteAllText("$root\custom\conf\app.ini",$ini,[Text.UTF8Encoding]::new($false))
$binary = '"' + $root + '\gitea.exe" web --work-path "' + $root + '" --config "' + $root + '\custom\conf\app.ini"'
New-Service -Name gitea -BinaryPathName $binary -DisplayName 'Gitea 局域网 Git 服务' -StartupType Automatic | Out-Null
Invoke-Native sc.exe @('config','gitea','obj=','NT AUTHORITY\LocalService','start=','delayed-auto')
New-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\gitea' -Name Environment -PropertyType MultiString -Value @("HOME=$root\service-home","USERPROFILE=$root\service-home") -Force | Out-Null
Invoke-Native sc.exe @('failure','gitea','reset=','86400','actions=','restart/60000/restart/60000/restart/120000')
Invoke-Native sc.exe @('failureflag','gitea','1')
Start-Service gitea
Write-Host '服务已启动。打开 http://127.0.0.1:3000/，按中文手册完成安装并创建管理员。'
Write-Host '此时未开放局域网。若浏览器安装后跳转到局域网地址而打不开，继续运行02脚本。'
