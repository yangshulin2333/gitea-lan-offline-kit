# 维护 / Maintenance

中文文档是默认入口；更新行为时同步维护英文指南和验证状态。不要提交真实配置、用户信息、密码、仓库数据或备份。

Chinese documentation is the default entry point. Update the English guide and validation status when behavior changes. Never commit real configurations, user data, secrets, repositories or backups.

## Build release archives

Place the exact upstream files under the ignored `vendor/` directory:

```text
vendor/gitea.exe
vendor/GITEA-LICENSE
vendor/Git-2.53.0.2-64-bit.exe
vendor/TortoiseGit-2.19.1.0-64bit.msi
vendor/TortoiseGit-LanguagePack-2.19.0.0-64bit-zh_CN.msi
```

Run `python tools/build.py`. Python is only a maintainer build dependency, not an end-user deployment dependency. The build checks pinned binary hashes, creates bilingual offline HTML guides and produces archives and SHA-256 checksums under `dist/`.

Validate PowerShell syntax using Windows PowerShell 5.1 and run the generated package verifier. Installation/restore acceptance requires a disposable Windows machine: do not test installers against production services. Existing scripts reject an existing `gitea` service and existing installation directory.

The backup tool currently supports only the generated local SQLite layout. If storage is customized, review all paths and storage backends before extending backup support.
