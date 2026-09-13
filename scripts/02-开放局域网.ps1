. "$PSScriptRoot\公共函数.ps1"
Assert-Admin
$root = Get-InstallRoot
$service = Assert-OwnedService $root
$config = "$root\custom\conf\app.ini"
if ((Get-IniValue $config security INSTALL_LOCK) -ne 'true') { throw '尚未完成网页安装。请先完成初始化并创建管理员。' }
$ip = Get-IniValue $config server DOMAIN
if (-not (Get-NetIPAddress -AddressFamily IPv4 | Where-Object IPAddress -eq $ip)) { throw '配置的局域网地址不属于本机，先核对网络配置。' }
if (Get-NetFirewallRule -Name 'Gitea-LAN-HTTP-3000' -ErrorAction SilentlyContinue) { throw '防火墙规则已存在，停止避免覆盖。若已部署成功，无需重复执行。' }
$text = [IO.File]::ReadAllText($config)
if ($text -notmatch '(?m)^HTTP_ADDR\s*=\s*127\.0\.0\.1\s*$') { throw '监听配置不符合本工具的初始化状态，停止自动修改。' }
Stop-Service gitea
try {
    $text = [regex]::Replace($text,'(?m)^HTTP_ADDR\s*=\s*127\.0\.0\.1\s*$',"HTTP_ADDR = $ip")
    [IO.File]::WriteAllText($config,$text,[Text.UTF8Encoding]::new($false))
    New-NetFirewallRule -Name 'Gitea-LAN-HTTP-3000' -DisplayName 'Gitea 局域网访问' -Direction Inbound -Action Allow -Protocol TCP -LocalPort 3000 -LocalAddress $ip -RemoteAddress LocalSubnet -Program "$root\gitea.exe" -Profile Any | Out-Null
} finally { Start-Service gitea }
Write-Host "已开放本地子网访问：http://${ip}:3000/。请在服务器及成员电脑分别检查登录。"
