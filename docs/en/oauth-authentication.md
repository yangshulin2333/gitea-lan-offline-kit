# First-request Gitea OAuth authentication failure

## Scope

This optional workaround targets Windows GCM 2.7.3 with Gitea browser OAuth: a first Git request fails authentication and a retry succeeds. It does not fix incorrect passwords, repository permissions, protected branches or network failures.

The reference environment showed failed OAUTH_USER authentication followed by OAuth refresh requests. GCM 2.7.3 GenericHostProvider returns a cached credential without an expiry check; OAuth refresh is used when no cached access credential exists. This is consistent with the symptom, but the token expiry time was not recorded for each historical failure.

The workaround keeps GCM's refresh credential while suppressing persistent access-token storage for one site. Each subsequent authentication can obtain a fresh token. This adds refresh traffic; it does not disable authentication, extend token lifetimes or change the server.

## Apply

Check `git credential-manager --version`, the remote URL, and the credential helper configuration. Confirm Gitea OAuth with OAUTH_USER, not password/PAT authentication. Never print token values. Pause concurrent Git operations against the site during setup.

From the source checkout, replace the example origin with the actual scheme, hostname and port (no repository path):

```powershell
.\scripts\04-GCM-OAuth.ps1 -Site 'https://git.example.test:3000' -WhatIf
.\scripts\04-GCM-OAuth.ps1 -Site 'https://git.example.test:3000'
```

No elevation is required. The script edits only the current user's site-scoped helpers and refuses unrelated existing helper entries. It removes only the OAUTH_USER access credential, preserving the refresh credential. Missing or expired refresh authorization may require browser login.

Future builds place the script under `工具/`. Existing v0.1.0 release ZIPs do not include it; use a source revision containing this change until a new bundle is published.

## Verify and undo

Inside the target repository, run two rounds of:

```powershell
git ls-remote origin HEAD
git push --dry-run origin HEAD
```

A dry run does not upload commits or validate every server-side write hook. Actual pushes follow normal repository procedures. The reference helper configuration passed two rounds of remote reads and explicit-branch push dry runs without login. Other machines, long idle periods and concurrent clients remain unverified.

```powershell
.\scripts\04-GCM-OAuth.ps1 -Site 'https://git.example.test:3000' -Mode Undo
```

Undo removes only matching workaround settings and restores helper inheritance. It does not restore the old access token or clear other credentials. Changes made by another tool cause a refusal instead of overwrite.

## Implementation

The helper consumes and discards `store` input, delegating `get` and `erase` to GCM. GCM continues storing refresh tokens itself. Use actual Git requests so GCM receives Gitea's authentication challenge; a bare credential-fill request without that challenge is not a valid standalone acceptance test.

Sources: [pinned GCM implementation](https://github.com/git-ecosystem/git-credential-manager/blob/v2.7.3/src/shared/Core/GenericHostProvider.cs), [OAuth documentation](https://github.com/git-ecosystem/git-credential-manager/blob/v2.7.3/docs/generic-oauth.md).
