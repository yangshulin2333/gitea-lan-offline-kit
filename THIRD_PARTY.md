# 第三方软件 / Third-party software

Original upstream programs are redistributed without modification. Their licenses are separate from this repository's MIT license. Installer-embedded notices remain intact.

|Software|Pinned version|Upstream source / release|License|
|---|---|---|---|
|Gitea|1.27.3 Windows amd64|https://github.com/go-gitea/gitea/releases/tag/v1.27.3|MIT; included in full bundle|
|Git for Windows|2.53.0.windows.2 (installer 2.53.0.2)|https://github.com/git-for-windows/git/releases/tag/v2.53.0.windows.2|GPL-2.0 and component licenses; see installer|
|TortoiseGit|2.19.1.0 x64|https://tortoisegit.org/download/|GPL-2.0; see installer|
|TortoiseGit simplified Chinese language pack|2.19.0.0 x64|https://download.tortoisegit.org/tgit/2.19.0.0/|Upstream TortoiseGit licensing|

Corresponding upstream source: https://github.com/git-for-windows/git/tree/v2.53.0.windows.2 and https://gitlab.com/tortoisegit/tortoisegit . Git for Windows build tooling: https://github.com/git-for-windows/build-extra . Consult the exact upstream release for component notices and source distribution information.

Gitea Windows service reference: https://docs.gitea.com/installation/windows-service/ . Configuration reference: https://docs.gitea.com/administration/config-cheat-sheet/ . Guides in this bundle are self-contained and can be read offline.

The bundled TortoiseGit application and Chinese language-pack versions differ because this was the upstream-provided combination used in the test environment. Do not apply the language pack to arbitrary other client versions.
