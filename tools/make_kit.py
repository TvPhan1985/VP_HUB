"""Dong goi bo quy chuan cho du an thiet bi moi thanh mot file zip trong release/.

Chay tu thu muc goc du an:  tools/.venv/Scripts/python tools/make_kit.py
Trong goi: quy chuan, giao thuc, PDF quy chuan giao dien, file mau JSON, component vph_ble,
firmware mau vph_demo (chi ma nguon) va file cai app VP Hub.
"""
import glob
import io
import os
import re
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)

ver = re.search(r'^version:\s*([0-9.]+)', io.open('app/pubspec.yaml', encoding='utf-8').read(), re.M).group(1)
# Tu 1.4: APK chia theo CPU. arm64 la ban chinh, arm32 cho may cu.
apk = 'release/VPHub_%s_arm64.apk' % ver
apk32 = 'release/VPHub_%s_arm32.apk' % ver
if not os.path.exists(apk):
    sys.exit('Thieu %s - build va chep APK vao release/ truoc' % apk)

README = """BO QUY CHUAN VP HUB %s - cho du an thiet bi moi
====================================================

Doc theo thu tu:
  1_QUY_CHUAN_DU_AN_MOI.md   Phai lam gi, theo thu tu nao (doc truoc tien)
  2_PROTOCOL.md              Chi tiet giao thuc VPH (tra cuu khi can)
  3_QUY_CHUAN_GIAO_DIEN.pdf  Quy chuan giao dien ma app dang theo
  4_COPY_STYLE.md            Quy tac viet chu (nhan, nut, cau loi) cho firmware va app
  5_LICENSES.md              License cac thu vien dung trong app

Thu muc:
  mau/                  2 file JSON mau (nong nghiep, cong nghiep). Chep, sua, roi mo trong app:
                        VP Hub -> menu -> Settings -> bat Technician mode -> Developer tools -> Open JSON file
  firmware/vph_ble/     Component dung chung - chep vao components/ cua du an moi
  firmware/vph_demo/    Firmware mau de chep khung code
  VPHub_%s_arm64.apk    App cai len dien thoai:  adb install -r VPHub_%s_arm64.apk
                        (may cu 32 bit: dung file _arm32.apk)

Nho nhat: khai .domain = "agri" (nong nghiep) hoac "ind" (cong nghiep) trong vph_info_t,
app dua vao do de chon bo giao dien. Tham so phan cung / giao tiep / hieu chuan / PID danh
vph_advanced(...) de chi hien o che do Technician cua app.
""" % (ver, ver, ver)

files = [
    ('docs/QUY_TAC_THIET_BI_MOI.md', '1_QUY_CHUAN_DU_AN_MOI.md'),
    ('docs/PROTOCOL.md', '2_PROTOCOL.md'),
    ('docs/COPY_STYLE.md', '4_COPY_STYLE.md'),
    ('docs/LICENSES.md', '5_LICENSES.md'),
    (apk, os.path.basename(apk)),
]
if os.path.exists(apk32):
    files.append((apk32, os.path.basename(apk32)))
if os.path.exists('release/CHANGELOG.md'):
    files.append(('release/CHANGELOG.md', 'CHANGELOG.md'))
pdf = glob.glob('docs/Quy Chuan*.pdf')
if pdf:
    files.append((pdf[0], '3_QUY_CHUAN_GIAO_DIEN.pdf'))
for f in sorted(glob.glob('docs/mau/*.json')):
    files.append((f, 'mau/' + os.path.basename(f)))


def tree(src, dst, skip=()):
    for base, dirs, names in os.walk(src):
        dirs[:] = sorted(d for d in dirs if d not in skip)
        for n in sorted(names):
            if n in skip:
                continue
            p = os.path.join(base, n)
            files.append((p, dst + '/' + os.path.relpath(p, src).replace('\\', '/')))


tree('firmware/components/vph_ble', 'firmware/vph_ble')
tree('firmware/examples/vph_demo', 'firmware/vph_demo',
     skip=('build', 'managed_components', 'sdkconfig', 'sdkconfig.old', 'dependencies.lock'))

out = 'release/VPH_KIT_%s.zip' % ver
top = 'VPH_KIT_%s/' % ver
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    z.writestr(top + 'DOC_TRUOC.txt', README)
    for src, dst in files:
        z.write(src, top + dst)
print('Da tao %s: %d file, %.1f MB' % (out, len(files) + 1, os.path.getsize(out) / 1e6))
for _, dst in files:
    print('  ' + dst)
