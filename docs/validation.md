# 验证状态 / Validation status

本记录区分人工实际验证与脚本静态检查。/ Operational tests and static script checks are distinct.

|项目 / Item|状态 / Status|
|---|---|
|Windows 11 x64 client installation and Chinese menus|人工验证 / Manually verified|
|Clone, commit, push, pull, private team access|人工验证 / Manually verified|
|Windows restart and LAN access|人工验证 / Manually verified|
|Service process failure and automatic restart|实测通过 / Observed passing|
|1 MiB LFS upload and fresh-clone download, matching hashes|实测通过 / Observed passing|
|Revert, text conflict resolution, branch review and merge|人工验证 / Manually verified|
|Backup file hashes, SQLite integrity and Git integrity|实测通过 / Observed passing|
|Same-machine independent restore: web login, files and permissions|人工验证 / Manually verified|
|Offline reconstruction of one LFS object from backup|字节校验通过 / Byte hash verified|
|New deployment and backup scripts|PowerShell 5.1 syntax checked; not executed end to end|
|Protected branch enforcement|规则保存，拦截测试跳过 / Rule saved; enforcement test skipped|
|Router address reservation|未确认 / Not confirmed|
|Clean offline machine installation / Windows 10|未验证 / Unverified|
|Cross-machine restore / restored HTTP Git and LFS transport|未验证 / Unverified|

## 已知认证问题 / Known authentication issue

Two clients have intermittently received `Authentication failed` on the first Git request. Retrying without changing configuration succeeded. Credential entry observations are consistent with token refresh, but the cause has not been established. Do not treat retry success as a permanent fix or disable authentication.

## 发布前检查 / Packaging checks

Original installers have valid Authenticode signatures on the build machine. Gitea binary matches the pinned SHA-256. Archive members are checked against source hashes. These checks detect packaging errors and do not establish application correctness on every machine.
