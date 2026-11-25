"""App Store / Mac App Store tanıtım görsellerini üretir.

Ham ekran görüntüleri app_store/ham/ klasöründen okunur, cihaz çerçevesine yerleştirilir,
başlık ve alt yazı eklenir. Çıktı: app_store/iphone, app_store/ipad, app_store/mac.
Çalıştırmak için: python3 tool/compose_store.py  (Pillow gerekir)
"""
import os
import sys

from PIL import Image, ImageDraw, ImageFilter, ImageFont

sys.path.insert(0, os.path.dirname(__file__))
import devices as dv  # noqa: E402

ROOT = os.path.join(os.path.dirname(__file__), '..')
RAW = os.path.join(ROOT, 'app_store/ham')
OSWALD = os.path.join(ROOT, 'assets/fonts/Oswald-Variable.ttf')
LORA = os.path.join(ROOT, 'assets/fonts/Lora-Italic-Variable.ttf')
CORAL = (240, 102, 76)

SHOTS = {
    'iphone': [
        ('p1_ana.png', 'Zamanı çevir, odağını bul.', 'Masandaki gerçek bir saat gibi dönen kartlar.'),
        ('p2_tamekran.png', 'Arkada canlı bir dünya', 'Kuzey ışıklarından yıldız kaymasına 8 hareketli sahne.'),
        ('p3_somine.png', 'Şöminenin sıcaklığında çalış', 'Yağmur, şömine, dalgalar… 8 sakin ses.'),
        ('p4_tebrik.png', 'Her oturum bir zafer', 'Etüt özetin, gün serin ve ilham veren sözler.'),
        ('p5_istatistik.png', 'İlerlemeni gör', 'Günlük etüt ve mola sayımı, haftalık grafik.'),
        ('p6_ayarlar.png', 'Tamamen senin', 'Süreler, renkler, sahneler ve sesler.'),
    ],
    'ipad': [
        ('i1_tamekran.png', 'Tabletin artık bir odak saati', 'Tam ekran modunda masanın en sakin köşesi.'),
        ('i2_ana.png', 'Büyük ekranda büyük odak', 'Sayaç, sahne ve görevlerin tek bakışta.'),
        ('i3_tebrik.png', 'Her oturumun sonunda ilham', 'Konfeti, alkış ve büyük bir sözle kutla.'),
    ],
    'mac': [
        ('m1_tamekran.png', 'Masaüstünde sessiz bir odak alanı', 'Yıldızların altında, dikkat dağıtan hiçbir şey olmadan.'),
        ('m2_ana.png', 'Sayaç, ses ve görevler bir arada', 'Kısayollarla: Boşluk başlat, F tam ekran.'),
        ('m3_tebrik.png', 'Odaklan. Dinlen. Tekrarla.', 'Her molada teneffüs zili, her oturumda bir tebrik.'),
    ],
}

SIZES = {'iphone': (1320, 2868), 'ipad': (2732, 2048), 'mac': (2880, 1800)}


def font(path, size, weight=None):
    f = ImageFont.truetype(path, size)
    if weight:
        try:
            f.set_variation_by_axes([weight])
        except Exception:
            pass
    return f


def cover(img, w, h):
    r = max(w / img.width, h / img.height)
    img = img.resize((int(img.width * r) + 1, int(img.height * r) + 1), Image.LANCZOS)
    x, y = (img.width - w) // 2, (img.height - h) // 2
    return img.crop((x, y, x + w, y + h))


def rounded_mask(size, radius):
    m = Image.new('L', size, 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, size[0] - 1, size[1] - 1), radius, fill=255)
    return m


def shadow(canvas, box, radius, blur, alpha=170):
    layer = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle(box, radius, fill=(0, 0, 0, alpha))
    canvas.alpha_composite(layer.filter(ImageFilter.GaussianBlur(blur)))


def wrap(draw, text, fnt, max_w):
    words, lines, cur = text.split(), [], ''
    for w in words:
        t = (cur + ' ' + w).strip()
        if draw.textlength(t, font=fnt) <= max_w:
            cur = t
        else:
            lines.append(cur)
            cur = w
    lines.append(cur)
    return lines


def caption(canvas, title, sub, top, max_w, title_px, sub_px):
    d = ImageDraw.Draw(canvas)
    tf = font(OSWALD, title_px, 600)
    sf = font(LORA, sub_px, 500)
    W = canvas.width
    y = top
    bottom = y
    for line in wrap(d, title, tf, max_w):
        tw = d.textlength(line, font=tf)
        d.text(((W - tw) / 2, y), line, font=tf, fill=(246, 244, 240))
        bottom = d.textbbox(((W - tw) / 2, y), line, font=tf)[3]
        y += int(title_px * 1.18)
    # mercan ayraç: yazının gerçek alt sınırının altında
    bar = int(title_px * .9)
    by = bottom + sub_px * .55
    d.rounded_rectangle(((W - bar) / 2, by, (W + bar) / 2, by + 8), 4, fill=CORAL)
    y = int(by + 8 + sub_px * .5)
    for line in wrap(d, sub, sf, max_w):
        tw = d.textlength(line, font=sf)
        d.text(((W - tw) / 2, y), line, font=sf, fill=(226, 222, 232))
        y += int(sub_px * 1.35)
    return y


def background(raw, W, H):
    bg = cover(raw, W, H).filter(ImageFilter.GaussianBlur(max(W, H) * .02)).convert('RGBA')
    shade = Image.new('RGBA', (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(shade)
    for y in range(H):
        a = int(150 - 70 * (y / H))
        d.line((0, y, W, y), fill=(8, 9, 20, a))
    bg.alpha_composite(shade)
    return bg


def device_shadow(canvas, dev, pos, blur=40, alpha=150, dy=30):
    """Cihazın altına yumuşak gölge düşürür ve cihazı yerleştirir."""
    sh = Image.new('RGBA', canvas.size, (0, 0, 0, 0))
    a = dev.split()[3].point(lambda v: int(v * alpha / 255))
    blk = Image.new('RGBA', dev.size, (0, 0, 0, 255))
    blk.putalpha(a)
    sh.alpha_composite(blk, (pos[0], pos[1] + dy))
    canvas.alpha_composite(sh.filter(ImageFilter.GaussianBlur(blur)))
    canvas.alpha_composite(dev, pos)


def iphone(raw, title, sub):
    W, H = SIZES['iphone']
    c = background(raw, W, H)
    caption(c, title, sub, 130, W - 120, 92, 44)
    dev = dv.iphone(dv.with_status_bar(raw), 1040)
    if dev.height > H - 520:
        dev = dev.resize((int(dev.width * (H - 520) / dev.height), H - 520), Image.LANCZOS)
    device_shadow(c, dev, ((W - dev.width) // 2, H - dev.height - 90))
    return c.convert('RGB')


def ipad(raw, title, sub):
    W, H = SIZES['ipad']
    c = background(raw, W, H)
    caption(c, title, sub, 110, W - 600, 96, 46)
    dev = dv.ipad(raw, 2080)
    device_shadow(c, dev, ((W - dev.width) // 2, H - dev.height - 90), blur=50)
    return c.convert('RGB')


def mac(raw, title, sub):
    W, H = SIZES['mac']
    c = background(raw, W, H)
    caption(c, title, sub, 90, W - 700, 88, 42)
    dev = dv.macbook(raw, 2300)
    device_shadow(c, dev, ((W - dev.width) // 2, H - dev.height - 70), blur=50)
    return c.convert('RGB')


def main(only=None):
    makers = {'iphone': iphone, 'ipad': ipad, 'mac': mac}
    for kind, items in SHOTS.items():
        if only and kind not in only:
            continue
        out = os.path.join(ROOT, 'app_store', kind)
        os.makedirs(out, exist_ok=True)
        for i, (name, title, sub) in enumerate(items, 1):
            path = os.path.join(RAW, name)
            if not os.path.exists(path):
                print('eksik:', name)
                continue
            img = makers[kind](Image.open(path).convert('RGB'), title, sub)
            assert img.size == SIZES[kind], img.size
            dst = os.path.join(out, f'{i}_{os.path.splitext(name)[0][3:]}.png')
            img.save(dst, optimize=True)
            print('yazıldı', os.path.relpath(dst, ROOT), img.size)


if __name__ == '__main__':
    main(sys.argv[1:] or None)
