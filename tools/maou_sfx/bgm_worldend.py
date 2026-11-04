import os, subprocess, tempfile
import numpy as np
from dsp import *

D = 16.6
N = n_of(D)
IMPACT, SHATTER, TEXT = 10.2, 12.2, 13.8


def env(pts):
    return np.interp(T(D), [p[0] for p in pts], [p[1] for p in pts])


def at(layer_fn, t0, d):
    out = np.zeros(N)
    place(out, layer_fn(d), t0)
    return out


def drone():
    f = 36.71 * 2 ** (env([(0, 0), (4.4, 0.6 / 12), (10.0, 3 / 12), (12.2, 0), (16.6, -5 / 12)]))
    x = sine(phase(f)) + 0.55 * sine(phase(f * 2))
    for det in (0.993, 1.0, 1.008):
        x += 0.22 * lp(saw(phase(f * 2 * det)), 420, 2)
    amp = env([(0, 0), (1.0, 0.10), (3.0, 0.16), (4.4, 0.26), (8.0, 0.42), (10.0, 0.62), (12.2, 0.62), (14.0, 0.40), (16.2, 0.16), (16.6, 0)])
    return sat(x * amp, 1.3) * 0.8


def choir():
    t = T(D)
    shift = env([(0, 0), (1.2, 0), (10.0, 2.6), (12.2, 2.6), (16.6, -10)])
    notes = [146.83, 155.56, 207.65, 220.00, 293.66, 311.13]
    vib = 1 + (0.003 + 0.010 * np.clip(t / 10.0, 0, 1)) * np.sin(2 * np.pi * 5.4 * t)
    src = np.zeros(N)
    for i, f0 in enumerate(notes):
        f = f0 * 2 ** (shift / 12) * vib * (1 + 0.0022 * (i - 2.5))
        src += saw(phase(f)) / len(notes)
        src += 0.5 * saw(phase(f * 1.004)) / len(notes)
    o = bp(src, 380, 560) + 0.5 * bp(src, 700, 950) + 0.2 * bp(src, 2400, 3000)
    a = bp(src, 650, 950) + 0.6 * bp(src, 1000, 1400) + 0.3 * bp(src, 2500, 3200)
    mix = env([(0, 0), (4.4, 0.2), (10.0, 1.0), (12.2, 1.0), (16.6, 0.2)])
    x = o * (1 - mix) + a * mix
    amp = env([(0, 0), (1.2, 0.0), (3.0, 0.16), (4.4, 0.26), (8.0, 0.6), (10.0, 0.95), (12.2, 1.0), (13.8, 0.55), (16.0, 0.12), (16.6, 0)])
    return norm(x, 1.0) * amp


def hit(amp, size=1.0):
    h = sub_drop(0.7, 95 * size, 38, 0.17, 1.0, 2.0)
    h += 0.5 * pad(noise_burst(0.12, 0.05, 40, 500), 0.7)
    h += 0.25 * pad(lp(noise_burst(0.35, 0.12), 900, 2), 0.7)
    return h * amp


def heartbeat():
    out = np.zeros(N)
    t = 0.55
    while t < 9.95:
        u = (t - 0.55) / 9.4
        interval = 1.05 + (0.23 - 1.05) * u ** 1.25
        amp = 0.12 + 0.88 * u ** 1.4
        place(out, hit(amp), t)
        place(out, hit(amp * 0.5, 0.9), t + min(0.2, 0.33 * interval))
        t += interval
    t = IMPACT + 0.55
    k = 0
    while t < SHATTER + 1.2:
        place(out, hit(1.0 - 0.07 * k, 1.25), t)
        t += 0.78 + 0.05 * k
        k += 1
    for i, tt in enumerate([14.3, 15.3, 16.0]):
        place(out, hit(0.34 - 0.09 * i, 1.1), tt)
        place(out, hit((0.34 - 0.09 * i) * 0.5, 1.0), tt + 0.2)
    return out


def bell(base, d=5.0):
    return inharm(d, base, [1, 2.0, 2.76, 5.4, 8.9], [3.2, 2.4, 1.7, 1.0, 0.6], [1, .6, .5, .3, .15], vib=0.0015)


def bells():
    out = np.zeros(N)
    for tt, base, a in [(2.0, 110, 0.5), (4.6, 110, 0.6), (7.0, 98, 0.7), (8.8, 98, 0.8), (9.55, 92.5, 0.8),
                        (TEXT + 0.15, 82.4, 0.85), (15.2, 73.4, 0.5)]:
        place(out, bell(base) * a, tt)
    return out


def riser():
    d = 5.8
    x = sweep(white(d), 160, 7500, "bandpass", 1.7)
    g = glide(110, 880, d, 2.0)
    s = lp(saw(phase(g)) + saw(phase(g * 1.007)), 2600, 2)
    u = np.linspace(0, 1, n_of(d)) ** 2.2
    r = (norm(x, 1.0) * 0.8 + norm(s, 1.0) * 0.5) * u
    out = np.zeros(N)
    place(out, r, 4.4)
    rv = (hp(white(1.1), 2500, 2) * np.linspace(0, 1, n_of(1.1)) ** 3)
    place(out, rv * 0.9, IMPACT - 1.15)
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
    d = 2.6
    t = T(d)
    for i in range(14):
        f = r.uniform(1800, 6500)
        trem = 0.5 + 0.5 * np.sin(2 * np.pi * r.uniform(7, 18) * t + r.uniform(0, 6.28))
        x = sine(phase(np.full(n_of(d), f))) * trem * np.exp(-t / r.uniform(0.5, 1.4))
        place(out, x * 0.05, SHATTER + r.uniform(0, 0.5))
    return out


def void_wind():
    d = TEXT - 12.9 + (D - TEXT) + 0.2
    w = sweep(pink(D - 12.9), 260, 900, "bandpass", 1.8)
    w = norm(w, 1.0) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.35 * T(D - 12.9))) * swell(D - 12.9, 0.3, 1.5, 1.2)
    out = np.zeros(N)
    place(out, w * 0.5, 12.9)
    return out


def build():
    pad_layers = choir() * 2.3 + bells() * 0.14 + glass() * 3.0
    dry_layers = drone() * 0.55 + heartbeat() * 0.75 + riser() * 0.8 + roar() * 2.0 + void_wind() * 2.5
    wet = reverb(pad_layers, wet=0.55, d=3.2, tau=1.3, dark=4200, seed=21)
    dry = np.stack([dry_layers, dry_layers])
    wet = np.stack([pad(c, D) for c in wet])
    st = wet + dry
    duck = env([(0, 1), (IMPACT - 0.22, 1), (IMPACT - 0.07, 0.10), (IMPACT + 0.12, 0.10), (IMPACT + 0.45, 1), (D, 1)])
    st = st * duck
    st = master(st, peak=0.86, drive=1.15, dur=D)
    st *= np.minimum(1.0, np.linspace(0, 1, st.shape[1]) * D / 0.6)
    st *= np.minimum(1.0, np.linspace(1, 0, st.shape[1]) * D / 0.7)
    return st


if __name__ == "__main__":
    out_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "audio", "sfx")
    wav = os.path.join(tempfile.mkdtemp(), "ult_maou_bgm.wav")
    write_wav(wav, build())
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-ar", "44100", "-ac", "2", "-c:a", "libmp3lame", "-b:a", "160k",
                    os.path.join(out_dir, "ult_maou_bgm.mp3")], check=True)
    print("ok ult_maou_bgm")
