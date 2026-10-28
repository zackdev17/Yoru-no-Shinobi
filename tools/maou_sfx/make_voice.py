from voice import *

PHRASE = "The world will end"
SPEED, TEMPO = 135, 1.0
MIX = dict(clarity=0.78, giant=0.52, a_gain=1.0, b_gain=0.35, c_gain=0.2, presence=0.5)

def _end_onset(x):
    env = lp(np.abs(x), 30.0, 2); thr = env.max() * 0.12
    voiced = env > thr; idx = np.where(voiced)[0]
    last = idx[-1]; gap = 0; k = last
    while k > 0:
        if not voiced[k]:
            gap += 1
            if gap > int(0.035 * SR): return (k + gap) / SR
        else: gap = 0
        k -= 1
    return 0.72 * len(x) / SR

def build_voice(out_wav, D=5.0, start=0.20, with_dry=None):
    x = espeak(PHRASE, speed=SPEED, pitch=20); x = x / (np.max(np.abs(x)) + 1e-9)
    y = rubber(x, 1.0, TEMPO, "preserved") if TEMPO != 1.0 else x
    dry_v = norm(demon(y, **MIX), 0.85)
    dry_v = dry_v + 0.55 * bp(dry_v, 1100, 3600) + 0.15 * hp(dry_v, 4000)
    t_end = start + _end_onset(dry_v); t_world = start + 0.30 * len(dry_v) / SR
    dry = np.zeros(n_of(D)); place(dry, dry_v, start)
    whisp = np.zeros(n_of(D)); place(whisp, vocode_whisper(rubber(y, 0.8)) * 0.8, start - 0.02)
    low = np.zeros(n_of(D))
    place(low, sub_drop(1.2, 62, 26, 0.45) * 0.45, t_world)
    place(low, sub_drop(2.4, 74, 22, 0.95, drive=2.2) * 0.6, t_end - 0.02)
    place(low, noise_burst(1.4, 0.35, 120, 2500) * 0.25, t_end - 0.02)
    riser = sweep(white(0.6), 300, 6500, "bandpass", 1.8) * swell(0.6, 0.98, 2.4, 0.2)
    place(low, riser * 0.40, t_end - 0.55)
    base = reverb(dry, wet=0.30, d=3.0, tau=1.3, pre=0.04, dark=3500, seed=11)
    st = np.zeros((2, max(base.shape[1], n_of(D)))); st[:, : base.shape[1]] += base
    st[0, : len(low)] += low; st[1, : len(low)] += low
    echo = lp(dry, 2200)
    place(st[1], echo * 0.22, 0.30); place(st[0], echo * 0.13, 0.62); place(st[1], echo * 0.07, 0.95)
    wst = reverb(whisp, wet=0.7, d=3.0, tau=1.7, pre=0.05, dark=6000, seed=23)
    m = min(st.shape[1], wst.shape[1]); st[:, :m] += wst[:, :m] * 0.5
    st = master(st, 0.9, drive=1.1, dur=D, sub_keep=0.3, harm_gain=0.7)
    if with_dry is not None: write_wav(with_dry, np.stack([dry, dry]))
    write_wav(out_wav, st)
    return st, (t_world, t_end)
if __name__ == "__main__":
    s, ts = build_voice("/tmp/v/ult_maou_voice.wav", with_dry="/tmp/v/voice_dry.wav")
    print(s.shape[1] / SR, np.max(np.abs(s)), "world@%.2f end@%.2f" % ts)
