"""Gerçekçi cihaz çerçeveleri: iPhone (titanyum kenar, yan tuşlar, Dynamic Island),
iPad (alüminyum kenar, ön kamera) ve MacBook (çentikli ekran, gövde).

Her cihaz önce 2 kat büyüklükte çizilip küçültülür; böylece kenarlar yumuşak olur.
Fonksiyonlar şeffaf zeminli (RGBA) bir cihaz görseli döndürür.
"""
import os

from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), '..')
OSWALD = os.path.join(ROOT, 'assets/fonts/Oswald-Variable.ttf')
SS = 2  # süper örnekleme katsayısı


def _rr_mask(size, radius):
    m = Image.new('L', size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius, fill=255)
    return m


def _hgrad(size, stops):
    """Yatay metal gradyanı. stops: [(konum 0..1, (r,g,b)), ...]"""
    w, h = size
    row = Image.new('RGB', (w, 1))
    px = row.load()
    for x in range(w):
        u = x / max(1, w - 1)
        for (a, ca), (b, cb) in zip(stops, stops[1:]):
            if a <= u <= b:
                t = (u - a) / max(1e-6, b - a)
                px[x, 0] = tuple(int(ca[i] + (cb[i] - ca[i]) * t) for i in range(3))
                break
    return row.resize((w, h))


TITANIUM = [(0, (88, 90, 96)), (.06, (168, 170, 176)), (.5, (205, 206, 210)), (.94, (168, 170, 176)), (1, (88, 90, 96))]
ALUMINIUM = [(0, (120, 122, 128)), (.05, (196, 198, 204)), (.5, (222, 223, 227)), (.95, (196, 198, 204)), (1, (120, 122, 128))]


def with_status_bar(raw, height_ratio=62 / 956):
    """iPhone ekranı: üstte durum çubuğu (9:41, sinyal, pil), altında uygulama."""
    dw, dh = raw.width, int(raw.width * 956 / 440)
    sb = int(dh * height_ratio)
    app = raw.resize((dw, dh - sb), Image.LANCZOS)
    screen = Image.new('RGB', (dw, dh), raw.getpixel((raw.width // 2, 2)))
    screen.paste(app, (0, sb))
    d = ImageDraw.Draw(screen)
    f = ImageFont.truetype(OSWALD, int(sb * .5))
    try:
        f.set_variation_by_axes([600])
    except Exception:
        pass
    white = (245, 245, 245)
    d.text((dw * .12, sb * .26), '9:41', font=f, fill=white)
    bx, unit = dw * .78, sb * .1
    for k in range(4):
        hh = unit * (1.6 + k)
        d.rounded_rectangle((bx + k * unit * 2.1, sb * .66 - hh, bx + k * unit * 2.1 + unit * 1.3, sb * .66), unit * .3, fill=white)
    # Pil
    px0 = bx + unit * 9.6
    bw, y0, y1 = unit * 6.4, sb * .36, sb * .64
    d.rounded_rectangle((px0, y0, px0 + bw, y1), unit * .9, outline=white, width=max(2, int(unit * .35)))
    d.rounded_rectangle((px0 + unit * .8, y0 + unit * .8, px0 + bw - unit * 1.6, y1 - unit * .8), unit * .4, fill=white)
    d.rounded_rectangle((px0 + bw + unit * .3, y0 + (y1 - y0) * .32, px0 + bw + unit * .9, y1 - (y1 - y0) * .32), unit * .2, fill=white)
    return screen


def iphone(screen, width):
    """Dikey iPhone. [screen] durum çubuklu ekran görseli, [width] çıktı genişliği (kenarlar dahil)."""
    W = width * SS
    rim, bez = int(W * .016), int(W * .032)
    sw = W - 2 * (rim + bez)
    sh = int(sw * screen.height / screen.width)
    H = sh + 2 * (rim + bez)
    btn = int(rim * 1.2)
    img = Image.new('RGBA', (W + 2 * btn, H), (0, 0, 0, 0))
    ox = btn
    R = int(W * .165)
    d = ImageDraw.Draw(img)
    # Yan tuşlar (gövdenin arkasında kalacak şekilde önce çizilir)
    side = (150, 152, 158, 255)
    for (y, ln) in ((.17, .032), (.235, .062), (.315, .062)):
        d.rounded_rectangle((0, H * y, btn + rim, H * (y + ln)), btn // 2, fill=side)
    for (y, ln) in ((.25, .1), (.56, .06)):
        d.rounded_rectangle((ox + W - rim, H * y, W + 2 * btn, H * (y + ln)), btn // 2, fill=side)
    # Titanyum kenar
    body = _hgrad((W, H), TITANIUM).convert('RGBA')
    img.paste(body, (ox, 0), _rr_mask((W, H), R))
    # Siyah çerçeve
    d.rounded_rectangle((ox + rim, rim, ox + W - rim, H - rim), R - rim, fill=(8, 8, 10, 255))
    # Ekran
    scr = screen.resize((sw, sh), Image.LANCZOS).convert('RGBA')
    sr = R - rim - bez
    img.paste(scr, (ox + rim + bez, rim + bez), _rr_mask((sw, sh), sr))
    # Dynamic Island
    iw, ih = int(sw * .31), int(sw * .092)
    top = rim + bez + int(sw * .027)
    d.rounded_rectangle((ox + W / 2 - iw / 2, top, ox + W / 2 + iw / 2, top + ih), ih / 2, fill=(0, 0, 0, 255))
    # Camda hafif yansıma
    glare = Image.new('RGBA', (sw, sh), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glare)
    gd.polygon([(0, 0), (sw * .55, 0), (0, sh * .38)], fill=(255, 255, 255, 14))
    img.alpha_composite(glare, (ox + rim + bez, rim + bez))
    return img.resize((img.width // SS, img.height // SS), Image.LANCZOS)


def ipad(screen, width):
    """Yatay iPad. [width] çıktı genişliği."""
    W = width * SS
    short = W * screen.height / screen.width
    rim, bez = int(short * .007), int(short * .034)
    sw = W - 2 * (rim + bez)
    sh = int(sw * screen.height / screen.width)
    H = sh + 2 * (rim + bez)
    R = int(H * .055)
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    img.paste(_hgrad((W, H), ALUMINIUM).convert('RGBA'), (0, 0), _rr_mask((W, H), R))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle((rim, rim, W - rim, H - rim), R - rim, fill=(10, 10, 12, 255))
    scr = screen.resize((sw, sh), Image.LANCZOS).convert('RGBA')
    img.paste(scr, (rim + bez, rim + bez), _rr_mask((sw, sh), int(R * .55)))
    # Ön kamera (yatay tutuşta üst uzun kenarın ortası)
    cr = bez * .16
    d.ellipse((W / 2 - cr, rim + bez / 2 - cr, W / 2 + cr, rim + bez / 2 + cr), fill=(30, 34, 44, 255))
    return img.resize((W // SS, H // SS), Image.LANCZOS)


def macbook(screen, width):
    """MacBook: çentikli ekran ve alüminyum gövde. [width] gövde genişliği."""
    W = width * SS
    lw = int(W * .86)  # kapak genişliği
    side, top = int(lw * .012), int(lw * .022)
    sw = lw - 2 * side
    sh = int(sw * screen.height / screen.width)
    lh = sh + top + side
    base_h = int(W * .022)
    H = lh + base_h + int(W * .006)
    img = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    lx = (W - lw) // 2
    d = ImageDraw.Draw(img)
    # Kapak
    d.rounded_rectangle((lx - 3 * SS, -3 * SS + 3 * SS, lx + lw + 3 * SS, lh + 2 * SS), int(lw * .022), fill=(150, 152, 158, 255))
    d.rounded_rectangle((lx, 3 * SS, lx + lw, lh), int(lw * .02), fill=(8, 8, 10, 255))
    scr = screen.resize((sw, sh), Image.LANCZOS).convert('RGBA')
    m = Image.new('L', (sw, sh), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, sw - 1, sh + 40), int(lw * .012), fill=255)
    img.paste(scr, (lx + side, top), m)
    # Çentik ve kamera
    nw, nh = int(sw * .085), int(top * 1.15)
    d.rounded_rectangle((W / 2 - nw / 2, top - 4 * SS, W / 2 + nw / 2, top + nh * .55), nh * .3, fill=(8, 8, 10, 255))
    d.ellipse((W / 2 - nh * .12, top + nh * .08, W / 2 + nh * .12, top + nh * .32), fill=(28, 32, 42, 255))
    # Gövde
    by = lh
    base = _hgrad((W, base_h), ALUMINIUM).convert('RGBA')
    bm = Image.new('L', (W, base_h), 0)
    ImageDraw.Draw(bm).rounded_rectangle((0, 0, W - 1, base_h * 2), base_h * .5, fill=255)
    img.paste(base, (0, by), bm)
    d.rounded_rectangle((W * .04, by + base_h - 2 * SS, W * .96, by + base_h + int(W * .006)), int(W * .006), fill=(110, 112, 118, 255))
    tw = int(W * .14)
    d.rounded_rectangle((W / 2 - tw / 2, by, W / 2 + tw / 2, by + base_h * .32), base_h * .16, fill=(160, 162, 168, 255))
    return img.resize((W // SS, H // SS), Image.LANCZOS)
