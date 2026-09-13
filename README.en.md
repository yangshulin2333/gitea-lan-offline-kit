# Gitea LAN Offline Kit

[简体中文（默认）](README.md) | **English**

A Windows x64 toolkit for small teams running Git on a local network: Gitea server setup, Git and TortoiseGit installers, and practical deployment and collaboration guides.

> **Prerelease: clean-machine offline deployment has not been validated.** Existing Windows 11 installations have been used for collaboration, service recovery and backup exercises. Validate on a separate machine before production use.

## Get started

Download the full offline bundle or member-client bundle from **Releases**. Large installers are release assets, not files in Git history.

1. Extract the entire archive and read `English-guide.html` or the [English guide](docs/en/guide.md).
2. Install Git. Run `工具/01-部署新服务器.ps1` in elevated Windows PowerShell.
3. Initialize the server locally and create your own administrator account.
4. Run `工具/02-开放局域网.ps1` to enable LAN access, then configure accounts and repository permissions.
5. Complete the acceptance checklist, including reboot, protected branches and restore tests.

Never run the fresh-install script over an existing Gitea installation. The bundle contains no predefined credentials, databases or repositories.

## Documentation

- [English deployment and collaboration guide](docs/en/guide.md)
- [完整中文指南](docs/zh-CN/guide.md)
- [Validation status and limitations](docs/validation.md)
- [Third-party versions, sources and licenses](THIRD_PARTY.md)
- [Maintenance and packaging](CONTRIBUTING.md)

Chinese is the default documentation language. An English guide includes translations of the Chinese script prompts and UI labels. Scripts currently display Chinese prompts; a fully localized English script interface is not yet implemented.

## Requirements and scope

Intel/AMD x64 Windows 10/11, administrator privileges, healthy local NTFS storage and a LAN. Tested operational environment: Windows 11 x64; Windows 10 remains unverified. ARM64, 32-bit and older Windows versions are outside this package's support scope.

SQLite is embedded. Deployment does not require Docker, Node or Python. A maintainer needs Python to build release archives. Fresh-machine deployment, cross-machine restore and protected-branch enforcement still require acceptance tests. Intermittent first-request OAuth authentication failures have been observed; retry succeeded but the root cause is unresolved. This kit uses HTTP on a controlled LAN, not public Internet hosting.

Original scripts and documentation are MIT licensed. Bundled programs retain their own licenses. This is an independent project, not an official distribution of Gitea, Git or TortoiseGit.
