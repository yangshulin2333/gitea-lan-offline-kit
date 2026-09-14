# Gitea OAuth 首次认证失败的处理

## 适用范围与证据

适用于 Windows Git Credential Manager（GCM）2.7.3 使用 Gitea OAuth 浏览器登录，出现首次 Git 请求 `Authentication failed`、再次操作成功的场景。账号密码错误、权限不足、分支保护和网络故障不适用本方案。

参考环境已观察到 `OAUTH_USER` 认证失败及后续 OAuth 刷新请求。GCM 2.7.3 的 GenericHostProvider 会直接返回已缓存的凭据；缓存不存在时才进入 OAuth 刷新流程。该机制与现象一致，但没有保存每次失败时令牌的过期时间，不能将全部历史失败都归于同一原因。

本方案是**可回退的客户端绕行处理**：保留 Windows 凭据库内的刷新令牌，不再持久保存这个站点的访问令牌。下一次 Git 认证由 GCM 获取新访问令牌，代价是增加刷新请求。它不延长令牌有效期，不关闭认证，也不修改服务器。

## 配置前检查

1. 核对完整错误，确认通过 OAuth 浏览器授权，使用的凭据账号为 `OAUTH_USER`。不要输出或分享密码、访问令牌和刷新令牌。
2. 在目标仓库运行 `git remote -v`，确定真实站点地址；脚本只接受协议、主机及端口，不含仓库路径。
3. 运行 `git credential-manager --version` 和 `git config --show-origin --get-all credential.helper`。其他版本先核对实现，不将本方案默认应用到所有客户端。
4. 暂停该账号在此站点的其他 Git 操作，避免首次配置时与凭据刷新并发。

## 使用脚本

源码中的脚本为 `scripts/04-GCM-OAuth.ps1`，后续构建的离线包中为 `工具/04-GCM-OAuth.ps1`。**既有 v0.1.0 ZIP 没有这个新增脚本**；可先克隆包含本修复的源码版本使用，不通过改名或覆盖校验清单冒充新发布包。

在源码根目录用 PowerShell 执行，替换示例站点：

```powershell
.\scripts\04-GCM-OAuth.ps1 -Site 'https://git.example.test:3000' -WhatIf
.\scripts\04-GCM-OAuth.ps1 -Site 'https://git.example.test:3000'
```

使用当前服务器的真实协议和地址，不因示例为 HTTPS 就擅自更改服务器协议。无需管理员权限；只修改当前用户、当前站点的 Git helper 配置。现有不匹配的站点 helper 会触发停止，不覆盖它们。

脚本会删除该站点 `OAUTH_USER` 的旧访问凭据，保留独立刷新凭据。没有有效刷新令牌时，下次操作需要重新进行浏览器授权。普通密码或 PAT 登录不要执行此脚本。

## 验证与回退

在已有目标仓库，分别执行两轮：

```powershell
git ls-remote origin HEAD
git push --dry-run origin HEAD
```

`--dry-run` 验证推送前置流程，不上传提交，也不证明服务端所有写入钩子或保护规则已通过。随后正常推送需遵循仓库工作流程。空远端可能没有 HEAD 输出，应结合退出码判断。

参考环境在配置相同 helper 后，两轮远端读取与明确分支的推送预检查成功，无需重新登录。尚未验证其他电脑、长期空闲后的操作、并发客户端及所有 GCM 版本；脚本自动化验证与真实认证验证分别记录。

回退：

```powershell
.\scripts\04-GCM-OAuth.ps1 -Site 'https://git.example.test:3000' -Mode Undo
```

仅在该站点配置仍与脚本一致时移除本方案，恢复继承原有 helper。它不还原旧访问令牌，也不清空 Windows 凭据库。若配置已被其他工具更改，脚本停止供人工检查。

## 原理与来源

- [GCM 2.7.3 GenericHostProvider 源码](https://github.com/git-ecosystem/git-credential-manager/blob/v2.7.3/src/shared/Core/GenericHostProvider.cs)
- [GCM Generic OAuth 文档](https://github.com/git-ecosystem/git-credential-manager/blob/v2.7.3/docs/generic-oauth.md)

Git 在成功后调用 helper 的 `store`。本方案丢弃访问令牌的 `store` 输入，其余 `get`、`erase` 委托 GCM；刷新令牌仍由 GCM 管理。因此必须通过正常 Git 请求获取 Gitea 的认证挑战，不能用缺少挑战信息的裸 `git credential fill` 作为唯一验收。

## 英语学习

- **Access token**：访问令牌。Request a new access token. 请求新访问令牌。
- **Refresh token**：刷新令牌。Keep the refresh token. 保留刷新令牌。
- **Workaround**：绕行解决方法。Apply the workaround. 应用绕行方案。
- **Credential helper**：凭据助手。Check the credential helper. 检查凭据助手。
- **Rollback**：回退。Prepare a rollback. 准备回退方案。
