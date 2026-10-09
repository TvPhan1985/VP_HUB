"""Ve bo icon cho VP Hub: mot nut giua noi voi 5 nut xung quanh (hub).

Mau theo app (lib/ui/theme.dart): nen xam dam #0F172A, nut trung tam #38BDF8, nut ve tinh trang.
Sinh ra:
  icon.png            icon vuong day du (may Android cu, khong co adaptive icon)
  icon_bg.png         lop nen cua adaptive icon (mot mau #0F172A)
  icon_fg.png         lop hinh cua adaptive icon, nen trong suot, hinh nam trong vung an toan 66%
  icon_mono.png       lop mot mau (Android 13 themed icon): hinh trang tren nen trong suot
  splash.png          logo cho man khoi dong (Android 11 tro xuong)
  splash_android12.png  logo cho man khoi dong Android 12+ (hinh nam trong vong tron giua)

Chay mot lan khi doi mau / hinh, khong thuoc qua trinh build app:
  tools/.venv/Scripts/python app/assets/icon/generate_icon.py
  cd app; dart run flutter_launcher_icons; dart run flutter_native_splash:create
"""
import math
import os

from PIL import Image, ImageDraw

SIZE = 1024
BG = (15, 23, 42, 255)          # #0F172A
WHITE = (255, 255, 255, 255)
ACCENT = (56, 189, 248, 255)    # #38BDF8
CLEAR = (0, 0, 0, 0)

HERE = os.path.dirname(os.path.abspath(__file__))


def hub(size, extent, bg, node, center, gap):
    """Ve hinh hub tren anh vuong `size`; toan bo hinh nam trong vong tron duong kinh `extent` * size.

    bg: mau nen; node: mau nut ve tinh va day noi; center: mau nut giua;
    gap: mau vien quanh nut giua (None = khoet trong suot).
    """
    # Ve lon gap 4 roi thu nho de canh muot
    k = 4
    s = size * k
    img = Image.new("RGBA", (s, s), bg)
    d = ImageDraw.Draw(img)
    c = s / 2
    half = s * extent / 2
    node_r = half * 0.185
    ring = half - node_r          # ban kinh vong cac nut ngoai
    hub_r = half * 0.32
    line_w = int(half * 0.085)
    pts = [(c + ring * math.cos(math.radians(-90 + i * 72)), c + ring * math.sin(math.radians(-90 + i * 72)))
           for i in range(5)]
    for x, y in pts:
        d.line([(c, c), (x, y)], fill=node, width=line_w)
    for x, y in pts:
        d.ellipse([x - node_r, y - node_r, x + node_r, y + node_r], fill=node)
    rim = hub_r + half * 0.065
    d.ellipse([c - rim, c - rim, c + rim, c + rim], fill=gap if gap is not None else CLEAR)
    d.ellipse([c - hub_r, c - hub_r, c + hub_r, c + hub_r], fill=center)
    return img.resize((size, size), Image.LANCZOS)


def save(img, name):
    out = os.path.join(HERE, name)
    img.save(out)
    print("da ghi", name, img.size)


# Icon vuong day du: hinh chiem 74% canh
save(hub(SIZE, 0.74, BG, WHITE, ACCENT, BG), "icon.png")
# Adaptive icon: lop nen mot mau + lop hinh trong vung an toan 66% (launcher cat hinh tron / bo goc)
# flutter_launcher_icons tu thu lop hinh con 68% (inset 16% moi canh), nen ve 0.86 anh
# de hinh chiem khoang 58% khung icon, vua trong vung an toan 61% (66/108 dp).
FG = 0.86
save(Image.new("RGBA", (SIZE, SIZE), BG), "icon_bg.png")
save(hub(SIZE, FG, CLEAR, WHITE, ACCENT, None), "icon_fg.png")
# Themed icon (Android 13): chi dung kenh alpha, he thong tu to mau
save(hub(SIZE, FG, CLEAR, WHITE, WHITE, None), "icon_mono.png")
# Man khoi dong: logo giua nen #0F172A
save(hub(512, 0.92, CLEAR, WHITE, ACCENT, None), "splash.png")
# Android 12+: he thong cat logo theo hinh tron duong kinh 2/3 canh
save(hub(1152, 0.52, CLEAR, WHITE, ACCENT, None), "splash_android12.png")
