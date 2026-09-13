# Windows LAN Git deployment and team guide

[简体中文](../zh-CN/guide.md) | English

This guide is designed for offline reading. You still need connectivity between team computers and the LAN server. This is a prerelease toolkit: complete the acceptance checklist on a separate machine before production use.

## 1. Requirements and contents

Use Intel/AMD x64 Windows, administrator privileges and healthy local NTFS storage. Windows 11 x64 has been used in operational tests; clean installation and Windows 10 remain unverified. ARM64, 32-bit Windows, old Windows releases and network-share installation paths are outside this package's scope.

Choose a simple local path without spaces, such as `D:\Gitea` or `C:\Gitea`. Keep at least 10 GB free as a starting point, plus capacity for repositories, LFS objects and backups. Prefer an internal disk. A server disk must remain attached with the same drive letter.

The full release contains Gitea, Git for Windows, TortoiseGit, the simplified Chinese language pack, deployment/backup scripts and bilingual guides. SQLite is included in Gitea. No Docker, Python, Node or separate database server is required by users. Python is used only by maintainers to build packages.

There are no bundled accounts, passwords or existing repositories. Fresh deployment and restoring an existing system are different operations. Never run the fresh-install script over an existing installation.

## 2. Record your deployment choices

- Installation directory.
- Backup directory, preferably on another physical disk.
- Stable LAN IPv4 address and port 3000.
- Administrator username and email.
- Two reviewers who can review one another's requests.

Set passwords yourself and store them separately from shared documentation. Arrange a DHCP reservation with the network administrator if possible. Do not invent a static address without checking the network plan. Examples in the guide are placeholders, not addresses to copy blindly.

Prevent the server from sleeping or hibernating while plugged in. Keep the disk available. If using a VPN, ensure LAN traffic remains direct. The scripts do not change VPN or power settings and do not disable the Windows firewall.

## 3. Install a new server

### 3.1 Extract and install Git

Extract the entire release archive before running anything. Install `Git-2.53.0.2-64-bit.exe` from `成员客户端/安装程序`. Keep Git LFS and Git Credential Manager. For PATH, choose **Git from the command line and also from 3rd-party software**. Use the default `C:\Program Files\Git` directory.

Open a new PowerShell window and run:

```powershell
git --version
git lfs version
```

Both commands should show a version. The server itself does not need TortoiseGit; install it if you also want to use this computer as a GUI client.

### 3.2 Start the deployment script

Open **Windows PowerShell** as administrator. Change to the extracted package's `工具` folder. For example:

```powershell
cd 'D:\packages\gitea-lan-offline-kit\工具'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File '.\01-部署新服务器.ps1'
```

Replace the example path with your actual extraction path. ExecutionPolicy Bypass applies only to this process. If organizational policy forbids scripts, contact your administrator rather than circumventing it.

The script currently uses Chinese prompts:

|Prompt or phrase|Meaning / response|
|---|---|
|请输入服务器安装目录|Enter a new server installation directory, e.g. D:\Gitea|
|请输入本机稳定的局域网IPv4地址|Enter this computer's actual stable LAN IPv4 address|
|已有 gitea 服务|A gitea service already exists; installation is stopped|
|目录已存在|The target exists; choose a fresh directory, do not delete existing data|
|3000端口已被占用|Port 3000 is already in use; investigate the owner|
|服务已启动|The service started; proceed to local web setup|

The script verifies the bundled Gitea hash, creates directories, limits access to Administrators/SYSTEM/LocalService, registers the service, and sets delayed automatic startup. Recovery actions retry after 60, 60 and 120 seconds. These settings cannot recover from a missing disk, corruption or a persistently occupied port.

If a step fails, preserve the error and inspect the partial directory/service state. Do not delete data or repeatedly reinstall blindly. No predefined secrets are inserted.

### 3.3 Initialize locally

Open `http://127.0.0.1:3000/` on the server. Wait for the first startup. Choose English in Gitea's page-language selector if necessary.

Check these installation fields:

- Database: SQLite3.
- Database path: your installation directory plus `\data\gitea.db`.
- Repository root: installation directory plus `\repositories`.
- LFS root: installation directory plus `\data\lfs`.
- Run-as username: `LOCAL SERVICE`.
- Domain: the selected LAN IPv4 address.
- HTTP port: `3000`.
- Base URL: `http://YOUR-LAN-IP:3000/`, including the trailing slash.
- Disable SSH and public registration. Leave mail unconfigured.
- Expand administrator account settings and create your own administrator, email and strong password. Do not leave this section empty.

Finish installation. Initialization is bound only to localhost. If the completed installation redirects to the LAN address and cannot yet load, proceed to the next step.

### 3.4 Enable LAN access

In the same elevated terminal run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File '.\02-开放局域网.ps1'
```

Enter the installation directory. The script checks installation is locked, the service command matches, and the computer owns the configured IP. It binds Gitea to that IP and adds a program-specific TCP 3000 firewall rule for LocalSubnet.

Visit the LAN URL from the server and a member computer. After this step the service listens on the selected LAN IP; use that URL rather than localhost. Do not map this HTTP port directly to the Internet.

### 3.5 Reboot acceptance

Save other work and reboot the server. Do not manually start Gitea. Have a member access the page and clone a practice repository. Ideally test before a Windows user signs in. Delayed startup can require a minute or two. Record actual results rather than assuming the startup setting proves success.

## 4. Accounts, organization and permissions

As administrator open the avatar menu, administration panel, identity/authentication and account management. Create separate member accounts; require an initial password change when appropriate. A Git author's email is not a login password. Avoid sharing the administrator account.

Create a private organization and initialized practice repository. Create a team with access to specified repositories; grant write access to code/issues/pull requests as needed and read access to other units. Add members **and assign the practice repository to the team**. Membership alone does not grant access to an unassigned repository.

Keep at least two designated reviewers if reviewers also submit changes. Ordinary developers do not need site-administrator privileges.

## 5. Install member tools and clone

Install Git, TortoiseGit and, if wanted, the simplified Chinese language pack in that order. English users can leave TortoiseGit in English. The packaged application is 2.19.1.0; the packaged Chinese language pack is 2.19.0.0, the combination used in the test environment. Do not assume it matches arbitrary other versions.

For Chinese: right-click, **Show more options → TortoiseGit → Settings → General → Language → 中文（简体） → Apply**. Restart Explorer or Windows if shell integration has not appeared.

In TortoiseGit settings, Git, set your own name and email. These identify commit authors; they do not authenticate you. In a new terminal run `git lfs install` for your user.

Open the repository's web page, choose Code and copy the HTTP clone URL. Right-click a local parent directory, choose TortoiseGit Clone, and select a new project subdirectory. Leave shallow/bare/no-checkout options disabled. HTTP does not need a PuTTY key. Authenticate with your Gitea account, not a GitHub account. `Authentication successful` means the browser authorization succeeded.

Different computers may use different local project directories. Never work directly inside the server's bare-repository directory, and do not edit `.git` manually.

## 6. Daily branch and review workflow

1. Commit or safely preserve current work. Switch/Checkout `main` and pull `origin/main`.
2. Create a new task branch, such as `member02-map`, and switch to it.
3. Edit files. Review the diff, select only intended files, and write a meaningful commit message.
4. Push local `member02-map` to remote `member02-map` on `origin`, not to main. Do not force-push.
5. On the website create a pull request: destination/base is main; source/head is the task branch. Comparing main with main shows no differences.
6. Review the diff and write a title/description, then create the request.
7. Another reviewer checks changed files and submits Approve. Marking a file viewed is not approval; a comment alone is not approval. Request changes means revisions are needed.
8. An authorized maintainer selects Create merge commit, checks the confirmation and confirms. Only the Merged status means the changes reached main.
9. Both clients switch back to main and pull. Web merges do not automatically update local files.

Create a fresh branch for each new task. Do not force-switch away from unsaved changes. Commit records changes locally; push uploads them. Delete an old branch only after verifying it is merged and has no additional work.

### Protect main

Repository Settings → Branches → Add new rule: pattern main, file patterns empty. Disable direct push and force push. Do not require signatures until signing is configured. Require one approval from designated reviewers; dismiss stale approvals when content changes. Restrict merging to maintainers. Do not allow bypass. Block rejected and pending official reviews, and enforce rules for administrators. Leave status checks off until CI exists.

Select actual user search results in allowlists, not just typed text. Verify direct pushes and unapproved merges are rejected, then verify approved merges work. This enforcement test was skipped in the original exercise, so it remains an acceptance requirement.

## 7. Undo changes

### Uncommitted changes

Select the file and use TortoiseGit Revert. Check the selected files first. Git generally cannot recover discarded changes that were never committed; copy valuable work outside the repository first.

### A committed and pushed change

After branch protection is enabled, create an undo task branch from current main. Open Show log, select the specific ordinary commit, then **Revert changes by this commit** (Chinese: 还原此版本做出的变更). Inspect the result, commit the reversal, push the task branch and open a pull request. The original history remains.

Do not confuse this with Reset branch to this revision. Reverting merge commits or interdependent sequences needs additional care; the tested exercise covers one ordinary commit only.

## 8. Resolve a text conflict

Changes in different locations may merge automatically; changes to the same line may conflict. Authentication failure is unrelated. Actual conflict output contains CONFLICT and Merge conflict.

Agree on the correct final content with your colleague. Right-click the actual file; on Windows 11 you may need Show more options. TortoiseGit offers Edit conflicts and Resolve (Chinese: 编辑冲突 / 解决冲突).

In TortoiseGitMerge the upper panels show both sides; the lower merged panel is the final output. Edit that panel, remove conflict markers, save, and choose Mark as resolved. If you edited with a text editor instead, open Resolve, select the file and confirm. Then commit the merge result and push. Marking a conflict resolved does not establish that the content is correct.

For the exercise, a valid agreed result is:

```text
Project: Team practice
This week's task: Build the lobby map
This week's task: Build the battle map
```

With protection enabled, merge main into your development branch and resolve there, then use a pull request. Keeping both sides is an example, not a universal solution: code may need one side selected or a rewrite and tests.

Images, models and other binary assets generally cannot be merged line by line. Agree on ownership before editing concurrently. Git LFS stores large files but does not automatically resolve conflicting assets. Real game projects need file-specific LFS and ignore rules.

## 9. Backup and restore

A complete backup includes the database, repositories, LFS, attachments, configuration and secrets. A repository clone alone is not a server backup. Store backups on a separate physical disk and keep them private.

For an installation generated by this kit, run `03-完整备份.ps1`. Prompts request the installation root and backup root (`请输入备份根目录`). Notify the team to pause work, then type BACKUP. The script temporarily stops the service, copies the local installation tree, compares file hashes and restarts the service if it was running. It creates a directory backup rather than a ZIP to avoid compression-size limitations.

The tool only supports the generated local SQLite layout. If storage has been moved outside the installation root or uses external services, review and extend the backup plan first. A copied and hashed backup is not yet a proven restore.

Restore into an independent copy and preserve both the original backup and failed installation. The least complex migration keeps the same installation path and Git version on the new machine: copy the backup's server tree, restore LocalService permissions, HOME/service settings, and do not initialize a new database. Accounts keep their backup-time passwords.

Changing drive letters or IP requires auditing all paths in app.ini and updating ROOT_URL/DOMAIN/HTTP_ADDR, then regenerating repository hooks. Old hooks can point at the original executable. Fresh-install scripts do not migrate existing data. Cross-machine recovery is unverified and is not advertised as one-click restore. Verify login, permissions, history, Git transfers and LFS on an isolated replacement machine before changing member URLs.

For a forgotten administrator password, the server administrator should use the matching Gitea management command. Run `gitea.exe admin user change-password --help` offline to inspect exact arguments, and avoid placing passwords in shared logs or chats. Do not delete the database or disable authentication.

## 10. Troubleshooting

|Symptom|First checks|
|---|---|
|Page unavailable|Server power, current IP, service status, delayed startup, TCP3000 and VPN LAN routing|
|Service fails to start|services.msc, installation log directory, disk availability, Git path, ACLs and occupied port|
|Authentication failed|Retry once unchanged; repeated failures need account/permission/credential investigation|
|Protected-branch rejection|Keep the local commit, create a task branch and push it, then open a pull request|
|Non-fast-forward|Remote has newer commits; integrate on the appropriate development branch and resolve conflicts|
|Missing shell menu|Select the actual file, use Show more options and check you are inside a repository|
|LFS failure|Check client LFS installation, server enablement, stored objects, connectivity and permissions|
|Merge blocked|Check approval count, reviewer allowlist, requested changes, pending reviews and conflicts|

First-request authentication failure followed by successful retry has been observed on two clients. Token refresh is a possibility, not a confirmed root cause. Do not wipe all Windows credentials; investigate only the matching Gitea site. Signature notices refer to commit signing, not login credentials.

## 11. Acceptance checklist

- With Internet disconnected but LAN intact, installers and local guides work.
- New administrator and independent member accounts work; private repository access is correct.
- Real reboot permits access without manually starting the service, preferably before Windows sign-in.
- Branch commits, push, review, merge and both clients' pulls work.
- Direct protected-branch pushes and unapproved merges are blocked.
- Ordinary commit revert and text conflict resolution work.
- LFS upload and fresh clone on another computer produce identical file hashes.
- A backup restored on another computer passes login, history, permission, Git-transfer and LFS tests.
- Observe first operations after token expiry and record authentication failures.

Keep unverified items visible. Existing tests cannot guarantee compatibility with every machine.
