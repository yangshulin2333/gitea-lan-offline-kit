$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path (Split-Path $PSScriptRoot) 'scripts/04-GCM-OAuth.ps1'
$tempConfig = [IO.Path]::GetTempFileName()
$oldConfig = $env:GIT_CONFIG_GLOBAL
$gitExe = (Get-Command git.exe).Source
$env:GIT_CONFIG_GLOBAL = $tempConfig
$script:eraseCalls = 0
function git {
    # Never touch real credentials during configuration tests.
    if ($args[0] -eq 'credential-manager') {
        if ($args[1] -eq 'erase') { $script:eraseCalls++; $input | Out-Null }
        $global:LASTEXITCODE = 0
        return
    }
    & $gitExe @args
}
function Assert($condition, $message) { if (-not $condition) { throw $message } }
try {
    & $gitExe config --global credential.helper manager
    & $scriptPath -Site 'https://git.example.test' -WhatIf
    Assert ($script:eraseCalls -eq 0) 'WhatIf erased credentials'
    & $scriptPath -Site 'https://git.example.test'
    & $scriptPath -Site 'https://git.example.test'
    $values = @(& $gitExe config --global --get-all credential.https://git.example.test.helper)
    Assert ($values.Count -eq 2 -and $values[0] -eq '') 'Missing reset or duplicate helpers'
    Assert ($values[1].Contains('"$1"')) 'Native argument quoting lost'
    & $scriptPath -Site 'https://git.example.test' -Mode Undo
    $values = @(& $gitExe config --global --get-all credential.https://git.example.test.helper)
    Assert ($values.Count -eq 0) 'Undo failed'
    Assert ((& $gitExe config --global --get credential.helper) -eq 'manager') 'Inherited helper changed'
    & $gitExe config --global credential.https://git.example.test.helper unrelated
    $refused = $false
    try { & $scriptPath -Site 'https://git.example.test' } catch { $refused = $true }
    Assert $refused 'Unrelated helper was overwritten'
    $refused = $false
    try { & $scriptPath -Site 'https://git.example.test/repo' } catch { $refused = $true }
    Assert $refused 'Repository path accepted as origin'
    Write-Host 'PASS: WhatIf, apply, idempotency, undo, preservation, invalid origin.'
} finally {
    $env:GIT_CONFIG_GLOBAL = $oldConfig
    Remove-Item -LiteralPath $tempConfig
}
