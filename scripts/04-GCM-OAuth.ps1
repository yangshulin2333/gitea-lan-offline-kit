[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$Site,
    [ValidateSet('Apply', 'Undo')][string]$Mode = 'Apply'
)

$ErrorActionPreference = 'Stop'
$uri = $null
if (-not [Uri]::TryCreate($Site, [UriKind]::Absolute, [ref]$uri) -or
    $uri.Scheme -notin @('http', 'https') -or $uri.UserInfo -or
    $uri.AbsolutePath -ne '/' -or $uri.Query -or $uri.Fragment) {
    throw 'Use a site origin only, e.g. https://git.example.test:3000 (no credentials or repository path).'
}
$origin = $uri.GetLeftPart([UriPartial]::Authority)
$key = "credential.$origin.helper"
# GCM retains its refresh token in the OS store. Do not cache access tokens.
$helper = '!f() { if test "$1" = store; then cat >/dev/null; else git credential-manager "$@"; fi; }; f'
$values = @(git config --global --get-all $key)
if ($LASTEXITCODE -notin @(0, 1)) { throw 'Cannot read global Git configuration.' }
$ours = $values.Count -eq 2 -and $values[0] -eq '' -and $values[1] -eq $helper
if ($values.Count -gt 0 -and -not $ours) {
    throw 'Existing site-specific helpers differ. Review them manually; nothing was overwritten.'
}
if ($Mode -eq 'Undo') {
    if ($ours -and $PSCmdlet.ShouldProcess($origin, 'Remove this workaround; inherit normal helpers')) {
        git config --global --unset-all $key
        if ($LASTEXITCODE -ne 0) { throw 'Could not remove helper settings.' }
    }
    return
}
git credential-manager --version
if ($LASTEXITCODE -ne 0) { throw 'Git Credential Manager is required.' }
if (-not $PSCmdlet.ShouldProcess($origin, 'Use GCM without persistent access-token caching')) { return }
if (-not $ours) {
    # --replace-all with an empty value resets inherited helpers for this site.
    if ($PSVersionTable.PSVersion.Major -le 5) {
        git config --global --add $key '""'
    } else {
        git config --global --add $key ''
    }
    if ($LASTEXITCODE -ne 0) { throw 'Could not add helper reset.' }
    $nativeHelper = $helper
    if ($PSVersionTable.PSVersion.Major -le 5) { $nativeHelper = $helper.Replace('"', '\"') }
    git config --global --add $key $nativeHelper
    if ($LASTEXITCODE -ne 0) {
        git config --global --unset-all $key
        throw 'Could not add helper; partial configuration removed.'
    }
}
# Remove only the known Gitea OAuth access credential, not the refresh token.
# Do not apply this procedure to password/PAT authentication.
"protocol=$($uri.Scheme)`nhost=$($uri.Authority)`nusername=OAUTH_USER`n`n" | git credential-manager erase
if ($LASTEXITCODE -ne 0) {
    throw 'Helper configured, but old access credential removal failed. Review before retrying.'
}
Write-Host 'Configured. Validate with git ls-remote origin HEAD and git push --dry-run.'
Write-Host 'OAuth browser authorization may be needed if no valid refresh token exists.'
