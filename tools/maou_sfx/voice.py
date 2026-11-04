import subprocess, os, wave, tempfile
import numpy as np
from scipy import signal
from dsp import *

TMP = tempfile.mkdtemp()

def _read(path):
    with wave.open(path) as w:
        sr = w.getframerate(); x = np.frombuffer(w.readframes(w.getnframes()), "<i2").astype(float) / 32768
    return signal.resample_poly(x, SR, sr) if sr != SR else x

def espeak(text, speed=68, pitch=4, voice="en-us+m3", gap=10, amp=200):
    p = os.path.join(TMP, "e.wav")
    subprocess.run(["espeak-ng", "-v", voice, "-s", str(speed), "-p", str(pitch), "-g", str(gap), "-a", str(amp), "-w", p, text], check=True)
    x = _read(p)
    idx = np.where(np.abs(x) > 0.01)[0]
    return x[idx[0]: idx[-1] + 1] if len(idx) else x

def rubber(x, pitch=1.0, tempo=1.0, formant="shifted"):
    a, b = os.path.join(TMP, "a.wav"), os.path.join(TMP, "b.wav")
    write_wav(a, np.stack([x, x]))
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", a, "-af",
                    f"rubberband=pitch={pitch}:tempo={tempo}:formant={formant}:transients=smooth", "-ac", "1", b], check=True)
    return _read(b)

def vocode_whisper(x, seed=3, bands=16, lo=120, hi=7000):
    edges = np.geomspace(lo, hi, bands + 1); out = np.zeros_like(x)
    r = np.random.default_rng(seed); noise = r.standard_normal(len(x))
    for i in range(bands):
        s = bp(x, edges[i], edges[i + 1], 2)
        env = lp(np.abs(s), 45.0, 2)
        out += bp(noise, edges[i], edges[i + 1], 2) * env
    return out / (np.max(np.abs(out)) + 1e-9)

def demon(x, clarity=0.78, giant=0.52, a_gain=1.0, b_gain=0.55, c_gain=0.35, presence=0.5):
    A = rubber(x, clarity, 1.0, "preserved")
    B = rubber(x, giant, 1.0, "shifted")
    C = rubber(x, clarity * 1.5, 1.0, "preserved")
    n = max(len(A), len(B), len(C))
    A, B, C = pad(A, n / SR), pad(B, n / SR), pad(C, n / SR)
    A = sat(A * 1.6, 1.6) * a_gain
    A = A + 0.45 * lp(A, 250) + presence * bp(A, 1300, 3800)
    B = sat(lp(B, 1100) * 2.6, 2.2) * b_gain
    C = hp(sat(C * 1.4, 1.4), 300) * c_gain
    return A + B + C
