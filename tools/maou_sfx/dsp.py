import numpy as np
from scipy import signal
SR = 44100
rng = np.random.default_rng(1337)

def n_of(d): return int(round(d * SR))
def T(d): return np.arange(n_of(d)) / SR
def white(d): return rng.standard_normal(n_of(d))

def _sos(kind, f, order):
    f = np.clip(f, 15.0, SR * 0.45)
    return signal.butter(order, f, btype=kind, fs=SR, output="sos")
def lp(x, f, o=2): return signal.sosfilt(_sos("lowpass", f, o), x)
def hp(x, f, o=2): return signal.sosfilt(_sos("highpass", f, o), x)
def bp(x, lo, hi, o=2): return signal.sosfilt(_sos("bandpass", [lo, hi], o), x)

def sweep(x, f0, f1, kind="lowpass", bw=1.5, order=2, chunk=441):
    n = len(x); out = np.zeros(n); zi = None
    nch = (n + chunk - 1) // chunk
    for k in range(nch):
        a, b = k * chunk, min(n, (k + 1) * chunk)
        f = f0 * (f1 / f0) ** ((k + 0.5) / nch)
        f = float(np.clip(f, 20.0, SR * 0.45))
        if kind == "bandpass":
            lo, hi = max(15.0, f / bw), min(SR * 0.45, f * bw)
            sos = signal.butter(order, [lo, hi], btype="bandpass", fs=SR, output="sos")
        else:
            sos = signal.butter(order, f, btype=kind, fs=SR, output="sos")
        if zi is None: zi = np.zeros((sos.shape[0], 2))
        y, zi = signal.sosfilt(sos, x[a:b], zi=zi)
        out[a:b] = y
    return out

def glide(f0, f1, d, power=1.0):
    u = np.linspace(0, 1, n_of(d)) ** power
    return f0 * (f1 / f0) ** u
def phase(freq): return np.cumsum(freq) / SR
def sine(ph): return np.sin(2 * np.pi * ph)
def saw(ph): return 2.0 * (ph % 1.0) - 1.0
def square(ph): return np.where((ph % 1.0) < 0.5, 1.0, -1.0)

def sat(x, drive=3.0): return np.tanh(x * drive) / np.tanh(drive)
def norm(x, peak=0.9):
    m = np.max(np.abs(x)) + 1e-9
    return x * (peak / m)
def fade(x, a=0.004, r=0.03):
    x = x.copy(); na, nr = int(a * SR), int(r * SR)
    if na: x[:na] *= np.linspace(0, 1, na)
    if nr: x[-nr:] *= np.linspace(1, 0, nr)
    return x
def pad(x, d):
    n = n_of(d)
    return np.pad(x, (0, max(0, n - len(x))))[:n]
def place(dst, src, at):
    a = n_of(at)
    if a >= len(dst): return
    b = min(len(dst), a + len(src))
    dst[a:b] += src[: b - a]
def exp_env(d, tau): return np.exp(-T(d) / tau)
def swell(d, peak=0.7, p_in=2.0, p_out=1.5):
    u = np.linspace(0, 1, n_of(d))
    return np.where(u < peak, (u / peak) ** p_in, (1 - (u - peak) / (1 - peak)) ** p_out)
def vibrato(f, rate, depth, ph0=0.0):
    t = np.arange(len(f)) / SR
    return f * (1 + depth * np.sin(2 * np.pi * rate * t + ph0))

def brown(d):
    x = np.cumsum(white(d)); x = hp(x, 12.0, 1)
    return x / (np.max(np.abs(x)) + 1e-9)
def pink(d):
    x = white(d)
    b, a = [0.049922035, -0.095993537, 0.050612699, -0.004408786], [1, -2.494956002, 2.017265875, -0.522189400]
    x = signal.lfilter(b, a, x); return x / (np.max(np.abs(x)) + 1e-9)

def make_ir(d, tau, seed, dark=5000.0, early=True):
    r = np.random.default_rng(seed); n = n_of(d)
    t = np.arange(n) / SR
    ir = r.standard_normal(n) * np.exp(-t / tau)
    ir = lp(ir, dark, 1)
    dk = lp(ir, dark * 0.25, 2); u = np.clip(t / d * 2.0, 0, 1)
    ir = ir * (1 - u) + dk * u
    if early:
        for k in range(10):
            ir[int(r.uniform(0.004, 0.08) * SR)] += r.uniform(0.3, 0.9) * (1 if r.random() < 0.5 else -1)
    return ir / np.sqrt(np.sum(ir ** 2))
def reverb(x, wet=0.3, d=2.5, tau=0.8, pre=0.02, dark=5000.0, seed=1, stereo=True):
    x = np.asarray(x, float)
    outs = []
    for s in (seed, seed + 101):
        ir = make_ir(d, tau, s, dark)
        w = signal.fftconvolve(x, ir)[: len(x) + n_of(d)]
        w = np.roll(w, n_of(pre)); w[: n_of(pre)] = 0
        outs.append(w)
    n = max(len(outs[0]), len(x))
    L = np.zeros(n); R = np.zeros(n)
    L[: len(x)] += x * (1 - wet * 0.5); R[: len(x)] += x * (1 - wet * 0.5)
    L[: len(outs[0])] += outs[0] * wet * 2.2; R[: len(outs[1])] += outs[1] * wet * 2.2
    return np.stack([L, R])

def stereo_noise(fn, *a, **k):
    return np.stack([fn(*a, **k), fn(*a, **k)])

def master(st, peak=0.9, drive=1.0, dur=None, lowcut=22.0, bass_fix=True, sub_keep=0.45, harm_gain=1.0):
    st = np.asarray(st, float)
    if st.ndim == 1: st = np.stack([st, st])
    st = np.stack([hp(c, lowcut, 2) for c in st])
    if bass_fix:
        out = []
        for c in st:
            low = lp(c, 95.0, 2); rest = c - low
            harm = bp(sat(low * 3.0, 3.5), 130.0, 1300.0, 2)
            out.append(rest + sub_keep * low + harm_gain * harm)
        st = np.stack(out)
    if drive > 1.0: st = sat(st, drive)
    st = norm(st, peak)
    if dur is not None:
        st = np.stack([pad(c, dur) for c in st])
    st = np.stack([fade(c, 0.003, 0.05) for c in st])
    return st

def write_wav(path, st):
    import wave
    st = np.clip(st, -1, 1); data = (st.T * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data.tobytes())

def sub_drop(d, f0, f1, tau, power=1.0, drive=1.5):
    ph = phase(glide(f0, f1, d, power)); return sat(sine(ph), drive) * np.exp(-T(d) / tau)
def noise_burst(d, tau, lo=None, hi=None, kind=white):
    x = kind(d) * np.exp(-T(d) / tau)
    if lo: x = hp(x, lo)
    if hi: x = lp(x, hi)
    return x
def inharm(d, base, ratios, taus, amps, vib=0.0):
    out = np.zeros(n_of(d)); t = T(d)
    for r, tau, a in zip(ratios, taus, amps):
        f = base * r * (1 + vib * np.sin(2 * np.pi * 5.1 * t))
        out += a * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / tau)
    return out
def rock_debris(d, rate0, rate1, lo=150, hi=2500, level=1.0, seed=5):
    r = np.random.default_rng(seed); out = np.zeros(n_of(d)); t = 0.0
    while t < d:
        u = t / d; rate = rate0 + (rate1 - rate0) * u
        t += r.exponential(1.0 / max(rate, 0.01))
        if t >= d: break
        ln = r.uniform(0.03, 0.16); b = noise_burst(ln, ln * 0.35, None, None)
        b = bp(b, r.uniform(lo, lo * 3), r.uniform(hi * 0.4, hi))
        b += 0.8 * sub_drop(ln, r.uniform(90, 160), 45, ln * 0.4)
        place(out, b * r.uniform(0.2, 1.0) * level, t)
    return out
