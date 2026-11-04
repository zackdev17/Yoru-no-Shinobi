"""Memecah backsound WORLD END menjadi file MP3 per-efek + bed musik, dan membuat daftar cue otomatis.

Hasil:
  assets/audio/sfx/ult_maou_<efek>.mp3      satu file per jenis efek (detak jantung, taiko, bell, riser, dll.)
  assets/audio/sfx/ult_maou_bgm_long.mp3    bed musik saja (paduan suara, senar, drone, desis udara)
  scripts/entities/maou_cues.gd             jadwal pemutaran tiap efek (waktu, file, volume dB, pitch)
  tools/maou_sfx/SFX_LIST.md                daftar lengkap agar tiap suara mudah diganti
Jalankan:  python3 build_maou_events.py
Mengganti suara: timpa file MP3 dengan nama yang sama (volume diatur di maou_cues.gd).
"""
import os, math, subprocess, tempfile
import numpy as np
from dsp import *
import bgm_worldend_long as B

HERE = os.path.dirname(os.path.abspath(__file__))
SFX = os.path.join(HERE, "..", "..", "assets", "audio", "sfx")
CUES_GD = os.path.join(HERE, "..", "..", "scripts", "entities", "maou_cues.gd")
TMP = tempfile.mkdtemp()
D = B.D
IGNITE, BURST, EYE0, PRISM, HALO, PILLAR, ASCEND, SKY, SWORD, FALL, CONTACT, IMPACT, SHATTER, TEXT = (
    B.IGNITE, B.BURST, B.EYE0, B.PRISM, B.HALO, B.PILLAR, B.ASCEND, B.SKY, B.SWORD, B.FALL, B.CONTACT, B.IMPACT, B.SHATTER, B.TEXT)
CLIPS = {}   # nama -> (2,n) float, dipakai untuk simulasi mix


def st(x):
    x = np.asarray(x, float)
    return np.stack([x, x]) if x.ndim == 1 else x


def save(name, x, dur=None, peak=0.9):
    y = master(st(x), peak=peak, drive=1.0, dur=dur)
    CLIPS[name] = y
    wav = os.path.join(TMP, name + ".wav")
    write_wav(wav, y)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-ar", "44100", "-ac", "2", "-c:a", "libmp3lame", "-b:a", "160k",
                    os.path.join(SFX, name + ".mp3")], check=True)


def riser_clip(d, f0=160, f1=7500, tone=True):
    x = sweep(white(d), f0, f1, "bandpass", 1.7)
    o = norm(x, 1.0) * 0.8
    if tone:
        g = glide(110, 1000, d, 2.0)
        s = lp(saw(phase(g)) + saw(phase(g * 1.007)), 2800, 2)
        o = o + norm(s, 1.0) * 0.5
    return o * (np.linspace(0, 1, n_of(d)) ** 2.2)


def rv(x, wet=0.35, d=4.5, tau=2.0, seed=301):
    return reverb(x, wet=wet, d=d, tau=tau, pre=0.02, dark=5000, seed=seed)


def render_events():
    x = np.zeros(n_of(1.2)); place(x, B.hit(1.0, 1.1), 0.0); place(x, B.hit(0.5, 0.9), 0.16)
    save("ult_maou_heartbeat", x, dur=1.2)
    save("ult_maou_taiko_s", B.taiko(1.0, 0.6))
    save("ult_maou_taiko", B.taiko(1.0, 1.0))
    save("ult_maou_taiko_l", B.taiko(1.0, 1.6))
    save("ult_maou_riser_ignite", riser_clip(2.4))
    save("ult_maou_riser_burst", riser_clip(3.0))
    save("ult_maou_riser_ascend", riser_clip(2.4))
    save("ult_maou_riser_sword", riser_clip(FALL - SWORD, 300, 6000, False))
    save("ult_maou_riser_fall", riser_clip(IMPACT - 0.5 - FALL))
    save("ult_maou_bell", rv(B.bell(146.8, 12.0)), dur=16.0)
    save("ult_maou_chime", rv(inharm(5.5, 587.33, [1, 2.76, 5.4], [4.0, 2.2, 1.0], [0.5, 0.2, 0.1]), 0.4, 4.0, 1.8, 311), dur=8.0)
    dn = lp(brown(5.0), 240, 2); dn = norm(dn, 1.0) * np.exp(-T(5.0) / (5.0 * 0.35))
    save("ult_maou_downer", dn)
    r = np.random.default_rng(21); cr = np.zeros(n_of(7.0))
    t = 0.0
    while t < 6.8:
        ln = r.uniform(0.015, 0.05)
        z = hp(white(ln), r.uniform(2500, 6500)) * np.exp(-T(ln) / (ln * 0.4))
        z += 0.4 * sine(phase(glide(r.uniform(3000, 6000), r.uniform(300, 900), ln, 1.5))) * np.exp(-T(ln) / (ln * 0.5))
        place(cr, z * r.uniform(0.3, 0.8), t)
        t += r.exponential(1.0 / 8.0)
    save("ult_maou_crackle", rv(cr, 0.25, 2.0, 0.9, 321))
    r = np.random.default_rng(77); gl = np.zeros(n_of(3.3)); d = 2.6; tt = T(d)
    for i in range(14):
        f = r.uniform(1800, 6500)
        trem = 0.5 + 0.5 * np.sin(2 * np.pi * r.uniform(7, 18) * tt + r.uniform(0, 6.28))
        place(gl, sine(phase(np.full(n_of(d), f))) * trem * np.exp(-tt / r.uniform(0.5, 1.4)), r.uniform(0, 0.5))
    save("ult_maou_glass", rv(gl, 0.3, 3.0, 1.2, 331))
    ro = np.zeros(n_of(4.7))
    b = norm(sweep(brown(4.6), 420, 110, "lowpass"), 1.0) * np.exp(-T(4.6) / 3.2)
    place(ro, b * 0.9, 0.0)
    place(ro, rock_debris(SHATTER - IMPACT, 14, 3, 120, 2200, 0.5, seed=11), 0.1)
    sc = hp(sweep(white(1.8), 7000, 500, "bandpass", 1.5), 300, 2) * np.exp(-T(1.8) / 0.9)
    place(ro, norm(sc, 1.0) * 0.55, SHATTER - IMPACT - 0.1)
    save("ult_maou_roar", ro)
    d1 = SWORD - SKY
    save("ult_maou_wind_sky", sweep(pink(d1), 300, 1400, "bandpass", 1.8) * (0.5 + 0.5 * np.sin(2 * np.pi * 0.3 * T(d1))) * swell(d1, 0.5, 1.6, 1.5))
    d2 = D - 68.0
    save("ult_maou_wind_end", sweep(pink(d2), 260, 900, "bandpass", 1.8) * swell(d2, 0.3, 1.5, 1.2))


def db(a):
    return 20 * math.log10(max(a, 1e-4))


def make_cues():
    c = []
    add = lambda t, f, a=1.0, p=1.0: c.append([round(t, 3), f, db(a), round(p, 4)])
    n = len(B.BEATS)
    for i, t in enumerate(B.BEATS):
        add(t, "ult_maou_heartbeat", 0.14 + 0.86 * (i / (n - 1)) ** 1.2)
    for k, tt in enumerate([68.7, 69.7, 70.5, 71.0]):
        add(tt, "ult_maou_heartbeat", 0.34 - 0.07 * k)
    for i in range(16):
        add(PRISM + 0.15 + 0.21 * i, "ult_maou_taiko_s", 0.35 + 0.012 * i)
    t = HALO + 0.4; k = 0
    while t < ASCEND - 0.8:
        add(t, "ult_maou_taiko", 0.55 if k % 4 else 0.9)
        if k % 2 == 1:
            add(t + 0.375, "ult_maou_taiko_s", 0.3)
        t += 0.75; k += 1
    t = FALL + 0.2; iv = 0.5
    while t < IMPACT - 0.55:
        add(t, "ult_maou_taiko_s", 0.3 + 0.7 * (t - FALL) / (IMPACT - FALL))
        t += iv; iv = max(0.085, iv * 0.93)
    for tt, a in [(BURST, 1.0), (EYE0, 0.6), (PILLAR, 0.9), (CONTACT, 1.0), (ASCEND, 0.9), (SWORD, 0.7)]:
        add(tt, "ult_maou_taiko_l", a)
    add(IGNITE - 2.4, "ult_maou_riser_ignite", 0.5)
    add(BURST - 3.0, "ult_maou_riser_burst", 0.8)
    add(ASCEND - 2.4, "ult_maou_riser_ascend", 0.9)
    add(SWORD, "ult_maou_riser_sword", 0.55)
    add(FALL, "ult_maou_riser_fall", 1.1)
    for tt, base, a in [(IGNITE, 146.8, 0.5), (BURST, 110.0, 0.8), (EYE0, 73.4, 0.55), (PILLAR, 146.8, 0.65), (ASCEND, 220.0, 0.7), (SWORD, 146.8, 0.9),
                        (CONTACT, 98.0, 0.9), (IMPACT, 73.4, 1.0), (TEXT + 0.1, 82.4, 1.0), (70.4, 73.4, 0.5)]:
        add(tt, "ult_maou_bell", a, base / 146.8)
        add(tt, "ult_maou_bell", a * 0.35, 2.0 * base / 146.8)
    notes = [587.33, 698.46, 880.0, 1046.5, 880.0, 698.46]
    t = SKY; k = 0
    while t < SWORD - 0.5:
        add(t, "ult_maou_chime", 0.5, notes[k % 6] / 587.33)
        t += 0.9; k += 1
    for tt, lv in [(BURST, 1.0), (PILLAR, 0.7), (ASCEND, 0.7), (SWORD, 0.7), (CONTACT, 1.0), (IMPACT, 1.2)]:
        add(tt, "ult_maou_downer", lv * 0.7)
    for off, a in [(0.4, 0.4), (6.7, 0.6), (13.0, 0.9)]:
        add(SWORD + off, "ult_maou_crackle", a)
    add(SHATTER, "ult_maou_glass", 0.5)
    add(IMPACT + 0.1, "ult_maou_roar", 0.9 * 2.0)
    add(SKY, "ult_maou_wind_sky", 0.63)
    add(68.0, "ult_maou_wind_end", 0.7)
    c.sort(key=lambda r: r[0])
    return c


def windows_power(x, hop=1.5, win=3.0):
    m = x.mean(axis=0) if x.ndim == 2 else x
    ts = np.arange(0, D - win + 1e-6, hop)
    return ts, np.array([np.mean(m[int(t * SR):int((t + win) * SR)] ** 2) + 1e-12 for t in ts])


def render_bed():
    pad_layers = B.choir_layer() * 1.3 + B.strings_layer() * 1.1
    dry = B.drone() * 1.5 + B.shimmer_bed() * 5.5
    wet = reverb(pad_layers, wet=0.55, d=3.2, tau=1.3, dark=4200, seed=21)
    wet = np.stack([pad(c, D) for c in wet])
    s = wet + np.stack([dry, dry])
    B.TARGET = [(t, v - 4.0) for t, v in B.TARGET]
    s = B.agc(s)
    duck = B.env([(0, 1), (IMPACT - 0.5, 1), (IMPACT - 0.44, 0.25), (IMPACT + 0.06, 0.25), (IMPACT + 0.22, 1), (D, 1)])
    s = master(s * duck, peak=0.9, drive=1.0, dur=D)
    s = norm(np.tanh(s * 1.15) / np.tanh(1.15), 0.9)
    s *= np.minimum(1.0, np.linspace(0, 1, s.shape[1]) * D / 1.2)
    s *= np.minimum(1.0, np.linspace(1, 0, s.shape[1]) * D / 0.8)
    return s


def tune_and_write(cues, bed):
    ev = np.zeros(n_of(D) + n_of(30))
    for t, f, vdb, p in cues:
        clip = CLIPS[f].mean(axis=0)
        if abs(p - 1.0) > 1e-3:
            idx = np.arange(0, len(clip) - 1, p)
            clip = np.interp(idx, np.arange(len(clip)), clip)
        g = 10 ** (vdb / 20)
        a = int(t * SR)
        m = min(len(clip), len(ev) - a)
        ev[a:a + m] += clip[:m] * g
    ev = ev[:n_of(D)]
    ts, pe = windows_power(ev); _, pb = windows_power(bed)
    tgt = np.interp(ts + 1.5, [p[0] for p in B.TARGET0], [p[1] - 3.0 for p in B.TARGET0])
    best = None
    for ge in range(-24, 8, 1):
        for gb in range(-18, 8, 1):
            tot = 10 * np.log10(pe * 10 ** (ge / 10) + pb * 10 ** (gb / 10))
            err = np.mean((tot[1:-1] - tgt[1:-1]) ** 2)
            if best is None or err < best[0]:
                best = (err, ge, gb)
    _, ge, gb = best
    print("tuning: event trim", ge, "dB, bed gain", gb, "dB, rms err", round(math.sqrt(best[0]), 1), "dB")
    scale = 10 ** (gb / 20)
    pk = float(np.abs(bed).max()) * scale
    if pk > 0.95:
        scale *= 0.95 / pk
    bed2 = bed * scale
    wav = os.path.join(TMP, "bed.wav"); write_wav(wav, bed2)
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-ar", "44100", "-ac", "2", "-c:a", "libmp3lame", "-b:a", "160k",
                    os.path.join(SFX, "ult_maou_bgm_long.mp3")], check=True)
    out = [[t, f, round(v + ge, 1), p] for t, f, v, p in cues]
    lines = ["class_name MaouCues", "# DIHASILKAN oleh tools/maou_sfx/build_maou_events.py. Format: [waktu_dtk, file, volume_dB, pitch]",
             "# Tiap suara adalah file MP3 sendiri di assets/audio/sfx/. Ganti file atau ubah volume/pitch di sini.", "const CUES := ["]
    for t, f, v, p in out:
        lines.append("\t[%s, \"%s\", %s, %s]," % (t, f, v, p))
    lines.append("]")
    open(CUES_GD, "w").write("\n".join(lines) + "\n")
    return out


def write_list(out):
    files = {}
    for t, f, v, p in out:
        files.setdefault(f, []).append(t)
    L = ["# Daftar SFX WORLD END (Maou)", "", "Semua suara adalah **file MP3 terpisah** di `assets/audio/sfx/`. Jadwal pemutaran ada di `scripts/entities/maou_cues.gd`",
         "(efek berulang/berpola) dan `Skills._worldend` di `scripts/entities/skills.gd` (efek tunggal). Untuk mengganti suara, timpa file dengan nama yang sama.", "",
         "## Efek tunggal (dipicu langsung oleh Skills._worldend)", "", "| File | Dipicu | Fungsi |", "|---|---|---|",
         "| ult_maou_voice | 2,4 dtk | suara \"The world will end\" |", "| ult_charge_worldend | 4,55 dtk | riser pengisian menuju Ignite |",
         "| ult_maou_ignite | 6,65 dtk | aura api emas menyala |", "| ult_maou_shock | 18,7 dtk | gelombang kejut |", "| ult_maou_eye | 21,0 dtk | mata terbuka |",
         "| ult_maou_prism | 27,4 dtk | 16 tebasan warna-warni |", "| ult_maou_halo | 31,2 dtk | cincin pita emas |", "| ult_maou_pillar | 33,0 dtk | pilar cahaya di karakter |",
         "| ult_maou_suck | 40,7 dtk | tarikan sebelum layar putih |", "| ult_maou_citypillar | 47,2 dtk | pilar cahaya emas di kota |", "| ult_maou_thunder | 50,6 dtk | petir biru |",
         "| ult_maou_summon | 48,2 dtk | pedang muncul (puncak di 51,6) |", "| ult_maou_windpulse | 52,45 dtk dst (tiap 2,2 dtk) | denyut kabut dan percikan listrik |",
         "| ult_maou_fall | 58,0 dtk | pedang jatuh, kontak di 62,0 |", "| ult_maou_hit | 43,0 dan 51,6 dtk | dentuman gong |",
         "| ult_maou_impact / quake / crack / shatter / end | 66,0 - 69,1 dtk | benturan, retakan, dunia pecah, teks |", "", "## Efek berpola (jadwal di maou_cues.gd)", "",
         "| File | Jumlah pemicu | Pemicu pertama | Fungsi |", "|---|---|---|---|"]
    desc = {"heartbeat": "detak jantung (volume naik)", "taiko_s": "taiko pendek (tebasan prisma, ritme jatuh)", "taiko": "taiko sedang (ritme halo)",
            "taiko_l": "taiko besar (momen utama)", "riser_ignite": "riser menuju Ignite", "riser_burst": "riser menuju Burst", "riser_ascend": "riser menuju layar putih",
            "riser_sword": "riser saat pedang menggantung", "riser_fall": "riser pedang jatuh", "bell": "bell panjang (pitch diubah per momen)",
            "chime": "denting dingin di langit malam", "downer": "ekor rumble rendah setelah hantaman", "crackle": "percikan listrik", "glass": "pecahan kaca",
            "roar": "gemuruh benturan + puing", "wind_sky": "angin langit malam", "wind_end": "angin setelah dunia pecah"}
    for f in sorted(files):
        k = f.replace("ult_maou_", "")
        L.append("| %s | %d | %.1f dtk | %s |" % (f, len(files[f]), min(files[f]), desc.get(k, "")))
    L += ["", "## Musik latar", "", "`ult_maou_bgm_long.mp3` (71,7 dtk) hanya berisi bed musik: paduan suara, senar, drone, dan desis udara. Diputar saat ultimate dimulai.", ""]
    open(os.path.join(HERE, "SFX_LIST.md"), "w").write("\n".join(L))


if __name__ == "__main__":
    B.TARGET0 = list(B.TARGET)
    render_events()
    cues = make_cues()
    bed = render_bed()
    out = tune_and_write(cues, bed)
    write_list(out)
    print("ok", len(out), "cue,", len(CLIPS), "file efek")
