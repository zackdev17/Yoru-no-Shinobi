import os, subprocess, tempfile, sys, time
from dsp import write_wav
from sfx_maou_long import SOUNDS_LONG

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "assets", "audio", "sfx")
tmp = tempfile.mkdtemp()
only = sys.argv[1:]
for name, fn in SOUNDS_LONG.items():
    if only and name not in only: continue
    t0 = time.time()
    wav = os.path.join(tmp, name + ".wav")
    write_wav(wav, fn())
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-ar", "44100", "-ac", "2", "-c:a", "libmp3lame", "-b:a", "160k",
                    os.path.join(OUT, name + ".mp3")], check=True)
    print("ok", name, round(time.time() - t0, 1), "s")
