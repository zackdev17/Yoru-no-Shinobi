"""Backsound WORLD END versi panjang (71,7 dtk) -> assets/audio/sfx/ult_maou_bgm_long.mp3
Timeline mengikuti Skills.WE_* di skills.gd:
  hush 0-7 | ignite 7-19 | burst 19-27.4 | prism 27.4-31 | halo 31-43 | sky 43-51 | sword 51-58 | fall 58-66 | impact 66+
"""
import os, subprocess, tempfile
import numpy as np
from dsp import *
from sfx_maou import choir_pad

D = 71.7
N = n_of(D)
IGNITE, BURST, EYE0, PRISM, HALO, PILLAR, ASCEND, SKY, SWORD, FALL, CONTACT, IMPACT, SHATTER, TEXT = 7.0, 19.0, 21.0, 27.4, 31.0, 33.0, 43.0, 44.6, 51.6, 58.0, 62.0, 66.0, 67.5, 69.1
BEATS = [1.0, 2.3, 3.5, 4.6, 5.6, 6.4, 6.75, 7.0, 8.0, 9.0, 10.0, 11.0, 12.0, 12.5, 13.0, 13.5, 14.0, 14.5, 15.0, 15.5, 16.25, 16.47, 16.664, 16.834, 16.984, 17.116, 17.236, 17.356, 17.476, 17.596, 17.716, 17.836, 17.956, 18.076, 18.196, 18.316, 18.436, 18.556, 18.676, 18.796]


def env(pts):
    return np.interp(T(D), [p[0] for p in pts], [p[1] for p in pts])


def put(layer_fn, t0, d):
    out = np.zeros(N)
    place(out, layer_fn(d), t0)
    return out


def semi(f, s):
    return f * 2 ** (s / 12)


# ---------- suara paduan (choir) berbasis formant ----------
def voice(freqs, t0, d, amp, vowel="ah", att=1.2, rel=1.4, glide_semi=0.0, seed=0):
    r = np.random.default_rng(seed + int(t0 * 10))
    n = n_of(d); t = np.arange(n) / SR
    src = np.zeros(n)
    for f in freqs:
        for cents in (-9, 2, 10):
            g = np.linspace(0, glide_semi, n)
            fr = f * 2 ** ((cents + 0.0) / 1200 + g / 12)
            fr = vibrato(fr, r.uniform(4.8, 5.8), 0.004 + 0.004 * min(1, d / 6), r.uniform(0, 6))
            src += saw(phase(fr))
    src /= max(1, len(freqs) * 3)
    if vowel == "ah":
        x = bp(src, 600, 900) + 0.6 * bp(src, 1000, 1400) + 0.3 * bp(src, 2400, 3100)
    else:
        x = bp(src, 300, 480) + 0.45 * bp(src, 650, 900) + 0.15 * bp(src, 2300, 2900)
    e = np.minimum(1.0, t / max(att, 1e-3)) ** 1.5 * np.minimum(1.0, (d - t) / max(rel, 1e-3)) ** 1.5
    out = np.zeros(N)
    place(out, x * e * amp * 4.0, t0)
    return out


# ---------- perkusi ----------
def hit(amp, size=1.0, d=0.7):
    h = sub_drop(d, 95 * size, 38, 0.17, 1.0, 2.0)
    h += 0.5 * pad(noise_burst(0.12, 0.05, 40, 500), d)
    h += 0.25 * pad(lp(noise_burst(0.35, 0.12), 900, 2), d)
    return h * amp


def taiko(amp, d=1.1):
    h = sub_drop(d, 130, 46, 0.28, 1.0, 2.2) + 0.5 * sub_drop(d, 74, 38, 0.45, 1.0, 2.0)
    h += 0.45 * pad(noise_burst(0.2, 0.05, 90, 1800), d)
    return h * amp


def bell(base, d=12.0):
    # bell panjang (ring 9 dtk lebih)
    return inharm(d, base, [1, 2.0, 2.76, 5.4, 8.9], [9.0, 6.5, 4.5, 2.6, 1.5], [1, .6, .5, .3, .15], vib=0.0015)


PULSES = [52.6, 54.8, 57.0, 59.2, 61.4]  # denyut cincin asap di ujung pedang (sama dengan _wind_ring)


# ---------- lapisan ----------
def drone():
    f = 36.71
    x = sine(phase(np.full(N, f))) + 0.55 * sine(phase(np.full(N, f * 2)))
    for det in (0.993, 1.0, 1.008):
        x += 0.22 * lp(saw(phase(np.full(N, f * 2 * det))), 420, 2)
    amp = env([(0, 0.3), (1.0, 0.4), (7, 0.5), (19, 0.65), (21, 0.5), (27, 0.55), (31, 0.65), (42.8, 0.7), (43.0, 0.6), (44.0, 0.5), (51, 0.55), (58, 0.65), (65.4, 0.75), (65.5, 0.15), (66.0, 0.15), (66.05, 0.85), (69, 0.4), (71.0, 0.1), (71.7, 0)])
    return sat(x * amp, 1.3) * 0.8


def heartbeat():
    out = np.zeros(N)
    for i, t in enumerate(BEATS):
        u = i / (len(BEATS) - 1)
        amp = 0.14 + 0.86 * u ** 1.2
        size = 1.0 + (0.25 if t >= IGNITE else 0.0)
        place(out, hit(amp, size), t)
        place(out, hit(amp * 0.5, 0.9), t + 0.16)
    for k, tt in enumerate([68.7, 69.7, 70.5, 71.0]):
        place(out, hit(0.34 - 0.07 * k, 1.1), tt)
    return out


def riser(t0, t1, level=1.0, f0=160, f1=7500, tone=True):
    d = t1 - t0
    x = sweep(white(d), f0, f1, "bandpass", 1.7)
    out = norm(x, 1.0) * 0.8
    if tone:
        g = glide(110, 1000, d, 2.0)
        s = lp(saw(phase(g)) + saw(phase(g * 1.007)), 2800, 2)
        out = out + norm(s, 1.0) * 0.5
    u = np.linspace(0, 1, n_of(d)) ** 2.2
    lay = np.zeros(N)
    place(lay, out * u * level, t0)
    return lay


def choir_layer():
    L = np.zeros(N)
    # I HUSH : paduan 'oo' sangat pelan
    L += voice([146.83, 220.0], 0.8, 6.4, 0.22, "oo", 2.2, 1.0, seed=1)
    # II IGNITE : Dm -> Bb -> Gm -> A (naik)
    L += voice([146.83, 174.61, 220.0, 293.66], 7.0, 4.2, 0.55, "ah", 0.6, 0.5, seed=2)
    L += voice([116.54, 174.61, 233.08, 293.66], 11.0, 4.2, 0.62, "ah", 0.5, 0.5, seed=3)
    L += voice([98.0, 196.0, 233.08, 293.66], 15.0, 2.2, 0.72, "ah", 0.4, 0.4, seed=4)
    L += voice([110.0, 220.0, 277.18, 329.63], 17.0, 1.9, 0.85, "ah", 0.3, 0.2, seed=5)
    # III BURST : A mayor raksasa lalu Dm kelam (mata)
    L += voice([110.0, 164.81, 220.0, 277.18, 329.63], 19.0, 3.6, 1.0, "ah", 0.15, 1.2, seed=6)
    L += voice([73.42, 146.83, 174.61, 220.0], 22.6, 5.2, 0.5, "oo", 1.6, 1.0, seed=7)
    # IV PRISM : stab pendek
    for i in range(16):
        ch = [[293.66, 349.23, 440.0], [233.08, 293.66, 349.23], [261.63, 329.63, 392.0], [220.0, 277.18, 329.63]][i % 4]
        L += voice(ch, PRISM + 0.2 * i, 0.5, 0.5, "ah", 0.02, 0.3, seed=10 + i)
    # V HALO : Dm | Bb | Gm | A  (epik)
    L += voice([73.42, 146.83, 174.61, 220.0, 293.66], 31.0, 3.4, 0.95, "ah", 0.8, 0.5, seed=21)
    L += voice([58.27, 116.54, 174.61, 233.08, 293.66], 34.0, 3.4, 1.0, "ah", 0.3, 0.5, seed=22)
    L += voice([49.0, 98.0, 196.0, 233.08, 293.66], 37.0, 3.4, 1.05, "ah", 0.3, 0.5, seed=23)
    L += voice([55.0, 110.0, 220.0, 277.18, 329.63], 40.0, 3.0, 1.15, "ah", 0.3, 0.3, seed=24)
    # VI SKY : dingin, nyaris sunyi (oo tinggi)
    L += voice([587.33, 880.0], 44.8, 6.4, 0.12, "oo", 2.5, 2.0, seed=31)
    # VII SWORD : naik perlahan
    L += voice([293.66, 349.23, 440.0], 51.0, 7.4, 0.42, "oo", 2.5, 0.5, glide_semi=3.0, seed=41)
    L += voice([146.83, 220.0], 53.0, 5.4, 0.45, "ah", 2.5, 0.5, glide_semi=2.0, seed=42)
    # VIII FALL : penuh
    L += voice([73.42, 146.83, 174.61, 220.0, 293.66], 58.0, 3.9, 0.95, "ah", 0.4, 0.2, seed=51)
    L += voice([58.27, 116.54, 174.61, 233.08, 349.23], 61.8, 3.7, 1.1, "ah", 0.15, 0.2, seed=52)
    # IX AFTERMATH
    L += voice([73.42, 110.0, 146.83, 174.61], 66.2, 5.5, 0.7, "oo", 0.3, 3.0, seed=61)
    return L


def strings(freqs, t0, d, amp, att=1.0, rel=1.2, seed=0):
    r = np.random.default_rng(seed + int(t0 * 10))
    n = n_of(d); t = np.arange(n) / SR
    src = np.zeros(n)
    for f in freqs:
        for cents in (-7, 0, 8):
            fr = vibrato(np.full(n, f * 2 ** (cents / 1200)), r.uniform(4.5, 5.5), 0.003, r.uniform(0, 6))
            src += saw(phase(fr))
    src /= max(1, len(freqs) * 3)
    x = lp(src, 2200, 2) + 0.25 * bp(src, 2500, 5200)
    e = np.minimum(1.0, t / max(att, 1e-3)) ** 1.4 * np.minimum(1.0, (d - t) / max(rel, 1e-3)) ** 1.4
    out = np.zeros(N)
    place(out, x * e * amp * 3.0, t0)
    return out


def strings_layer():
    """Lapisan senar kontinu (tidak pernah hening, seperti musik referensi): memberi mid-range yang stabil antar-adegan."""
    L = np.zeros(N)
    seq = [  # (t0, d, freqs, amp)
        (0.0, 7.6, [146.83, 220.0, 293.66, 349.23], 0.35), (7.0, 4.4, [146.83, 220.0, 293.66, 349.23], 0.5), (11.0, 4.4, [116.54, 233.08, 293.66, 349.23], 0.55),
        (15.0, 2.4, [98.0, 196.0, 233.08, 293.66], 0.62), (17.0, 2.4, [110.0, 220.0, 277.18, 329.63], 0.7), (19.0, 4.0, [110.0, 220.0, 277.18, 329.63, 440.0], 0.85),
        (22.8, 4.9, [146.83, 220.0, 293.66, 349.23], 0.55), (27.4, 3.8, [293.66, 349.23, 440.0], 0.6),
        (31.0, 3.4, [146.83, 220.0, 293.66, 440.0], 0.8), (34.0, 3.4, [116.54, 233.08, 349.23, 466.16], 0.85), (37.0, 3.4, [98.0, 196.0, 293.66, 392.0], 0.9), (40.0, 3.4, [110.0, 220.0, 277.18, 329.63], 1.0),
        (43.0, 8.4, [293.66, 440.0, 587.33, 659.26], 0.6), (50.8, 3.4, [233.08, 349.23, 466.16], 0.6), (54.0, 4.4, [196.0, 293.66, 392.0], 0.55),
        (58.0, 4.2, [146.83, 220.0, 293.66, 349.23], 0.8), (61.8, 4.0, [116.54, 233.08, 349.23, 466.16], 0.9),
        (66.0, 6.0, [146.83, 220.0, 293.66], 0.6)]
    for i, (t0, d, fr, a) in enumerate(seq):
        L += strings(fr, t0, d + 0.8, a, 0.9, 1.0, seed=100 + i)
    return L


def shimmer_bed():
    """Udara/desis frekuensi tinggi yang mengalir di seluruh durasi (referensi punya banyak energi 2-8 kHz)."""
    x = bp(white(D), 2500, 9000)
    x *= 0.55 + 0.45 * np.sin(2 * np.pi * 0.17 * T(D))
    return x * env([(0, 0.05), (7, 0.09), (19, 0.16), (31, 0.18), (43, 0.1), (44.5, 0.14), (58, 0.15), (65.4, 0.2), (66.5, 0.1), (71.7, 0.0)]) * 0.5


def crackle_bed():
    """Percikan listrik kuning-hijau (sinkron dengan aura angin di sisi pedang)."""
    out = np.zeros(N); r = np.random.default_rng(21)
    t = SWORD + 0.4
    while t < IMPACT - 0.7:
        u = (t - SWORD) / (IMPACT - SWORD)
        ln = r.uniform(0.015, 0.05)
        z = hp(white(ln), r.uniform(2500, 6500)) * np.exp(-T(ln) / (ln * 0.4))
        z += 0.4 * sine(phase(glide(r.uniform(3000, 6000), r.uniform(300, 900), ln, 1.5))) * np.exp(-T(ln) / (ln * 0.5))
        place(out, z * r.uniform(0.2, 0.6) * (0.4 + 0.8 * u), t)
        t += r.exponential(1.0 / (5 + 9 * u))
    return out


def downers():
    """Ekor rumble rendah setelah tiap hantaman besar, supaya transisi tidak terputus."""
    out = np.zeros(N)
    for tt, d, lv in [(BURST, 4.0, 1.0), (PILLAR, 3.0, 0.7), (ASCEND, 3.0, 0.7), (SWORD, 4.0, 0.7), (CONTACT, 4.0, 1.0), (IMPACT, 5.0, 1.2)]:
        x = lp(brown(d), 240, 2)
        x = norm(x, 1.0) * np.exp(-T(d) / (d * 0.35))
        place(out, x * lv * 0.7, tt)
    return out


def ring_pulses():
    out = np.zeros(N)
    for tp in PULSES:
        d = 2.4
        w = sweep(white(d), 500, 3200, "bandpass", 1.6) * swell(d, 0.3, 1.8, 1.5) * 0.5
        place(out, w, tp)
        place(out, hit(0.35, 0.8), tp + 0.12)
    return out


def percussion():
    out = np.zeros(N)
    # prism: kick tiap tebasan
    for i in range(16):
        place(out, taiko(0.35 + 0.012 * i, 0.6), PRISM + 0.15 + 0.21 * i)
    # halo: taiko tiap 0.75s, aksen tiap 4
    t = HALO + 0.4; k = 0
    while t < ASCEND - 0.8:
        place(out, taiko(0.55 if k % 4 else 0.9, 1.0), t)
        if k % 2 == 1: place(out, taiko(0.3, 0.6), t + 0.375)
        t += 0.75; k += 1
    # fall: 16th yang makin rapat
    t = FALL + 0.2; iv = 0.5; k = 0
    while t < IMPACT - 0.55:
        place(out, taiko(0.3 + 0.7 * (t - FALL) / (IMPACT - FALL), 0.6), t)
        t += iv; iv = max(0.085, iv * 0.93); k += 1
    # titik besar
    for tt, a in [(BURST, 1.0), (EYE0, 0.6), (PILLAR, 0.9), (CONTACT, 1.0), (ASCEND, 0.9), (SWORD, 0.7)]:
        place(out, taiko(a, 1.6), tt)
    return out


def bells():
    out = np.zeros(N)
    for tt, base, a in [(IGNITE, 146.8, 0.5), (BURST, 110.0, 0.8), (EYE0, 73.4, 0.55), (PILLAR, 146.8, 0.65), (ASCEND, 220.0, 0.7), (SWORD, 146.8, 0.9),
                        (CONTACT, 98.0, 0.9), (IMPACT, 73.4, 1.0), (TEXT + 0.1, 82.4, 1.0), (70.4, 73.4, 0.5)]:
        place(out, bell(base) * a, tt)
        place(out, bell(base * 2.0, 8.0) * a * 0.35, tt)
    notes = [587.33, 698.46, 880.0, 1046.5, 880.0, 698.46]
    t = SKY; k = 0
    while t < SWORD - 0.5:
        place(out, inharm(5.5, notes[k % 6], [1, 2.76, 5.4], [4.0, 2.2, 1.0], [0.5, 0.2, 0.1]) * 0.5, t)
        t += 0.9; k += 1
    return out


def air():
    out = np.zeros(N)
    # angin dingin di langit malam
    d = SWORD - SKY
    w = sweep(pink(d), 300, 1400, "bandpass", 1.8) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.3 * T(d))) * swell(d, 0.5, 1.6, 1.5)
    place(out, w * 0.45, SKY)
    # setelah dunia pecah
    d2 = D - 68.0
    w2 = sweep(pink(d2), 260, 900, "bandpass", 1.8) * swell(d2, 0.3, 1.5, 1.2)
    place(out, w2 * 0.5, 68.0)
    return out


def roar():
    out = np.zeros(N)
    d = 4.6
    b = sweep(brown(d), 420, 110, "lowpass")
    b = norm(b, 1.0) * np.exp(-T(d) / 3.2)
    place(out, b * 0.9, IMPACT + 0.1)
    deb = rock_debris(SHATTER - IMPACT, 14, 3, 120, 2200, 0.5, seed=11)
    place(out, deb, IMPACT + 0.2)
    sc = hp(sweep(white(1.8), 7000, 500, "bandpass", 1.5), 300, 2) * np.exp(-T(1.8) / 0.9)
    place(out, norm(sc, 1.0) * 0.55, SHATTER)
    return out


def glass():
    out = np.zeros(N)
    r = np.random.default_rng(77)
    d = 2.6; t = T(d)
    for i in range(14):
        f = r.uniform(1800, 6500)
        trem = 0.5 + 0.5 * np.sin(2 * np.pi * r.uniform(7, 18) * t + r.uniform(0, 6.28))
        x = sine(phase(np.full(n_of(d), f))) * trem * np.exp(-t / r.uniform(0.5, 1.4))
        place(out, x * 0.05, SHATTER + r.uniform(0, 0.5))
    return out


# kurva loudness target (dB RMS) per adegan : hening -> naik -> ledakan -> sunyi langit malam -> klimaks
TARGET = [(0, -20), (1.0, -19), (6.5, -17), (7.0, -15), (12, -13.5), (18.5, -12), (19.0, -7.5), (21, -10.5), (23, -12), (27, -10), (31, -9),
          (40, -8.5), (42.8, -8), (43.2, -12.5), (45, -13.5), (49, -13), (51, -12), (55, -11), (58, -10.5), (65.4, -7),
          (66.2, -6.5), (68, -10), (70, -15), (71.7, -30)]


def agc(st, hop=0.25, win=1.0):
    mono = st.mean(axis=0)
    w = int(win * SR); h = int(hop * SR)
    centers = np.arange(0, N, h)
    meas = []
    for c in centers:
        a, b = max(0, c - w // 2), min(N, c + w // 2)
        seg = mono[a:b]
        meas.append(20 * np.log10(np.sqrt(np.mean(seg ** 2)) + 1e-6))
    meas = np.array(meas)
    tgt = np.interp(centers / SR, [p[0] for p in TARGET], [p[1] for p in TARGET])
    g = np.clip(tgt - meas, -24, 14)
    g = np.convolve(np.pad(g, 3, mode="edge"), np.ones(7) / 7, mode="valid")
    gain = 10 ** (np.interp(np.arange(N) / SR, centers / SR, g) / 20)
    return st * gain


def build():
    pad_layers = choir_layer() * 1.3 + strings_layer() * 1.1 + bells() * 0.32 + glass() * 3.0
    dry_layers = (drone() * 1.5 + heartbeat() * 0.7 + percussion() * 0.75 + air() * 1.4 + roar() * 2.0 + shimmer_bed() * 5.5 + crackle_bed() * 1.3 + downers() + ring_pulses()
                  + riser(IGNITE - 2.4, IGNITE, 0.5) + riser(BURST - 3.0, BURST, 0.8) + riser(ASCEND - 2.4, ASCEND, 0.9)
                  + riser(SWORD, FALL, 0.55, 300, 6000, False) + riser(FALL, IMPACT - 0.5, 1.1))
    wet = reverb(pad_layers, wet=0.55, d=3.2, tau=1.3, dark=4200, seed=21)
    dry = np.stack([dry_layers, dry_layers])
    wet = np.stack([pad(c, D) for c in wet])
    st = wet + dry
    st = agc(st)
    duck = env([(0, 1), (BURST - 0.12, 1), (BURST - 0.04, 0.35), (BURST + 0.2, 0.45), (BURST + 0.6, 1),
                (ASCEND - 0.1, 1), (ASCEND - 0.02, 0.35), (ASCEND + 0.7, 0.7), (SKY, 1),
                (IMPACT - 0.5, 1), (IMPACT - 0.44, 0.25), (IMPACT + 0.06, 0.25), (IMPACT + 0.22, 1), (D, 1)])
    st = st * duck
    st = master(st, peak=0.9, drive=1.0, dur=D)
    st = norm(np.tanh(st * 1.15) / np.tanh(1.15), 0.9)
    st *= np.minimum(1.0, np.linspace(0, 1, st.shape[1]) * D / 1.2)
    st *= np.minimum(1.0, np.linspace(1, 0, st.shape[1]) * D / 0.8)
    return st


if __name__ == "__main__":
    out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "audio", "sfx")
    wav = os.path.join(tempfile.mkdtemp(), "ult_maou_bgm_long.wav")
    write_wav(wav, build())
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-ar", "44100", "-ac", "2", "-c:a", "libmp3lame", "-b:a", "160k",
                    os.path.join(out_dir, "ult_maou_bgm_long.mp3")], check=True)
    print("ok ult_maou_bgm_long")
