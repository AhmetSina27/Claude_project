"""Uygulamadaki ortam seslerini ve zil seslerini üretir.

Sesler ders çalışırken arka planda kalacak şekilde sakin tasarlandı: tiz frekanslar kısıldı,
ani sesler (kuş, çıtırtı, damla) seyrek ve yumuşak tutuldu, genel seviye düşük.
Tüm döngüler frekans alanında şekillendirilmiş gürültüden ve döngü uzunluğuna göre sarmalanan
olaylardan oluşur; bu yüzden başa sardıklarında kesinti olmaz.
Çalıştırmak için: python3 tool/generate_sounds.py  (numpy ve ffmpeg gerekir)
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sounds")
L = 30 * SR  # 30 saniyelik döngüler
rng = np.random.default_rng(11)


def spectrum_shape(n, shape):
    f = np.fft.rfftfreq(n, 1 / SR)
    f[0] = 1e-3
    return shape(f)


def shaped_noise(n, shape):
    """shape(freqs) -> genlik. FFT ile şekillendirilmiş, periyodik gürültü."""
    spec = np.fft.rfft(rng.standard_normal(n)) * spectrum_shape(n, shape)
    out = np.fft.irfft(spec, n)
    return out / (np.abs(out).max() + 1e-9)


def filt(x, shape):
    """Periyodik (döngüyü bozmayan) frekans alanı süzgeci."""
    return np.fft.irfft(np.fft.rfft(x) * spectrum_shape(len(x), shape), len(x))


def bp(lo, hi, slope=2):
    return lambda f: 1 / (1 + (lo / f) ** (2 * slope)) ** .5 / (1 + (f / hi) ** (2 * slope)) ** .5


def lp(fc, slope=2):
    return lambda f: 1 / (1 + (f / fc) ** (2 * slope)) ** .5


def slow_env(n, cycles_max, lo=0.0, hi=1.0):
    """Periyodik, yavaş değişen zarf (lo..hi)."""
    x = shaped_noise(n, lp(cycles_max / (n / SR), 3))
    x = (x - x.min()) / (x.max() - x.min() + 1e-9)
    return lo + (hi - lo) * x


def add_event(buf, ev, pos):
    idx = (pos + np.arange(len(ev))) % len(buf)
    np.add.at(buf, idx, ev)


def env(n, attack, decay):
    t = np.arange(n) / SR
    return np.clip(t / max(attack, 1e-4), 0, 1) * np.exp(-t / decay)


def write(name, x, peak=0.5, soften=6000):
    """Tiz frekansları yumuşatır, seviyeyi ayarlar ve mp3 olarak yazar."""
    if soften:
        x = filt(x, lp(soften, 1.5))
    x = x / (np.abs(x).max() + 1e-9) * peak
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        with wave.open(tmp.name, "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SR)
            w.writeframes(pcm.tobytes())
        dst = os.path.join(OUT, name + ".mp3")
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp.name,
                        "-c:a", "libmp3lame", "-b:a", "128k", dst], check=True)
    os.unlink(tmp.name)
    print("yazıldı", os.path.relpath(dst))


def main():
    os.makedirs(OUT, exist_ok=True)
    for old in ("ucak", "tren"):
        p = os.path.join(OUT, old + ".mp3")
        if os.path.exists(p):
            os.remove(p)

    # --- Yağmur: düzenli, yumuşak yağmur; seyrek ve alçak damlalar ---
    rain = shaped_noise(L, lambda f: bp(250, 4500)(f) * f ** -0.5)
    rain *= slow_env(L, 4, .85, 1.0)
    for _ in range(700):
        d = int(SR * rng.uniform(0.008, 0.02))
        t = np.arange(d) / SR
        ev = np.sin(2 * np.pi * rng.uniform(900, 2500) * t) * env(d, 0.002, d / SR / 4) * rng.uniform(0.02, 0.08)
        add_event(rain, ev, rng.integers(L))
    write("yagmur", rain, peak=.45, soften=5000)

    # --- Şömine: sıcak uğultu, seyrek ve yumuşak çıtırtılar ---
    fire = shaped_noise(L, lp(220, 1)) * slow_env(L, 10, .75, 1.0)
    for _ in range(420):
        d = int(SR * rng.uniform(0.003, 0.012))
        ev = filt(rng.standard_normal(d), lp(2500)) * env(d, 0.0008, d / SR / 4) * rng.uniform(0.05, 0.35) ** 2
        add_event(fire, ev, rng.integers(L))
    write("ates", fire, peak=.45, soften=3500)

    # --- Orman: hafif rüzgâr ve çok seyrek, uzaktan kuş sesleri ---
    forest = shaped_noise(L, bp(120, 900)) * slow_env(L, 3, .35, 1.0)
    for _ in range(9):
        base = rng.uniform(1800, 3000)
        start = rng.integers(L)
        for c in range(rng.integers(2, 4)):
            d = int(SR * rng.uniform(0.12, 0.22))
            t = np.arange(d) / SR
            sweep = base * (1 + rng.uniform(-0.15, 0.2) * t / t[-1])
            ev = np.sin(2 * np.pi * np.cumsum(sweep) / SR) * np.sin(np.pi * t / t[-1]) ** 2
            add_event(forest, ev * rng.uniform(0.04, 0.08), start + int(c * SR * rng.uniform(0.25, 0.4)))
    write("orman", forest, peak=.42, soften=4000)

    # --- Doğa (dere): yumuşak su akışı ---
    stream = shaped_noise(L, bp(250, 2200)) * (0.75 + 0.25 * np.abs(shaped_noise(L, bp(0.5, 3))))
    for _ in range(1500):
        d = int(SR * rng.uniform(0.02, 0.05))
        t = np.arange(d) / SR
        f0 = rng.uniform(300, 900)
        ev = np.sin(2 * np.pi * f0 * (1 + 1.5 * t / t[-1]) * t) * np.sin(np.pi * t / t[-1]) * rng.uniform(0.01, 0.04)
        add_event(stream, ev, rng.integers(L))
    write("doga", stream, peak=.42, soften=3500)

    # --- Okyanus dalgaları: 7,5 ve 10 saniyelik yavaş dalgalar ---
    t = np.arange(L) / L
    swell = 0.0
    for cycles, w, ph in ((4, .6, 0.0), (3, .4, 1.3)):
        s = 0.5 - 0.5 * np.cos(2 * np.pi * cycles * t + ph)
        swell = swell + w * s ** 1.8
    waves = shaped_noise(L, bp(80, 2500, 1)) * (0.15 + 0.85 * swell)
    waves += shaped_noise(L, lp(150)) * 0.25
    write("dalga", waves, peak=.45, soften=3000)

    # --- Kahverengi gürültü: derin, düz ve çok sakin ---
    brown = shaped_noise(L, lambda f: 1 / np.maximum(f, 20) * lp(900, 1)(f))
    write("kahverengi", brown, peak=.45, soften=0)

    # --- Karlı kulübe: dışarıda alçak rüzgâr, içeride çok hafif şömine ---
    cabin = shaped_noise(L, bp(100, 600)) * slow_env(L, 3, .3, 1.0) * 0.8
    cabin += shaped_noise(L, lp(180, 1)) * 0.3
    for _ in range(250):
        d = int(SR * rng.uniform(0.003, 0.01))
        ev = filt(rng.standard_normal(d), lp(2000)) * env(d, 0.0008, d / SR / 4) * rng.uniform(0.03, 0.18) ** 2
        add_event(cabin, ev, rng.integers(L))
    write("kulube", cabin, peak=.42, soften=3000)

    # --- Tik tak: yumuşak, tok saat tıkırtısı ---
    tick = shaped_noise(L, lp(400)) * 0.01
    for s in range(30):
        d = int(SR * 0.025)
        tt = np.arange(d) / SR
        f0 = 1300 if s % 2 == 0 else 1050
        ev = (np.sin(2 * np.pi * f0 * tt) + 0.2 * rng.standard_normal(d)) * env(d, 0.0008, 0.0035)
        add_event(tick, ev, s * SR)
    write("tiktak", tick, peak=.35, soften=4000)

    # --- Teneffüs zili (okul zili) ---
    D = int(SR * 3.2)
    t = np.arange(D) / SR
    bell = np.zeros(D)
    strike = np.zeros(D)
    strike[(np.arange(0, 2.6, 1 / 22) * SR).astype(int)] = 1.0
    for f0, a in [(1180, 1.0), (2860, 0.6), (4120, 0.35), (5650, 0.2)]:
        n = int(SR * 0.6)
        ir = np.sin(2 * np.pi * f0 * np.arange(n) / SR) * np.exp(-np.arange(n) / SR / 0.25) * a
        bell += np.convolve(strike, ir)[:D]
    bell *= np.clip((3.2 - t) / 0.6, 0, 1)
    write("zil", bell, peak=.7, soften=0)

    # --- Mola bitince çalan yumuşak çan ---
    D = int(SR * 2.5)
    t = np.arange(D) / SR
    chime = np.zeros(D)
    for i, f0 in enumerate([659.25, 880.0, 1318.5]):
        st = int(SR * i * 0.18)
        tt = t[: D - st]
        chime[st:] += (np.sin(2 * np.pi * f0 * tt) + 0.3 * np.sin(2 * np.pi * f0 * 2.76 * tt)) * np.exp(-tt / 0.7)
    write("can", chime, peak=.6, soften=0)

    # --- Alkış (yumuşak) ---
    D = int(SR * 4.0)
    clap = np.zeros(D)
    for _ in range(700):
        d = int(SR * 0.02)
        ev = shaped_noise(d, bp(rng.uniform(600, 1200), rng.uniform(2500, 4500))) * env(d, 0.0008, 0.006)
        pos = int(abs(rng.normal(1.4, 0.9)) * SR) % (D - d)
        clap[pos:pos + d] += ev * rng.uniform(0.3, 1.0)
    t = np.arange(D) / SR
    clap *= np.clip(t / 0.2, 0, 1) * np.clip((4.0 - t) / 1.5, 0, 1)
    write("alkis", clap, peak=.5, soften=6000)


if __name__ == "__main__":
    main()
