import os, subprocess, tempfile
from dsp import write_wav
from sfx_maou import SOUNDS
import make_voice

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio", "sfx")
tmp = tempfile.mkdtemp()
jobs = dict(SOUNDS); jobs["ult_maou_voice"] = lambda: make_voice.build_voice(os.path.join(tmp, "ult_maou_voice.wav"))[0]
for name, fn in jobs.items():
    wav = os.path.join(tmp, name + ".wav")
    if name != "ult_maou_voice": write_wav(wav, fn())
    else: fn()
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-ar", "44100", "-ac", "2", "-c:a", "libmp3lame", "-b:a", "160k",
                    os.path.join(OUT, name + ".mp3")], check=True)
    print("ok", name)
