from dsp import *

def S(x): return np.asarray(x)

def choir_pad(d, freqs, f_mult=(1.0, 1.0), vowel=((700, 1100), (500, 900)), level=1.0, lp_sweep=(300, 2500), vib=0.004, seed=1):
    r = np.random.default_rng(seed); out = np.zeros(n_of(d))
    for f in freqs:
        for cents in (-9, -3, 4, 10):
            fr = glide(f * 2 ** (cents / 1200), f * f_mult[1] / f_mult[0] * 2 ** (cents / 1200), d)
            fr = vibrato(fr, r.uniform(4.6, 5.8), vib, r.uniform(0, 6))
            out += saw(phase(fr))
    out = sweep(out, lp_sweep[0], lp_sweep[1], "lowpass", order=2)
    f1 = sweep(out, vowel[0][0], vowel[1][0], "bandpass", 1.25)
    f2 = sweep(out, vowel[0][1], vowel[1][1], "bandpass", 1.25)
    return (f1 + 0.7 * f2 + 0.25 * out) * level / len(freqs) / 2.0

def heartbeat(times, d, f0=95, f1=36, tau=0.16, amps=None):
    out = np.zeros(n_of(d))
    for i, t in enumerate(times):
        a = 1.0 if amps is None else amps[i]
        place(out, sub_drop(0.45, f0, f1, tau, drive=2.0) * a, t)
        place(out, sub_drop(0.3, f0 * 1.25, f1, tau * 0.7, drive=2.0) * a * 0.5, t + 0.13)
    return out

def ult_charge_worldend():
    D = 2.9
    sub = sine(phase(glide(34, 92, D, 1.4))) * swell(D, 0.8, 2.0, 1.3)
    cluster = choir_pad(D, [55.0, 58.27, 77.78, 82.41], f_mult=(1.0, 1.52), lp_sweep=(180, 2600), level=1.0, seed=2) * swell(D, 0.82, 1.8, 1.2)
    air = sweep(pink(D), 250, 7000, "bandpass", 1.7) * swell(D, 0.85, 3.2, 1.0)
    whisp = sweep(white(D), 1500, 5200, "bandpass", 1.5) * swell(D, 0.7, 2.0, 1.5) * (0.6 + 0.4 * sine(phase(np.full(n_of(D), 7.0))))
    times = [0.10, 0.70, 1.20, 1.60, 1.92, 2.17, 2.37, 2.52]
    hb = heartbeat(times, D, amps=[0.35, 0.45, 0.55, 0.65, 0.75, 0.85, 0.95, 1.0])
    x = 0.8 * sub + 0.9 * cluster + 0.5 * air + 0.18 * whisp + 0.9 * hb
    st = reverb(sat(x, 1.3), wet=0.28, d=2.0, tau=0.9, pre=0.02, dark=4500, seed=31)
    return master(st, 0.88, dur=D)

def ult_maou_eye():
    D = 3.6
    groan = saw(phase(vibrato(glide(46, 41, D), 0.75, 0.07)))
    groan = sweep(sat(groan, 1.5), 140, 900, "lowpass") * swell(D, 0.45, 1.6, 1.0)
    trit = (sine(phase(glide(55, 55, D))) + 0.8 * sine(phase(glide(77.78, 78.4, D)))) * swell(D, 0.5, 1.4, 1.0)
    creak = sweep(white(D), 260, 1100, "bandpass", 1.12, order=3) * (0.55 + 0.45 * sine(phase(vibrato(np.full(n_of(D), 9.0), 0.5, 0.5))))
    creak *= swell(D, 0.45, 1.8, 1.5)
    boom = np.zeros(n_of(D)); place(boom, sub_drop(1.6, 74, 26, 0.55, drive=2.2), 1.55)
    place(boom, noise_burst(0.9, 0.25, None, 1400) * 0.7, 1.55)
    shim = inharm(1.5, 1180, [1, 1.51, 2.37, 3.12], [0.6, 0.5, 0.4, 0.35], [0.5, 0.4, 0.3, 0.25], vib=0.003)
    shim = (shim[::-1] * swell(1.5, 0.99, 2.2, 0.1)); sh = np.zeros(n_of(D)); place(sh, shim, 0.1)
    place(sh, inharm(2.0, 1180, [1, 1.51, 2.37, 3.12], [0.9, 0.7, 0.6, 0.5], [0.25, 0.2, 0.15, 0.12]), 1.6)
    choir = np.zeros(n_of(D)); place(choir, choir_pad(2.4, [110.0, 138.6, 164.8], lp_sweep=(500, 3000), vowel=((600, 1000), (800, 1200)), seed=4) * swell(2.4, 0.4, 1.5, 1.4), 1.2)
    x = 0.8 * groan + 0.5 * trit + 0.55 * creak + 1.0 * boom + 0.35 * sh + 0.45 * choir
    return master(reverb(x, wet=0.38, d=3.2, tau=1.5, pre=0.03, dark=4000, seed=41), 0.88, dur=D)

def ult_maou_pillar():
    D = 3.6
    whoosh = sweep(white(1.1), 7500, 350, "bandpass", 1.6) * swell(1.1, 0.35, 1.2, 1.2)
    boom = np.zeros(n_of(D)); place(boom, sub_drop(2.2, 82, 24, 0.85, drive=2.2), 0.9)
    place(boom, noise_burst(1.2, 0.3, 80, 1800) * 0.8, 0.9)
    place(boom, inharm(2.5, 160, [1, 2.76, 5.4, 8.93], [1.2, 0.7, 0.4, 0.25], [0.35, 0.25, 0.15, 0.1]), 0.9)
    col = np.zeros(n_of(D)); place(col, choir_pad(2.8, [73.4, 110.0, 146.8, 220.0], lp_sweep=(900, 1500), vowel=((750, 1150), (500, 850)), seed=6, level=1.2) * swell(2.8, 0.15, 1.0, 1.4), 0.7)
    r = np.random.default_rng(9); crack = np.zeros(n_of(D))
    for _ in range(70):
        t = r.uniform(0.2, 3.0) ** 1.0; ln = r.uniform(0.004, 0.02)
        place(crack, hp(white(ln), 3000) * np.exp(-T(ln) / (ln * 0.4)) * r.uniform(0.3, 1.0) * np.exp(-t / 1.6), t)
    x = 0.65 * np.pad(whoosh, (0, n_of(D) - len(whoosh))) + 1.0 * boom + 0.7 * col + 0.35 * crack
    return master(reverb(x, wet=0.33, d=2.8, tau=1.3, pre=0.03, dark=4500, seed=51), 0.9, dur=D)

def ult_maou_sword():
    D = 7.2; pk = 5.7 / D
    sw = swell(D, pk, 2.4, 2.2)
    sub = sine(phase(glide(28, 118, D, 1.2))) * sw
    body = sweep(sat(saw(phase(glide(55, 210, D, 1.3))), 1.4), 160, 3200, "lowpass") * sw
    wind = sweep(pink(D), 180, 1400, "bandpass", 1.8) * swell(D, pk, 2.0, 1.8)
    t = T(D); sing = np.zeros(n_of(D))
    for r_, a in zip([1, 1.504, 2.11, 2.97], [1, 0.7, 0.5, 0.35]):
        fr = glide(620 * r_, 1250 * r_, D, 1.4)
        sing += a * sine(phase(vibrato(fr, 5.5, 0.006)))
    sing *= swell(D, pk, 2.8, 2.5) * 0.35
    scrape = sweep(white(D), 700, 3800, "bandpass", 1.5) * (0.5 + 0.5 * np.abs(sine(phase(glide(6, 24, D))))) * swell(D, pk, 3.0, 2.2)
    drum = np.zeros(n_of(D))
    for tt, a in zip([0.4, 1.4, 2.3, 3.1, 3.8, 4.4, 4.9, 5.3, 5.55], [0.4, 0.5, 0.6, 0.7, 0.8, 0.85, 0.9, 0.95, 1.0]):
        place(drum, sub_drop(0.6, 70, 32, 0.2, drive=2.2) * a, tt)
        place(drum, noise_burst(0.25, 0.05, 60, 900) * a * 0.4, tt)
    choir = choir_pad(D, [55.0, 82.41, 110.0, 138.6], f_mult=(1.0, 1.35), lp_sweep=(300, 2400), seed=8, level=1.0) * swell(D, pk, 2.0, 1.8)
    x = 0.8 * sub + 0.7 * body + 0.5 * wind + 0.5 * sing + 0.4 * scrape + 0.8 * drum + 0.7 * choir
    return master(reverb(x, wet=0.25, d=3.0, tau=1.4, pre=0.03, dark=4200, seed=61), 0.9, dur=D)

def ult_maou_quake():
    D = 6.6; sw = swell(D, 0.86, 1.3, 2.0)
    def rumble(seed):
        global rng
        b = brown(D); b2 = sweep(b, 70, 190, "lowpass")
        am = 0.65 + 0.35 * lp(white(D), 9, 1) * 8
        return b2 * am * sw
    L, R = rumble(1), rumble(2)
    tremor = sine(phase(glide(26, 40, D))) * (0.7 + 0.3 * sine(phase(np.full(n_of(D), 7.0)))) * sw
    grind = sweep(pink(D), 100, 700, "bandpass", 1.7) * (0.5 + 0.5 * lp(np.abs(white(D)), 14, 1) * 4) * sw
    deb = rock_debris(D, 3, 26, 120, 2400, 1.0, seed=71)
    deb2 = rock_debris(D, 2, 18, 90, 1800, 0.9, seed=72)
    thumps = np.zeros(n_of(D)); r = np.random.default_rng(3)
    for k in range(16):
        t = 0.4 + k * 0.36 + r.uniform(-0.05, 0.05); place(thumps, sub_drop(0.55, 85, 24, 0.17, drive=2.0) * (0.35 + 0.04 * k), t)
    mono = 0.7 * tremor + 0.55 * grind + 0.9 * thumps
    st = np.stack([mono + 1.1 * L + 0.5 * deb, mono + 1.1 * R + 0.5 * deb2])
    st = np.stack([sat(c, 1.4) for c in st])
    return master(st, 0.9, dur=D)

def ult_maou_impact():
    D = 5.0
    crack = noise_burst(0.2, 0.025, 800, None) * 1.0
    boom = sub_drop(3.0, 92, 20, 1.05, drive=2.6)
    body = noise_burst(2.0, 0.45, 40, 420, kind=brown) * 2.0
    clang = inharm(3.2, 150, [1, 2.76, 5.4, 8.93, 13.3], [1.6, 1.1, 0.7, 0.4, 0.25], [0.45, 0.35, 0.22, 0.14, 0.09], vib=0.002)
    blast = sweep(white(1.0), 3500, 160, "bandpass", 1.7) * swell(1.0, 0.04, 1.0, 1.4)
    deb = rock_debris(3.2, 22, 2, 100, 2200, 1.1, seed=81)
    x = np.zeros(n_of(D))
    place(x, crack, 0.0); place(x, boom, 0.0); place(x, body, 0.0); place(x, clang * 0.9, 0.0)
    place(x, blast * 0.85, 0.02); place(x, deb * 0.8, 0.12)
    place(x, sub_drop(2.0, 48, 20, 0.9, drive=2.0) * 0.6, 0.35)
    return master(reverb(sat(x, 1.5), wet=0.36, d=3.6, tau=1.7, pre=0.025, dark=3800, seed=91), 0.96, dur=D)

def ult_maou_crack():
    D = 2.8; r = np.random.default_rng(12); x = np.zeros(n_of(D))
    t = 0.0; k = 0
    while t < 1.9:
        ln = r.uniform(0.03, 0.09); a = 0.5 + 0.5 * min(1, t / 1.2)
        c = hp(white(ln), r.uniform(900, 2500)) * np.exp(-T(ln) / (ln * 0.3))
        c += 0.8 * sub_drop(ln, r.uniform(180, 300), 70, ln * 0.7, drive=1.6)
        place(x, c * a * r.uniform(0.6, 1.0), t); t += r.exponential(0.16 - 0.1 * min(1, t / 1.9))
    grind = sweep(pink(D), 160, 900, "bandpass", 1.6) * swell(D, 0.35, 1.2, 1.4) * (0.5 + 0.5 * lp(np.abs(white(D)), 18, 1) * 4)
    rumble = sweep(brown(D), 70, 150, "lowpass") * swell(D, 0.3, 1.0, 1.4)
    sizz = hp(white(D), 5500) * swell(D, 0.55, 2.2, 1.6) * (0.4 + 0.6 * np.abs(sine(phase(glide(10, 45, D)))))
    boom = np.zeros(n_of(D)); place(boom, sub_drop(1.2, 60, 24, 0.45, drive=2.0), 1.7)
    place(boom, noise_burst(0.5, 0.12, 80, 1400), 1.7)
    mix = 0.95 * x + 0.6 * grind + 0.9 * rumble + 0.16 * sizz + 0.9 * boom
    return master(reverb(mix, wet=0.28, d=2.4, tau=1.1, pre=0.02, dark=4200, seed=101), 0.9, dur=D)

def ult_maou_shatter():
    D = 4.2; r = np.random.default_rng(14)
    boom = sub_drop(3.4, 80, 18, 1.0, drive=2.6)
    expl = sweep(white(2.0), 9000, 260, "lowpass") * np.exp(-T(2.0) / 0.55)
    sh = np.zeros(n_of(D))
    for _ in range(420):
        t = r.exponential(0.55); 
        if t > 3.4: continue
        f = r.uniform(1400, 9500); ln = r.uniform(0.04, 0.45)
        ping = sine(phase(np.full(n_of(ln), f))) * np.exp(-T(ln) / (ln * 0.3))
        ping += 0.5 * sine(phase(np.full(n_of(ln), f * r.uniform(2.1, 3.4)))) * np.exp(-T(ln) / (ln * 0.18))
        place(sh, ping * r.uniform(0.05, 0.4) * np.exp(-t / 1.4), t)
    glass = hp(white(D), 4500) * np.exp(-T(D) / 0.5) * (0.5 + 0.5 * np.abs(sine(phase(glide(30, 80, D)))))
    crunch = rock_debris(3.6, 40, 4, 120, 3000, 1.2, seed=15)
    x = np.zeros(n_of(D))
    place(x, boom, 0); place(x, expl * 0.9, 0); place(x, sh * 0.8, 0.0); place(x, glass * 0.5, 0)
    place(x, crunch * 0.8, 0.05); place(x, noise_burst(0.25, 0.03, 700, None), 0.0)
    place(x, inharm(3.0, 118, [1, 2.76, 5.4], [1.6, 0.9, 0.5], [0.3, 0.2, 0.12]), 0.0)
    return master(reverb(sat(x, 1.4), wet=0.40, d=3.6, tau=1.7, pre=0.025, dark=7000, seed=111), 0.96, dur=D)

def ult_maou_suck():
    D = 2.8; E = 2.35
    whoosh = sweep(white(E), 120, 7000, "bandpass", 1.7, order=3) * swell(E, 0.97, 2.2, 0.2)
    wind2 = sweep(pink(E), 80, 3000, "bandpass", 2.0) * swell(E, 0.95, 1.8, 0.3)
    vort = sine(phase(vibrato(glide(90, 1500, E, 1.5), 6.0, 0.02))) * swell(E, 0.96, 2.2, 0.2)
    vort2 = saw(phase(glide(45, 400, E, 1.3))); vort2 = sweep(vort2, 150, 1800, "lowpass") * swell(E, 0.95, 2.0, 0.3)
    x = np.zeros(n_of(D))
    place(x, 0.9 * whoosh + 0.7 * wind2 + 0.25 * vort + 0.45 * vort2, 0.0)
    place(x, sub_drop(0.6, 90, 30, 0.2, drive=2.0) * 0.9, E - 0.02)
    place(x, noise_burst(0.12, 0.02, 200, 3000), E - 0.02)
    return master(reverb(x, wet=0.18, d=1.2, tau=0.5, pre=0.01, dark=5000, seed=121), 0.88, dur=D)

def ult_maou_end():
    D = 5.6
    bell = inharm(5.6, 82.41, [1, 2.0, 2.76, 4.07, 5.43, 6.8], [3.2, 2.4, 1.8, 1.1, 0.7, 0.5], [0.8, 0.5, 0.35, 0.25, 0.15, 0.1], vib=0.0015)
    toll = np.zeros(n_of(D)); place(toll, bell, 0.0); place(toll, bell * 0.35, 2.3)
    boom = np.zeros(n_of(D)); place(boom, sub_drop(3.2, 58, 20, 1.2, drive=2.0) * 0.9, 0.0)
    place(boom, noise_burst(0.8, 0.18, 50, 800), 0.0)
    pad_ = np.zeros(n_of(D)); place(pad_, choir_pad(5.0, [41.2, 61.7, 82.41, 98.0], lp_sweep=(1500, 220), vowel=((600, 1000), (450, 800)), seed=21, level=1.1) * swell(5.0, 0.1, 1.0, 1.1), 0.1)
    wind = sweep(pink(D), 900, 180, "bandpass", 1.8) * swell(D, 0.2, 1.0, 1.4) * 0.4
    x = 0.85 * toll + 1.0 * boom + 0.7 * pad_ + 0.35 * wind
    return master(reverb(x, wet=0.4, d=4.0, tau=2.0, pre=0.03, dark=3000, seed=131), 0.9, dur=D)

def skill_dash_eclipse():
    D = 1.1
    sw = sweep(white(0.45), 6500, 700, "bandpass", 1.6) * swell(0.45, 0.25, 1.1, 1.4)
    shing = inharm(0.8, 2300, [1, 1.62, 2.4], [0.28, 0.2, 0.15], [0.35, 0.22, 0.14]) 
    thud = sub_drop(0.55, 130, 38, 0.18, drive=2.2)
    dark = sweep(brown(D), 400, 90, "lowpass") * np.exp(-T(D) / 0.3) * 0.8
    x = np.zeros(n_of(D)); place(x, sw * 0.9, 0.0); place(x, shing, 0.04); place(x, thud * 0.95, 0.0); place(x, dark, 0.0)
    place(x, noise_burst(0.06, 0.012, 1500, None) * 0.7, 0.0)
    return master(reverb(sat(x, 1.3), wet=0.25, d=1.4, tau=0.55, pre=0.01, dark=5000, seed=141), 0.9, dur=D)

def skill_special_judgement():
    D = 1.9; C = 1.15
    rise = sweep(white(C), 250, 6500, "bandpass", 1.7) * swell(C, 0.97, 2.6, 0.2)
    subr = sine(phase(glide(42, 125, C, 1.2))) * swell(C, 0.97, 2.0, 0.2)
    choir = choir_pad(C, [110.0, 130.8, 185.0], lp_sweep=(500, 2800), vowel=((600, 1000), (800, 1250)), seed=24) * swell(C, 0.95, 2.0, 0.3)
    x = np.zeros(n_of(D))
    place(x, 0.7 * rise + 0.8 * subr + 0.7 * choir, 0.0)
    place(x, sub_drop(0.9, 88, 27, 0.35, drive=2.4) * 0.95, C - 0.02)
    place(x, noise_burst(0.5, 0.08, 120, 3500) * 0.8, C - 0.02)
    place(x, inharm(1.2, 330, [1, 2.76, 5.4], [0.5, 0.3, 0.2], [0.3, 0.2, 0.1]), C - 0.02)
    return master(reverb(x, wet=0.3, d=2.0, tau=0.9, pre=0.02, dark=4500, seed=151), 0.9, dur=D)

def skill_impact_judgement():
    D = 2.4
    crack = hp(white(0.1), 1200) * np.exp(-T(0.1) / 0.015)
    boom = sub_drop(1.6, 110, 24, 0.5, drive=2.4)
    body = noise_burst(1.0, 0.18, 60, 700, kind=brown) * 1.6
    ring = inharm(1.6, 210, [1, 2.76, 5.4, 8.93], [0.7, 0.4, 0.25, 0.15], [0.4, 0.3, 0.18, 0.1])
    x = np.zeros(n_of(D)); place(x, crack * 1.1, 0); place(x, boom, 0); place(x, body, 0); place(x, ring * 0.9, 0)
    place(x, sweep(white(0.5), 3500, 250, "bandpass", 1.6) * swell(0.5, 0.05, 1.0, 1.3) * 0.7, 0.01)
    return master(reverb(sat(x, 1.5), wet=0.3, d=2.2, tau=0.9, pre=0.02, dark=4200, seed=161), 0.95, dur=D)

SOUNDS = {
    "ult_charge_worldend": ult_charge_worldend, "ult_maou_eye": ult_maou_eye, "ult_maou_pillar": ult_maou_pillar,
    "ult_maou_sword": ult_maou_sword, "ult_maou_quake": ult_maou_quake, "ult_maou_impact": ult_maou_impact,
    "ult_maou_crack": ult_maou_crack, "ult_maou_shatter": ult_maou_shatter, "ult_maou_suck": ult_maou_suck,
    "ult_maou_end": ult_maou_end, "skill_dash_eclipse": skill_dash_eclipse,
    "skill_special_judgement": skill_special_judgement, "skill_impact_judgement": skill_impact_judgement,
}
