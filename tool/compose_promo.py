"""iPhone, iPad ve MacBook'u bir arada gösteren reklam / sosyal medya görselleri.

Çıktılar app_store/reklam/ klasörüne yazılır:
  - aile_yatay_1920x1080.png     (web sitesi, YouTube, sunum)
  - aile_instagram_1080x1350.png (Instagram gönderisi)
  - aile_hikaye_1080x1920.png    (Instagram / TikTok hikâyesi)
Çalıştırmak için: python3 tool/compose_promo.py
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import devices as dv  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), '..')
RAW = os.path.join(ROOT, 'app_store/ham')
OUT = os.path.join(ROOT, 'app_store/reklam')
OSWALD = os.path.join(ROOT, 'assets/fonts/Oswald-Variable.ttf')
LORA = os.path.join(ROOT, 'assets/fonts/Lora-Italic-Variable.ttf')
ICON = os.path.join(ROOT, 'assets/icon/icon.png')
CORAL = (240, 102, 76)

SLOGAN = 'Zamanı çevir, odağını bul.'
ALT = 'iPhone, iPad ve Mac\'te. Hareketli sahneler, sakin sesler, gerçek bir flip saat.'


def font(path, size, weight):
    f = ImageFont.truetype(path, size)
    try:
        f.set_variation_by_axes([weight])
    except Exception:
        pass
    return f


def raw(name):
    return Image.open(os.path.join(RAW, name)).convert('RGB')


def backdrop(W, H):
    """Gece mavisinden sıcak mercana uzanan yumuşak zemin + yıldızlar."""
    img = Image.new('RGB', (W, H))
    px = img.load()
    top, mid, bot = (14, 17, 40), (30, 26, 62), (70, 34, 44)
    for y in range(H):
        t = y / H
        c = [int(top[i] + (mid[i] - top[i]) * min(1, t * 1.6)) for i in range(3)]
        if t > .6:
            k = (t - .6) / .4
            c = [int(c[i] + (bot[i] - c[i]) * k) for i in range(3)]
        for x in range(W):
            px[x, y] = tuple(c)
    glow = Image.new('L', (W, H), 0)
    ImageDraw.Draw(glow).ellipse((W * .1, H * .55, W * .9, H * 1.3), fill=120)
    glow = glow.filter(ImageFilter.GaussianBlur(min(W, H) * .15))
    img = Image.composite(Image.new('RGB', (W, H), (120, 60, 70)), img, glow)
    d = ImageDraw.Draw(img)
    import random
    r = random.Random(3)
    for _ in range(int(W * H / 9000)):
        x, y = r.random() * W, r.random() * H * .6
        s = r.choice([1, 1, 1.5, 2])
        a = r.randint(90, 220)
        d.ellipse((x - s, y - s, x + s, y + s), fill=(a, a, min(255, a + 15)))
    return img.convert('RGBA')


def place(canvas, dev, x, y, blur=36, alpha=170, dy=26):
    sh = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    m = dev.split()[3].point(lambda v: int(v * alpha / 255))
    blk = Image.new('RGBA', dev.size, (0, 0, 0, 255))
    blk.putalpha(m)
    sh.alpha_composite(blk, (int(x), int(y + dy)))
    canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(blur)))
    canvas.alpha_composite(dev, (int(x), int(y)))


def brand(canvas, x, y, size, center=False):
    """Logo + "Odaklanma Zamanı" yazısı."""
    icon = Image.open(ICON).convert('RGBA').resize((size, size), Image.LANCZOS)
    m = Image.new('L', (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, size - 1, size - 1), size * .225, fill=255)
    icon.putalpha(m)
    d = ImageDraw.Draw(canvas)
    f = font(OSWALD, int(size * .55), 600)
    w1 = d.textlength('Odaklanma ', font=f)
    w2 = d.textlength('Zamanı', font=f)
    total = size + size * .3 + w1 + w2
    if center:
        x = (canvas.width - total) / 2
    canvas.alpha_composite(icon, (int(x), int(y)))
    tx = x + size * 1.3
    ty = y + size * .18
    d.text((tx, ty), 'Odaklanma ', font=f, fill=(246, 244, 240))
    d.text((tx + w1, ty), 'Zamanı', font=f, fill=CORAL)


def headline(canvas, text, sub, y, size, max_w):
    d = ImageDraw.Draw(canvas)
    tf = font(OSWALD, size, 700)
    sf = font(LORA, int(size * .36), 500)
    W = canvas.width
    tw = d.textlength(text, font=tf)
    if tw > max_w:
        tf = font(OSWALD, int(size * max_w / tw), 700)
        tw = d.textlength(text, font=tf)
    d.text(((W - tw) / 2, y), text, font=tf, fill=(250, 248, 244))
    bb = d.textbbox(((W - tw) / 2, y), text, font=tf)
    bar = size * .9
    by = bb[3] + size * .22
    d.rounded_rectangle(((W - bar) / 2, by, (W + bar) / 2, by + max(4, size * .07)), 4, fill=CORAL)
    # alt yazı (gerekirse iki satır)
    words, lines, cur = sub.split(), [], ''
    for w in words:
        t = (cur + ' ' + w).strip()
        if d.textlength(t, font=sf) <= max_w:
            cur = t
        else:
            lines.append(cur)
            cur = w
    lines.append(cur)
    yy = by + size * .38
    for line in lines:
        lw = d.textlength(line, font=sf)
        d.text(((W - lw) / 2, yy), line, font=sf, fill=(226, 222, 234))
        yy += sf.size * 1.4
    return yy


def badge(canvas, text, cx, y, size):
    d = ImageDraw.Draw(canvas)
    f = font(OSWALD, size, 600)
    tw = d.textlength(text, font=f)
    pad = size * .9
    box = (cx - tw / 2 - pad, y, cx + tw / 2 + pad, y + size * 2.1)
    d.rounded_rectangle(box, size * 1.05, fill=CORAL)
    d.text((cx - tw / 2, y + size * .45), text, font=f, fill=(255, 255, 255))


def family(W, H, layout):
    c = backdrop(W, H)
    mac_s, ipad_s, phone_s = raw('m2_ana.png'), raw('i1_tamekran.png'), dv.with_status_bar(raw('p2_tamekran.png'))
    if layout == 'yatay':
        brand(c, 60, 46, 64)
        bottom = headline(c, SLOGAN, ALT, 150, 76, W * .8)
        mac = dv.macbook(mac_s, int(W * .5))
        ipad = dv.ipad(ipad_s, int(W * .34))
        phone = dv.iphone(phone_s, int(W * .13))
        base = H - 60
        place(c, mac, (W - mac.width) / 2, base - mac.height - 10)
        place(c, ipad, W * .07, base - ipad.height)
        place(c, phone, W * .78, base - phone.height + 10)
    elif layout == 'instagram':
        brand(c, 0, 50, 64, center=True)
        headline(c, SLOGAN, ALT, 160, 84, W * .86)
        mac = dv.macbook(mac_s, int(W * .92))
        ipad = dv.ipad(ipad_s, int(W * .52))
        phone = dv.iphone(phone_s, int(W * .25))
        place(c, mac, (W - mac.width) / 2, H * .40)
        place(c, ipad, W * .04, H - ipad.height - 70)
        place(c, phone, W * .70, H - phone.height - 40)
    else:  # hikaye
        brand(c, 0, 120, 72, center=True)
        y = headline(c, SLOGAN, ALT, 250, 92, W * .86)
        mac = dv.macbook(mac_s, int(W * .94))
        ipad = dv.ipad(ipad_s, int(W * .62))
        phone = dv.iphone(phone_s, int(W * .3))
        place(c, mac, (W - mac.width) / 2, y + 80)
        place(c, ipad, W * .03, H - ipad.height - 330)
        place(c, phone, W * .665, H - phone.height - 250)
        badge(c, 'Yakında App Store ve Google Play\'de', W / 2, H - 170, 40)
    return c.convert('RGB')


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, (w, h, layout) in {
        'aile_yatay_1920x1080.png': (1920, 1080, 'yatay'),
        'aile_instagram_1080x1350.png': (1080, 1350, 'instagram'),
        'aile_hikaye_1080x1920.png': (1080, 1920, 'hikaye'),
    }.items():
        family(w, h, layout).save(os.path.join(OUT, name), optimize=True)
        print('yazıldı', name)


if __name__ == '__main__':
    main()
