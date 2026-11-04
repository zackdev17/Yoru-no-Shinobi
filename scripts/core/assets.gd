class_name Assets
extends RefCounted

const SFX_RATE := 22050
const MUS_RATE := 16000

static var _sfx: Dictionary = {}
static var _music: AudioStreamWAV = null
static var _drums: AudioStreamWAV = null
static var music_progress := 0.0
static var _mutex := Mutex.new()


static func _wav(samples: PackedFloat32Array, rate: int, loop := false) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = bytes
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w


static func _osc(wave: int, ph: float) -> float:
	var p := fposmod(ph, 1.0)
	match wave:
		0: return sin(p * TAU)
		1: return 1.0 if p < 0.5 else -1.0
		2: return p * 2.0 - 1.0
		3: return absf(p * 4.0 - 2.0) - 1.0
	return randf() * 2.0 - 1.0


static func _tone(dur: float, f0: float, f1: float, wave: int = 0, vol: float = 0.5,
		decay: float = 1.5, noise: float = 0.0, lp: float = 1.0, rate: int = SFX_RATE) -> PackedFloat32Array:
	var n := int(dur * rate)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	var lpv := 0.0
	for i in n:
		var t := float(i) / n
		var f := lerpf(f0, f1, t)
		ph += f / rate
		var s := _osc(wave, ph) * (1.0 - noise) + (randf() * 2.0 - 1.0) * noise
		var env := pow(1.0 - t, decay) * minf(1.0, float(i) / 120.0)
		lpv += (s - lpv) * lp
		out[i] = lpv * env * vol
	return out


static func _mix_into(dst: PackedFloat32Array, src: PackedFloat32Array, at: int, gain: float = 1.0) -> void:
	for i in src.size():
		var j := at + i
		if j >= dst.size():
			break
		dst[j] += src[i] * gain


static func _arp(notes: Array, step: float, wave: int, vol: float, decay: float = 1.2) -> PackedFloat32Array:
	var total := int((notes.size() * step + 0.25) * SFX_RATE)
	var out := PackedFloat32Array()
	out.resize(total)
	for k in notes.size():
		var f: float = notes[k]
		_mix_into(out, _tone(0.22, f, f, wave, vol, decay), int(k * step * SFX_RATE))
	return out


static func _swell(dur: float, f0: float, f1: float, wave: int = 0, vol: float = 0.5, peak: float = 0.6,
		noise: float = 0.0, lp: float = 1.0, rate: int = SFX_RATE) -> PackedFloat32Array:
	var n := int(dur * rate)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	var lpv := 0.0
	for i in n:
		var t := float(i) / n
		ph += lerpf(f0, f1, t) / rate
		var s := _osc(wave, ph) * (1.0 - noise) + (randf() * 2.0 - 1.0) * noise
		var env := pow(t / peak, 1.6) if t < peak else pow(1.0 - (t - peak) / (1.0 - peak), 1.4)
		lpv += (s - lpv) * lp
		out[i] = lpv * env * vol
	return out


static func _glass(dur: float, count: int, vol: float, rate: int = SFX_RATE) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(dur * rate))
	for k in count:
		var at := int(randf() * dur * 0.92 * rate)
		var f := randf_range(1800.0, 5200.0)
		_mix_into(out, _tone(randf_range(0.03, 0.11), f, f * 0.35, 2, vol * randf_range(0.4, 1.0), 2.2, 0.35, 0.85, rate), at)
	return out


static func sfx(name: String) -> AudioStream:
	if name.ends_with("_maou"):
		name = name.trim_suffix("_maou") + "_kakuou"
	_mutex.lock()
	if _sfx.has(name):
		var cached: AudioStream = _sfx[name]
		_mutex.unlock()
		return cached
	_mutex.unlock()
	var path := "res://assets/audio/sfx/%s.mp3" % name
	if not ResourceLoader.exists(path):
		if FileAccess.file_exists(path):
			var direct := AudioStreamMP3.load_from_file(path)
			if direct != null:
				_mutex.lock()
				_sfx[name] = direct
				_mutex.unlock()
				return direct
		push_warning("SFX tidak ditemukan: " + path)
		return null
	var loaded: Resource = load(path)
	if not (loaded is AudioStream):
		push_warning("SFX gagal dimuat: " + path)
		return null
	_mutex.lock()
	_sfx[name] = loaded
	_mutex.unlock()
	return loaded as AudioStream


static var _ski: AudioStream = null


static func ski_loop() -> AudioStream:
	if _ski != null:
		return _ski
	var path := "res://assets/audio/sfx/ski_loop.mp3"
	if not ResourceLoader.exists(path):
		push_warning("SFX tidak ditemukan: " + path)
		return null
	var mp3 := load(path) as AudioStreamMP3
	if mp3 == null:
		push_warning("SFX gagal dimuat: " + path)
		return null
	mp3.loop = true
	_ski = mp3
	return _ski


static func music() -> AudioStreamWAV:
	if _music == null:
		build_music()
	return _music


static func drums() -> AudioStreamWAV:
	if _drums == null:
		build_music()
	return _drums


static func music_ready() -> bool:
	return _music != null and _drums != null


static func _pluck(freq: float, dur: float, vol: float, decay: float = 0.996) -> PackedFloat32Array:
	var n := int(dur * MUS_RATE)
	var period := maxi(2, int(MUS_RATE / freq))
	var buf := PackedFloat32Array()
	buf.resize(period)
	for i in period:
		buf[i] = randf() * 2.0 - 1.0
	var out := PackedFloat32Array()
	out.resize(n)
	var idx := 0
	var fade_start := int(n * 0.8)
	for i in n:
		var nxt := idx + 1
		if nxt >= period:
			nxt = 0
		var v := buf[idx]
		buf[idx] = (v + buf[nxt]) * 0.5 * decay
		var env := 1.0
		if i > fade_start:
			env = 1.0 - float(i - fade_start) / float(n - fade_start)
		out[i] = v * vol * env
		idx = nxt
	return out


static func _pad(freq: float, dur: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * MUS_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / MUS_RATE
		var vib := 1.0 + 0.004 * sin(t * 5.2) * minf(1.0, t * 1.5)
		ph += freq * vib / MUS_RATE
		var s := sin(ph * TAU) + 0.35 * sin(ph * TAU * 2.0) + 0.12 * sin(ph * TAU * 3.0)
		var br := (randf() * 2.0 - 1.0) * 0.08
		lp += ((s + br) - lp) * 0.3
		var fi := minf(1.0, t / 0.5)
		var fo := minf(1.0, (dur - t) / 0.7)
		out[i] = lp * vol * fi * fo
	return out


static func _taiko(vol: float, low: float) -> PackedFloat32Array:
	var n := int(0.5 * MUS_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var ph := 0.0
	var lp := 0.0
	for i in n:
		var t := float(i) / n
		var f := lerpf(low * 2.2, low, minf(1.0, t * 6.0))
		ph += f / MUS_RATE
		var thump := sin(ph * TAU) * pow(1.0 - t, 2.2)
		lp += ((randf() * 2.0 - 1.0) - lp) * 0.25
		var skin := lp * pow(1.0 - t, 9.0) * 0.5
		out[i] = (thump + skin) * vol
	return out


static var _menu_music_stream: AudioStreamWAV = null

static func menu_music() -> AudioStreamWAV:
	if _menu_music_stream != null: return _menu_music_stream
	var rate := MUS_RATE
	var notes := [293.66, 349.23, 392.0, 440.0, 392.0, 349.23, 261.63, 293.66]
	var step := 0.5
	var samples := PackedFloat32Array()
	samples.resize(int(8.0 * rate))
	for i in notes.size():
		_mix_into(samples, _tone(0.85, notes[i], notes[i] * 0.995, 0, 0.17, 1.2, 0.02, 0.45, rate), int(i * step * rate))
		_mix_into(samples, _tone(1.1, notes[i] * 0.5, notes[i] * 0.5, 3, 0.07, 0.8, 0.0, 0.2, rate), int(i * step * rate))
	_menu_music_stream = _wav(samples, rate, true)
	return _menu_music_stream

static func build_music() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261023
	var bpm := 92.0
	var beat := 60.0 / bpm
	var bars := 8
	var total := int(bars * 4 * beat * MUS_RATE)
	var mel := PackedFloat32Array()
	mel.resize(total)
	var drm := PackedFloat32Array()
	drm.resize(total)

	var scale := [0, 2, 3, 7, 8]
	var root := 293.66
	var degrees: Array = []
	for oct in [-1, 0, 1]:
		for s in scale:
			degrees.append(float(s + oct * 12))
	var phrases: Array = []
	for p in 3:
		var ph: Array = []
		var pos := 7 + rng.randi_range(-1, 1)
		for step in 16:
			if step % 8 == 7 or rng.randf() < 0.28:
				ph.append(-1)
				continue
			pos = clampi(pos + rng.randi_range(-2, 2), 2, degrees.size() - 2)
			ph.append(pos)
		phrases.append(ph)
	var arrangement := [0, 0, 1, 2]
	var eighth := beat * 0.5
	var progress_total := 8.0 + 4.0 + 8.0
	var done := 0.0
	for pi in arrangement.size():
		var ph: Array = phrases[arrangement[pi]]
		for step in 16:
			var d: int = ph[step]
			if d < 0:
				continue
			var f: float = root * pow(2.0, (degrees[d] as float) / 12.0)
			var at := int((pi * 16 + step) * eighth * MUS_RATE)
			_mix_into(mel, _pluck(f, 0.85, 0.5, 0.997), at)
			if step % 8 == 0 and rng.randf() < 0.5:
				_mix_into(mel, _pluck(f * 0.5, 0.9, 0.35, 0.998), at)
		done += 1.0
		music_progress = done / progress_total

	var bass_notes := [73.42, 73.42, 110.0, 73.42, 87.31, 73.42, 110.0, 98.0]
	for b in bars * 2:
		var f: float = bass_notes[b % bass_notes.size()]
		_mix_into(mel, _pluck(f, 1.2, 0.55, 0.999), int(b * 2.0 * beat * MUS_RATE))
	music_progress = (8.0 + 4.0) / progress_total

	var pad_notes := [roundf(root), roundf(root * 1.5), roundf(root * 1.189), roundf(root * 1.5)]
	for i in 4:
		var f: float = pad_notes[i]
		var dur := beat * 8.0
		_mix_into(mel, _pad(f * 0.5, dur, 0.09), int(i * dur * MUS_RATE))
	music_progress = 0.85

	var big := _taiko(0.9, 58.0)
	var small := _taiko(0.5, 90.0)
	for bar in bars:
		var b0 := bar * 4.0 * beat
		_mix_into(drm, big, int(b0 * MUS_RATE))
		_mix_into(drm, small, int((b0 + 2.0 * beat) * MUS_RATE), 0.8)
		_mix_into(drm, small, int((b0 + 2.75 * beat) * MUS_RATE), 0.55)
		if bar % 2 == 1:
			_mix_into(drm, small, int((b0 + 3.5 * beat) * MUS_RATE), 0.7)
		for k in 8:
			var tk := _tone(0.03, 1800, 1500, 1, 0.07, 3.0, 0.3, 0.8, MUS_RATE)
			_mix_into(drm, tk, int((b0 + k * 0.5 * beat) * MUS_RATE), 0.6 if k % 2 == 0 else 0.3)

	var peak := 0.001
	for i in total:
		peak = maxf(peak, absf(mel[i]))
	var g := 0.85 / peak
	for i in total:
		mel[i] = clampf(mel[i] * g, -1.0, 1.0)
	var peak2 := 0.001
	for i in total:
		peak2 = maxf(peak2, absf(drm[i]))
	var g2 := 0.9 / peak2
	for i in total:
		drm[i] = clampf(drm[i] * g2, -1.0, 1.0)

	_drums = _wav(drm, MUS_RATE, true)
	_music = _wav(mel, MUS_RATE, true)
	music_progress = 1.0
