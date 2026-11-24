"""Uygulama simgesini üretir: python3 tool/generate_icon.py (Pillow gerekir)."""
import math, os, random
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), '..')
S = 2048  # büyük çizip küçültüyoruz (yumuşak kenarlar için)
FONT = os.path.join(ROOT, 'assets/fonts/Oswald-Variable.ttf')


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


def background(size):
    img = Image.new('RGB', (size, size))
    px = img.load()
    top, bottom = (31, 38, 84), (9, 11, 26)
    for y in range(size):
        c = lerp(top, bottom, y / size)
        for x in range(size):
            px[x, y] = c
    # Alttan gelen sıcak ışıltı
    glow = Image.new('L', (size, size), 0)
    ImageDraw.Draw(glow).ellipse((-size * .2, size * .75, size * 1.2, size * 1.6), fill=110)
    glow = glow.filter(ImageFilter.GaussianBlur(size * .12))
    warm = Image.new('RGB', (size, size), (240, 102, 76))
    img = Image.composite(warm, img, glow)
    # Yıldızlar
    d = ImageDraw.Draw(img)
    rnd = random.Random(4)
    for _ in range(70):
        x, y = rnd.random() * size, rnd.random() * size * .55
        r = rnd.choice([2, 3, 3, 4, 5])
        a = rnd.randint(120, 255)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(a, a, min(255, a + 10)))
    return img


def shooting_star(img, size):
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)
    hx, hy = size * .80, size * .17
    ang = math.radians(152)
    length = size * .36
    steps = 120
    for i in range(steps):
        t = i / steps
        x = hx + math.cos(ang) * length * t
        y = hy + math.sin(ang) * length * t * -1
        r = 10 * (1 - t) + 2
        a = int(255 * (1 - t) ** 1.6)
        d.ellipse((x - r, y - r, x + r, y + r), fill=(255, 244, 220, a))
    glow = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(glow).ellipse((hx - 60, hy - 60, hx + 60, hy + 60), fill=(255, 240, 200, 200))
    glow = glow.filter(ImageFilter.GaussianBlur(30))
    img.alpha_composite(glow)
    img.alpha_composite(layer)


def card(img, size, scale=1.0):
    w, h = size * .60 * scale, size * .54 * scale
    x0, y0 = (size - w) / 2, size * .52 - h / 2
    rad = w * .10
    # Gölge
    sh = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle((x0, y0 + h * .05, x0 + w, y0 + h + h * .05), rad, fill=(0, 0, 0, 150))
    img.alpha_composite(sh.filter(ImageFilter.GaussianBlur(size * .03)))
    # Kart (üst yarı biraz daha açık)
    c = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    cd = ImageDraw.Draw(c)
    cd.rounded_rectangle((x0, y0, x0 + w, y0 + h), rad, fill=(36, 41, 66, 255))
    top = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    ImageDraw.Draw(top).rounded_rectangle((x0, y0, x0 + w, y0 + h), rad, fill=(48, 54, 84, 255))
    mask = Image.new('L', (size, size), 0)
    ImageDraw.Draw(mask).rectangle((0, 0, size, y0 + h / 2), fill=255)
    c = Image.composite(top, c, mask)
    img.alpha_composite(c)
    d = ImageDraw.Draw(img)
    # Ad: menteşe çizgisi adı ikiye böler (üstte ODAKLANMA, altta ZAMANI)
    def fit(text, max_w, max_h):
        size = int(max_h)
        while size > 10:
            f = ImageFont.truetype(FONT, size)
            try:
                f.set_variation_by_name('Bold')
            except Exception:
                pass
            bb = d.textbbox((0, 0), text, font=f)
            if bb[2] - bb[0] <= max_w and bb[3] - bb[1] <= max_h:
                return f, bb
            size -= 4
        return f, bb

    inner_w = w * .84
    half = h / 2
    for text, cy in (('ODAKLANMA', y0 + half * .54), ('ZAMANI', y0 + half + half * .46)):
        f, bb = fit(text, inner_w, half * .50)
        tw, th = bb[2] - bb[0], bb[3] - bb[1]
        d.text((size / 2 - tw / 2 - bb[0], cy - th / 2 - bb[1]), text, font=f, fill=(243, 242, 239))
    # Menteşe çizgisi ve yan çentikler
    seam = max(6, int(h * .022))
    d.rectangle((x0, y0 + h / 2 - seam / 2, x0 + w, y0 + h / 2 + seam / 2), fill=(14, 16, 32))
    n = h * .045
    d.ellipse((x0 - n, y0 + h / 2 - n, x0 + n, y0 + h / 2 + n), fill=(14, 16, 32))
    d.ellipse((x0 + w - n, y0 + h / 2 - n, x0 + w + n, y0 + h / 2 + n), fill=(14, 16, 32))
    # Mercan ilerleme çizgisi
    by = y0 + h + size * .055
    bw = w * .9
    bh = size * .028
    d.rounded_rectangle((size / 2 - bw / 2, by, size / 2 + bw / 2, by + bh), bh / 2, fill=(78, 62, 78))
    d.rounded_rectangle((size / 2 - bw / 2, by, size / 2 - bw / 2 + bw * .62, by + bh), bh / 2, fill=(240, 102, 76))


def make_full():
    img = background(S).convert('RGBA')
    shooting_star(img, S)
    card(img, S)
    return img.convert('RGB').resize((1024, 1024), Image.LANCZOS)


def make_foreground():
    """Android uyarlanabilir simge ön planı: şeffaf zemin, güvenli alanda kart."""
    img = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    card(img, S, scale=.72)
    return img.resize((1024, 1024), Image.LANCZOS)


if __name__ == '__main__':
    out = os.path.join(ROOT, 'assets/icon')
    os.makedirs(out, exist_ok=True)
    make_full().save(os.path.join(out, 'icon.png'))
    make_foreground().save(os.path.join(out, 'icon_foreground.png'))
    bg = background(1024)
    bg.save(os.path.join(out, 'icon_background.png'))
    print('simgeler yazıldı')
