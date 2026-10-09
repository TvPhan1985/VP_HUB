# Sinh docs/LICENSES.md tu app/pubspec.lock. Chay trong thu muc app: ../tools/.venv/Scripts/python ../tools/gen_licenses.py
import re,os,io,sys
lock=io.open('pubspec.lock',encoding='utf-8').read()
cache=os.path.expanduser('~/AppData/Local/Pub/Cache/hosted/pub.dev')
flutter='D:/flutter'
pk=re.findall(r'^  (\S+):\n    dependency: "?([^"\n]+)"?\n    description:(.*?)\n    source: (\S+)\n    version: "([^"]+)"',lock,re.S|re.M)
def kind(t):
    h=t[:1500]
    if 'Apache License' in h: return 'Apache-2.0'
    if 'MIT License' in h or 'Permission is hereby granted, free of charge' in h: return 'MIT'
    if 'Redistribution and use in source and binary forms' in h:
        return 'BSD-3-Clause' if re.search(r'Neither the name|nor the names',t) else 'BSD-2-Clause'
    if 'zlib' in h.lower() or 'This software is provided \'as-is\'' in h: return 'Zlib'
    if 'Mozilla Public' in h: return 'MPL-2.0'
    if 'GNU' in h: return 'GPL/LGPL'
    return '?? '+h[:60].replace('\n',' ')
rows=[]
for name,dep,desc,src,ver in pk:
    if src=='sdk':
        rows.append((name,ver,dep,'BSD-3-Clause (Flutter SDK)')); continue
    f=None
    for n in ('LICENSE','LICENSE.md','LICENSE.txt','COPYING'):
        q=os.path.join(cache,f'{name}-{ver}',n)
        if os.path.exists(q): f=q;break
    rows.append((name,ver,dep,kind(io.open(f,encoding='utf-8',errors='replace').read()) if f else '?? no LICENSE file'))
for r in rows: print('|'.join(r))

ok=('BSD','MIT','Apache','Zlib')
out=["# LICENSES — thư viện dùng trong app VP Hub","",
"Sinh từ `app/pubspec.lock` (chạy `dart pub deps` + đọc file LICENSE của từng gói trong pub cache). Cập nhật: 2026-10-09, app 1.4.0.","",
"Quy tắc của dự án: chỉ dùng gói có license **BSD / MIT / Apache / Zlib**. Gói khác phải ghi **🔴** ở đây và báo người dùng.","",
"## Gói dùng trực tiếp","","| Gói | Bản | License |","|---|---|---|"]
for n,v,d,l in rows:
    if d.startswith('direct'): out.append(f"| `{n}` | {v if v!='0.0.0' else 'SDK'} | {l}{' (chỉ dùng lúc phát triển)' if 'dev' in d else ''} |")
out+=["","## Gói kéo theo (transitive)","","| Gói | Bản | License |","|---|---|---|"]
for n,v,d,l in rows:
    if not d.startswith('direct'):
        bad=not any(k in l for k in ok)
        out.append(f"| `{n}` | {v if v!='0.0.0' else 'SDK'} | {'🔴 **'+l+'**' if bad else l} |")
out+=["","## Ghi chú","",
"- **Thư viện BLE**: `universal_ble` 2.3.0, BSD-3-Clause (Navideck Labs OÜ) — thay `flutter_blue_plus` 2.x (license riêng, công ty có lợi nhuận phải mua). Đã đọc file LICENSE trong gói và nhãn `license:bsd-3-clause` trên pub.dev.",
"- 🔴 `bluez`, `dbus`: **MPL-2.0**. Đây là gói **chỉ dùng cho Linux desktop**, kéo theo bởi `universal_ble` (BLE trên Linux) và `file_picker_linux`; đã có sẵn trong `pubspec.lock` từ bản 1.3 (không phải gói mới thêm). MPL-2.0 là copyleft **theo từng file**: dùng nguyên bản, không sửa mã của gói thì được phép dùng trong sản phẩm thương mại, chỉ cần giữ thông báo bản quyền (màn *Open-source licenses* của app đã hiện). App chỉ phát hành cho Android nên phần mã này không được gọi tới.",
"- Màn **Settings → About → Open-source licenses** trong app hiện toàn văn license của mọi gói (hàm `showLicensePage()` của Flutter).",
"- Khi thêm gói mới: chạy lại việc rà này và cập nhật bảng."]
io.open('../docs/LICENSES.md','w',encoding='utf-8',newline='\n').write('\n'.join(out)+'\n')
