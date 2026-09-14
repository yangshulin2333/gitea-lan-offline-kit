"""Build offline release assets using only the Python standard library."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def digest(path):
    value = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            value.update(block)
    return value.hexdigest().upper()


def render(text, language):
    parts, code, table = [], False, False
    for line in text.splitlines():
        if table and not line.startswith('|'):
            parts.append('</table>')
            table = False
        if not code and line.startswith('|'):
            if not table:
                parts.append('<table>')
                table = True
            if not re.match(r'^\|[-| :]+\|$', line):
                cells = ''.join('<td>' + html.escape(x.strip()) + '</td>' for x in line.strip('|').split('|'))
                parts.append('<tr>' + cells + '</tr>')
            continue
        if line.startswith('```'):
            parts.append('</code></pre>' if code else '<pre><code>')
            code = not code
        elif code:
            parts.append(html.escape(line) + '\n')
        elif re.match(r'^#{1,6} ', line):
            level = len(line.split(' ')[0])
            parts.append(f'<h{level}>' + html.escape(line[level + 1:]) + f'</h{level}>')
        elif line:
            parts.append('<p>' + html.escape(line) + '</p>')
    if table:
        parts.append('</table>')
    return f'''<!doctype html><html lang="{language}"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>Gitea LAN Kit Guide</title>
<style>body{{max-width:960px;margin:40px auto;padding:0 24px;font:17px/1.8 "Microsoft YaHei",sans-serif;color:#243443}}
h2{{border-bottom:2px solid #bfd5e5;padding-top:25px}}pre{{background:#edf2f6;padding:16px;white-space:pre-wrap}}
table{{border-collapse:collapse;width:100%}}td{{border:1px solid #bfd5e5;padding:8px}}p{{overflow-wrap:anywhere}}
@media print{{body{{font-size:11pt;margin:0}}h2,h3{{break-after:avoid}}}}</style><body>''' + '\n'.join(parts) + '</body></html>'


def archive(folder, target):
    entries = [{'Path': str(p.relative_to(folder)), 'SHA256': digest(p)}
               for p in sorted(folder.rglob('*')) if p.is_file() and p.name != 'SHA256清单.json']
    (folder / 'SHA256清单.json').write_text(json.dumps(entries, ensure_ascii=False, indent=2), encoding='utf-8-sig')
    with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED) as output:
        for path in sorted(folder.rglob('*')):
            if path.is_file():
                output.write(path, str(path.relative_to(folder.parent)))
    with zipfile.ZipFile(target) as output:
        assert output.testzip() is None
        for path in folder.rglob('*'):
            if path.is_file():
                name = path.relative_to(folder.parent).as_posix()
                assert hashlib.sha256(output.read(name)).hexdigest().upper() == digest(path)


def main():
    expected = json.loads((ROOT / 'tools/vendor-hashes.json').read_text(encoding='utf-8-sig'))
    for entry in expected:
        path = ROOT / 'vendor' / entry['Name']
        if not path.is_file() or digest(path) != entry['SHA256']:
            raise RuntimeError('Missing or mismatched upstream file: ' + entry['Name'])
    dist = ROOT / 'dist'
    dist.mkdir(exist_ok=True)
    # Use a fresh staging directory, never merge with old or user-provided files.
    import tempfile
    with tempfile.TemporaryDirectory(prefix='gitea-kit-', dir=dist) as temporary:
        full = Path(temporary) / 'gitea-lan-offline-kit'
        client = Path(temporary) / 'gitea-member-client'
        (full / '服务端').mkdir(parents=True)
        (full / '成员客户端/安装程序').mkdir(parents=True)
        (client / '安装程序').mkdir(parents=True)
        shutil.copytree(ROOT / 'scripts', full / '工具')
        (client / '工具').mkdir()
        shutil.copy2(ROOT / 'scripts/00-校验离线包.ps1', client / '工具')
        shutil.copy2(ROOT / 'scripts/04-GCM-OAuth.ps1', client / '工具')
        shutil.copy2(ROOT / 'vendor/gitea.exe', full / '服务端')
        shutil.copy2(ROOT / 'vendor/GITEA-LICENSE', full / '服务端/LICENSE')
        for path in (ROOT / 'vendor').iterdir():
            if path.suffix == '.msi' or path.name.startswith('Git-'):
                shutil.copy2(path, full / '成员客户端/安装程序')
                shutil.copy2(path, client / '安装程序')
        zh = (ROOT / 'docs/zh-CN/guide.md').read_text(encoding='utf-8')
        en = (ROOT / 'docs/en/guide.md').read_text(encoding='utf-8')
        for folder in (full, client):
            (folder / 'OAuth-authentication.html').write_text(
                render((ROOT / 'docs/zh-CN/oauth-authentication.md').read_text(encoding='utf-8'), 'zh-CN'), encoding='utf-8')
            (folder / 'OAuth-authentication-English.html').write_text(
                render((ROOT / 'docs/en/oauth-authentication.md').read_text(encoding='utf-8'), 'en'), encoding='utf-8')
            (folder / '完整中文操作手册.html').write_text(render(zh, 'zh-CN'), encoding='utf-8')
            (folder / 'English-guide.html').write_text(render(en, 'en'), encoding='utf-8')
            for name in ('THIRD_PARTY.md', 'LICENSE'):
                shutil.copy2(ROOT / name, folder / name)
            shutil.copy2(ROOT / 'docs/validation.md', folder / '验证状态-Validation.md')
        (full / '先读我-START-HERE.txt').write_text(
            '默认中文：打开 完整中文操作手册.html。English: open English-guide.html.\n'
            '预发布；全新电脑安装尚未验收。Prerelease; clean-machine installation is unverified.\n'
            '先安装Git，再运行工具中的01部署脚本。Install Git, then follow the deployment guide.\n'
            '不用于覆盖现有服务器。Do not overwrite an existing installation.\n', encoding='utf-8-sig')
        (client / '先读我-START-HERE.txt').write_text(
            '成员客户端包：按Git、TortoiseGit、中文语言包顺序安装。阅读手册第5至8节。\n'
            'Client-only bundle. Install Git and TortoiseGit; Chinese pack is optional. Read sections 5–8 of English-guide.html.\n'
            '本包不含服务端。No server included.\n', encoding='utf-8-sig')
        assets = [('gitea-lan-offline-kit-windows-x64.zip', full), ('gitea-member-client-windows-x64.zip', client)]
        for name, folder in assets:
            archive(folder, dist / name)
        (dist / 'SHA256SUMS.txt').write_text(''.join(digest(dist / name) + '  ' + name + '\n' for name, _ in assets), encoding='ascii')
        for name, _ in assets:
            print(f'Verified {name}: {(dist / name).stat().st_size / 1024 / 1024:.1f} MiB')


if __name__ == '__main__':
    main()
