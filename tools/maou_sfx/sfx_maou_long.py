"""SFX tambahan untuk WORLD END versi panjang (71,7 dtk).
Setiap file punya puncak (peak) pada offset tertentu supaya jatuh tepat pada momen visual:
  ult_maou_ignite  puncak 0.35  -> dijadwalkan di WE_IGNITE - 0.35
  ult_maou_shock   puncak 0.30  -> WE_BURST - 0.30
  ult_maou_prism   tebasan ke-i pada 0.15 + 0.21*i, finale 3.6 -> WE_PRISM
  ult_maou_halo    7.0 dtk       -> WE_HALO + 0.2
  ult_maou_thunder sambaran pada 0.05/0.90/1.75/2.80 -> WE_BOLT0
  ult_maou_summon  puncak 3.4   -> WE_SWORD - 3.4
  ult_maou_fall    kontak 4.0   -> WE_FALL
  ult_maou_hit     dentuman gong/taiko tunggal
"""
from dsp import *
from sfx_maou import choir_pad


def stereo(L, R=None):
    R = L if R is None else R
    n = max(len(L), len(R))
    return np.stack([pad(L, n / SR), pad(R, n / SR)])


def bell(base, d, amp=1.0):
    # bell panjang: dering utama bertahan hampir seluruh durasi d
    return inharm(d, base, [1, 2.0, 2.76, 5.4, 8.9], [d * 0.95, d * 0.72, d * 0.5, d * 0.3, d * 0.18], [1, .6, .5, .3, .15], vib=0.0015) * amp


def rev_swell(d, f0=300, f1=6000, level=1.0, power=2.6):
    return sweep(white(d), f0, f1, "bandpass", 1.7) * swell(d, 0.98, power, 0.1) * level


def ult_maou_ignite():
    D = 7.0; P = 0.35
    x = np.zeros(n_of(D))
    place(x, rev_swell(P, 200, 5000, 0.5), 0.0)
    fire = sweep(white(3.4), 3800, 380, "bandpass", 1.5) * np.exp(-T(3.4) / 1.1)
    fire += 0.8 * sweep(pink(3.4), 1800, 220, "bandpass", 1.6) * np.exp(-T(3.4) / 1.5)
    place(x, fire * 0.9, P)
    place(x, sub_drop(2.6, 88, 24, 0.9, drive=2.4), P)
    place(x, noise_burst(0.5, 0.08, 80, 2500) * 0.9, P)
    r = np.random.default_rng(5)
    for _ in range(160):
        t = P + r.exponential(0.9)
        if t > D - 0.2: continue
        ln = r.uniform(0.004, 0.02)
        place(x, hp(white(ln), r.uniform(2500, 6000)) * np.exp(-T(ln) / (ln * 0.4)) * r.uniform(0.2, 0.9) * np.exp(-(t - P) / 1.4), t)
    ch = np.zeros(n_of(D))
    place(ch, choir_pad(3.6, [146.83, 174.61, 220.0, 293.66], lp_sweep=(600, 3200), vowel=((600, 1000), (800, 1250)), seed=31) * swell(3.6, 0.2, 1.4, 1.4), 0.2)
    place(ch, bell(293.66, 3.0, 0.5), P)
    return master(reverb(sat(x * 0.9 + 0.7 * ch, 1.3), wet=0.3, d=4.6, tau=1.9, pre=0.02, dark=5000, seed=201), 0.95, dur=D)


def ult_maou_shock():
    D = 8.0; P = 0.30
    x = np.zeros(n_of(D))
    place(x, rev_swell(P, 150, 3500, 0.8), 0.0)
    place(x, sub_drop(3.8, 96, 17, 1.2, drive=2.8), P)
    place(x, noise_burst(0.3, 0.03, 600, None) * 1.1, P)
    place(x, noise_burst(2.4, 0.5, 40, 500, kind=brown) * 2.2, P)
    place(x, sweep(white(1.4), 9000, 180, "bandpass", 1.6) * np.exp(-T(1.4) / 0.35) * 0.9, P)
    place(x, rock_debris(3.0, 24, 2, 100, 2600, 1.1, seed=203), P + 0.1)
    place(x, bell(110.0, 8.0, 0.7), P)
    place(x, sub_drop(2.0, 50, 20, 0.9, drive=2.0) * 0.7, P + 0.45)
    return master(reverb(sat(x, 1.5), wet=0.38, d=5.2, tau=2.3, pre=0.025, dark=4200, seed=211), 0.97, dur=D)


def whip(d=0.45, f0=7500, f1=800, level=1.0):
    n = sweep(white(d), f0, f1, "bandpass", 1.5) * swell(d, 0.12, 1.0, 1.6)
    return n * level


def ult_maou_prism():
    D = 8.5
    L = np.zeros(n_of(D)); R = np.zeros(n_of(D))
    scale = [0, 2, 4, 7, 9, 12, 14, 16]
    for i in range(16):
        t = 0.15 + 0.21 * i
        f = 880 * 2 ** (scale[i % len(scale)] / 12)
        w = whip(0.5, 9000 - 150 * i, 700, 0.9)
        ring = inharm(0.7, f, [1, 1.5, 2.01, 3.2], [0.3, 0.22, 0.16, 0.1], [0.4, 0.3, 0.2, 0.12]) * 0.5
        thud = sub_drop(0.3, 120, 40, 0.1, drive=2.0) * 0.5
        s = pad(w, 0.7) + pad(ring, 0.7) + pad(thud, 0.7)
        pan = 0.15 if i % 2 == 0 else 0.85
        place(L, s * (1 - pan) * 1.4, t); place(R, s * pan * 1.4, t)
    fin = np.zeros(n_of(D))
    place(fin, rev_swell(0.6, 600, 9000, 1.0), 3.0)
    place(fin, sub_drop(2.0, 80, 22, 0.7, drive=2.4), 3.6)
    place(fin, noise_burst(0.4, 0.05, 500, None), 3.6)
    place(fin, bell(587.0, 5.0, 0.6), 3.6)
    place(fin, bell(293.6, 7.0, 0.5), 3.6)
    place(fin, hp(white(1.6), 5000) * np.exp(-T(1.6) / 0.5) * 0.4, 3.6)
    st = stereo(L + fin, R + fin)
    return master(st, 0.95, dur=D)


def ult_maou_halo():
    D = 9.5
    L = np.zeros(n_of(D)); R = np.zeros(n_of(D))
    r = np.random.default_rng(7)
    for k in range(4):
        per = [2.4, 3.0, 1.9, 3.7][k]
        ph0 = [0.0, 0.7, 1.1, 0.4][k]
        t = ph0
        while t < D - 1.2:
            d = 1.2
            n = sweep(white(d), 500 * (1 + 0.5 * k), 3800, "bandpass", 1.8) * swell(d, 0.5, 1.6, 1.6)
            n += 0.5 * sweep(pink(d), 220, 1400, "bandpass", 1.6) * swell(d, 0.5, 1.6, 1.6)
            sgn = 1 if k % 2 == 0 else -1
            pan = np.linspace(0.1, 0.9, n_of(d)) if sgn > 0 else np.linspace(0.9, 0.1, n_of(d))
            place(L, n * (1 - pan) * 0.9, t); place(R, n * pan * 0.9, t)
            t += per
    sh = np.zeros(n_of(D))
    for i in range(18):
        f = 1200 * 2 ** (r.choice([0, 3, 7, 10, 12, 15]) / 12)
        t = r.uniform(0, D - 1.5)
        place(sh, inharm(1.4, f, [1, 2.4, 3.7], [0.5, 0.3, 0.2], [0.3, 0.2, 0.1]) * r.uniform(0.15, 0.4), t)
    ch = choir_pad(D, [146.83, 220.0, 293.66, 349.23], lp_sweep=(500, 3600), vowel=((600, 1000), (800, 1250)), seed=77) * swell(D, 0.55, 1.5, 1.6)
    rs = np.zeros(n_of(D)); place(rs, sub_drop(2.4, 62, 22, 1.0, drive=2.0), 0.0)
    st = stereo(L + 0.8 * sh + 0.6 * ch + 0.7 * rs, R + 0.8 * sh + 0.6 * ch + 0.7 * rs)
    wet = reverb(st[0] * 0.5 + st[1] * 0.5, wet=0.5, d=4.4, tau=1.8, pre=0.02, dark=5000, seed=221)
    n = wet.shape[1]
    dry = np.stack([np.pad(st[0], (0, n - st.shape[1])), np.pad(st[1], (0, n - st.shape[1]))])
    return master(wet * 0.6 + dry * 0.7, 0.9, dur=D)


def thunder_crack(delay_tail=2.2):
    ln = 0.9
    c = hp(white(0.22), 1500) * np.exp(-T(0.22) / 0.03)
    zap = sine(phase(glide(7000, 150, 0.25, 1.6))) * np.exp(-T(0.25) / 0.06) * 0.6
    body = noise_burst(1.8, 0.4, 40, 800, kind=brown) * 1.6
    sizz = hp(white(1.2), 4500) * np.exp(-T(1.2) / 0.25) * (0.5 + 0.5 * np.abs(sine(phase(glide(40, 120, 1.2)))))
    sub = sub_drop(1.6, 70, 26, 0.5, drive=2.0)
    out = np.zeros(n_of(2.6))
    place(out, pad(c, 0.25) * 1.1 + zap, 0.0); place(out, body, 0.05); place(out, sizz * 0.5, 0.0); place(out, sub * 0.9, 0.08)
    return out


def ult_maou_thunder():
    D = 8.5
    x = np.zeros(n_of(D))
    for i, (t, g) in enumerate([(0.05, 1.0), (0.25, 0.55), (0.95, 0.45)]):
        place(x, thunder_crack() * g, t)
    place(x, sub_drop(3.0, 60, 20, 1.0, drive=2.4), 0.08)
    wind = sweep(pink(D), 150, 900, "bandpass", 1.8) * swell(D, 0.3, 1.5, 1.2) * 0.2
    return master(reverb(sat(x + wind, 1.3), wet=0.3, d=4.8, tau=2.1, pre=0.02, dark=4500, seed=231), 0.95, dur=D)


def ult_maou_citypillar():
    """Pilar cahaya emas naik dari gedung (puncak di 0.1 dtk): whoosh naik cepat + dengung kristal + percikan, lalu menipis."""
    D = 5.0
    x = np.zeros(n_of(D))
    up = sweep(white(0.5), 250, 7000, "bandpass", 1.6) * swell(0.5, 0.85, 1.4, 0.7) * 0.9
    place(x, up, 0.0)
    place(x, sub_drop(1.6, 90, 40, 0.5, drive=1.8) * 0.6, 0.1)
    hum = sine(phase(vibrato(np.full(n_of(3.6), 440.0), 5.0, 0.004))) + 0.5 * sine(phase(np.full(n_of(3.6), 660.0))) + 0.25 * sine(phase(np.full(n_of(3.6), 1320.0)))
    place(x, hum * swell(3.6, 0.1, 1.2, 1.6) * 0.22, 0.1)
    r = np.random.default_rng(17)
    for _ in range(34):
        t = 0.1 + r.uniform(0, 3.2)
        f = 1500 * 2 ** (r.choice([0, 4, 7, 12, 16, 19]) / 12)
        place(x, inharm(0.6, f, [1, 2.76], [0.4, 0.25], [0.3, 0.12]) * r.uniform(0.08, 0.3) * np.exp(-(t - 0.1) / 2.0), t)
    place(x, bell(220.0, 6.0, 0.35), 0.1)
    fade = sweep(white(2.0), 5000, 500, "bandpass", 1.7) * swell(2.0, 0.1, 1.0, 1.6) * 0.3
    place(x, fade, 1.8)
    return master(reverb(sat(x, 1.2), wet=0.4, d=4.4, tau=1.9, pre=0.02, dark=5500, seed=291), 0.92, dur=D)


def ult_maou_summon():
    D = 11.5; P = 3.4
    x = np.zeros(n_of(D))
    th = sine(phase(vibrato(glide(900, 3400, P, 1.6), 5.0, 0.004))) * swell(P, 0.97, 2.4, 0.2) * 0.18
    place(x, th, 0.0)
    place(x, rev_swell(P, 500, 8000, 0.35, 3.0), 0.0)
    r = np.random.default_rng(9)
    for i in range(22):
        t = P * (i / 22.0) ** 0.8
        f = 1000 * 2 ** (r.choice([0, 4, 7, 11, 12, 16]) / 12) * (1 + 0.4 * t / P)
        place(x, inharm(0.9, f, [1, 2.76], [0.3, 0.2], [0.3, 0.15]) * (0.2 + 0.5 * t / P), t)
    place(x, bell(146.83, 10.0, 1.0), P)
    place(x, bell(293.66, 8.0, 0.7), P)
    place(x, bell(440.0, 6.0, 0.35), P + 0.05)
    place(x, sub_drop(2.4, 70, 24, 0.8, drive=2.2), P)
    place(x, noise_burst(0.35, 0.06, 300, 4000), P)
    ch = choir_pad(2.0, [146.83, 185.0, 220.0, 293.66], lp_sweep=(500, 3600), vowel=((600, 1000), (800, 1250)), seed=41) * swell(2.0, 0.25, 1.3, 1.4)
    place(x, ch * 0.9, P - 0.1)
    return master(reverb(sat(x, 1.25), wet=0.38, d=5.2, tau=2.3, pre=0.03, dark=5500, seed=241), 0.95, dur=D)


def ult_maou_fall():
    D = 12.5; K = 4.0
    x = np.zeros(n_of(D))
    pre = sweep(white(K), 200, 7000, "bandpass", 1.6) * swell(K, 0.98, 2.2, 0.1) * 0.8
    whis = sine(phase(vibrato(glide(2400, 380, K, 1.3), 6.0, 0.01))) * swell(K, 0.95, 2.0, 0.2) * 0.3
    rum = sweep(brown(K), 60, 240, "lowpass") * swell(K, 0.98, 1.8, 0.1) * 1.8
    sub = sine(phase(glide(26, 70, K, 1.2))) * swell(K, 0.98, 2.0, 0.1)
    place(x, pre + whis + rum + sub * 0.8, 0.0)
    place(x, sub_drop(4.6, 74, 16, 1.4, drive=2.8), K)
    place(x, noise_burst(0.25, 0.03, 500, None) * 1.2, K)
    place(x, noise_burst(2.8, 0.55, 40, 520, kind=brown) * 2.4, K)
    place(x, bell(98.0, 11.0, 0.95), K)
    place(x, sweep(white(1.8), 9500, 200, "bandpass", 1.7) * np.exp(-T(1.8) / 0.45), K)
    place(x, rock_debris(3.8, 30, 6, 90, 3000, 1.3, seed=251), K + 0.05)
    roar = sweep(pink(D - K), 120, 1800, "bandpass", 1.7) * swell(D - K, 0.55, 1.0, 1.8) * 0.8
    place(x, roar, K)
    place(x, choir_pad(4.5, [73.42, 110.0, 146.83, 220.0], lp_sweep=(700, 2600), vowel=((700, 1100), (800, 1250)), seed=51, level=1.2) * swell(4.5, 0.4, 1.0, 1.7), K + 0.1)
    return master(reverb(sat(x, 1.4), wet=0.33, d=5.0, tau=2.2, pre=0.025, dark=4600, seed=261), 0.97, dur=D)


def ult_maou_hit():
    D = 6.5
    x = np.zeros(n_of(D))
    place(x, sub_drop(1.8, 85, 22, 0.55, drive=2.6), 0.0)
    place(x, noise_burst(0.3, 0.04, 300, 4000) * 0.9, 0.0)
    place(x, bell(130.8, 6.0, 1.0), 0.0)
    place(x, bell(261.6, 4.5, 0.4), 0.0)
    return master(reverb(sat(x, 1.4), wet=0.28, d=4.0, tau=1.7, pre=0.02, dark=4800, seed=271), 0.95, dur=D)


def ult_maou_windpulse():
    """Cincin asap memekar dari ujung pedang + percikan listrik kuning-hijau (dijadwalkan di tiap denyut cincin)."""
    D = 4.2
    x = np.zeros(n_of(D))
    place(x, sweep(white(2.6), 500, 3400, "bandpass", 1.6) * swell(2.6, 0.3, 1.8, 1.5) * 0.8, 0.0)
    place(x, sweep(pink(3.0), 160, 700, "bandpass", 1.7) * swell(3.0, 0.3, 1.6, 1.4) * 0.7, 0.0)
    place(x, sub_drop(2.2, 60, 28, 0.6, drive=1.8) * 0.8, 0.15)
    r = np.random.default_rng(13)
    for _ in range(26):
        t = 0.05 + r.exponential(0.8)
        if t > D - 0.4: continue
        ln = r.uniform(0.02, 0.07)
        z = hp(white(ln), r.uniform(2500, 6500)) * np.exp(-T(ln) / (ln * 0.4))
        z += 0.5 * sine(phase(glide(r.uniform(3000, 6000), r.uniform(300, 900), ln, 1.5))) * np.exp(-T(ln) / (ln * 0.5))
        place(x, z * r.uniform(0.25, 0.8) * np.exp(-t / 1.6), t)
    place(x, bell(220.0, 4.0, 0.25), 0.15)
    return master(reverb(sat(x, 1.2), wet=0.4, d=4.2, tau=1.8, pre=0.02, dark=5200, seed=281), 0.9, dur=D)


SOUNDS_LONG = {
    "ult_maou_citypillar": ult_maou_citypillar,
    "ult_maou_windpulse": ult_maou_windpulse,
    "ult_maou_ignite": ult_maou_ignite, "ult_maou_shock": ult_maou_shock, "ult_maou_prism": ult_maou_prism,
    "ult_maou_halo": ult_maou_halo, "ult_maou_thunder": ult_maou_thunder, "ult_maou_summon": ult_maou_summon,
    "ult_maou_fall": ult_maou_fall, "ult_maou_hit": ult_maou_hit,
}
