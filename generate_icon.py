import sys
sys.path.insert(0, r'C:\users\pc\appdata\roaming\python\python312\site-packages')
from PIL import Image, ImageDraw
import os

def draw_truck_icon(size=1024):
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    s = size

    # Background circle - deep navy blue
    d.ellipse([0, 0, s-1, s-1], fill=(26, 35, 126, 255))

    def px(v): return int(v * s / 100)

    # --- Cargo box / trailer ---
    d.rectangle([px(8), px(32), px(67), px(62)], fill=(255, 193, 7, 255))
    d.rectangle([px(8), px(32), px(67), px(62)], outline=(255, 160, 0, 255), width=px(1))
    for i in [20, 32, 44, 56]:
        d.rectangle([px(i), px(33), px(i)+px(1), px(61)], fill=(255, 160, 0, 200))

    # --- Cab body ---
    d.rectangle([px(67), px(40), px(90), px(62)], fill=(255, 193, 7, 255))
    # Cab roof
    d.polygon([
        (px(67), px(40)),
        (px(71), px(30)),
        (px(88), px(30)),
        (px(90), px(40)),
    ], fill=(255, 193, 7, 255))
    # Windshield
    d.polygon([
        (px(69), px(39)),
        (px(72), px(32)),
        (px(87), px(32)),
        (px(89), px(39)),
    ], fill=(144, 202, 249, 210))
    # Door separator
    d.line([(px(78), px(41)), (px(78), px(61))], fill=(255, 152, 0, 255), width=px(1))

    # --- Chassis frame ---
    d.rectangle([px(8), px(62), px(90), px(66)], fill=(200, 200, 200, 255))

    # --- Wheels ---
    for cx in [px(22), px(40), px(76)]:
        cy = px(66)
        wr = px(9)
        d.ellipse([cx-wr, cy-wr, cx+wr, cy+wr], fill=(30, 30, 30, 255))
        d.ellipse([cx-int(wr*0.6), cy-int(wr*0.6), cx+int(wr*0.6), cy+int(wr*0.6)], fill=(160, 160, 160, 255))
        d.ellipse([cx-int(wr*0.22), cy-int(wr*0.22), cx+int(wr*0.22), cy+int(wr*0.22)], fill=(220, 220, 220, 255))

    # --- Headlight ---
    d.ellipse([px(88), px(52), px(93), px(58)], fill=(255, 245, 157, 255))

    # --- Exhaust stack ---
    d.rectangle([px(85), px(25), px(88), px(31)], fill=(160, 160, 160, 255))

    return img

os.makedirs('flutter_app/assets/icons', exist_ok=True)

icon = draw_truck_icon(1024)
icon.save('flutter_app/assets/icons/truck_icon.png')

fg = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
truck_small = draw_truck_icon(800)
fg.paste(truck_small, (112, 112), truck_small)
fg.save('flutter_app/assets/icons/truck_icon_fg.png')

print('Icons generated OK')
