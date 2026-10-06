"""Ve icon.png cho VP Hub: mot nut giua noi voi 5 nut xung quanh (hub) tren nen xanh teal.
Chay mot lan khi doi mau / hinh, khong thuoc qua trinh build app:
  tools/.venv/Scripts/python app/assets/icon/generate_icon.py
  cd app; dart run flutter_launcher_icons
"""
import math
import os

from PIL import Image, ImageDraw

SIZE = 1024
BG = (0, 121, 107, 255)       # mau hat giong cua app (0xFF00796B)
WHITE = (255, 255, 255, 255)
ACCENT = (255, 202, 40, 255)  # vang ho phach cho nut giua

img = Image.new("RGBA", (SIZE, SIZE), BG)
d = ImageDraw.Draw(img)
cx = cy = SIZE // 2
R = 300          # ban kinh vong cac nut ngoai
NODE = 74        # ban kinh nut ngoai
HUB = 128        # ban kinh nut giua

pts = []
for i in range(5):
    a = math.radians(-90 + i * 72)
    pts.append((cx + R * math.cos(a), cy + R * math.sin(a)))

for x, y in pts:
    d.line([(cx, cy), (x, y)], fill=WHITE, width=34)
for x, y in pts:
    d.ellipse([x - NODE, y - NODE, x + NODE, y + NODE], fill=WHITE)
d.ellipse([cx - HUB - 26, cy - HUB - 26, cx + HUB + 26, cy + HUB + 26], fill=BG)
d.ellipse([cx - HUB, cy - HUB, cx + HUB, cy + HUB], fill=ACCENT)

out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "icon.png")
img.save(out)
print("da ghi", out, img.size)
