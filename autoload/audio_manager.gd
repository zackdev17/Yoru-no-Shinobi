extends Node

var _pool: Array[AudioStreamPlayer] = []
var _voice: AudioStreamPlayer
var _ult_bgm: AudioStreamPlayer
var _bgm_tw: Tween
var music_duck_db := 0.0:
	set(v):
		music_duck_db = v
		if _music_bus >= 0:
			apply_volumes()
var _next := 0
var _music: AudioStreamPlayer
var _drums: AudioStreamPlayer
var _menu_music: AudioStreamPlayer
var _music_mode := ""
var _intensity := 0.0
var _lp_fx: AudioEffectLowPassFilter
var _music_bus := -1
var _sfx_bus := -1
var _external_gameplay_music := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buses()
	for i in 12:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_voice = AudioStreamPlayer.new()
	_voice.bus = "SFX"
	add_child(_voice)
	_ult_bgm = AudioStreamPlayer.new()
	_ult_bgm.bus = "SFX"
	add_child(_ult_bgm)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	add_child(_music)
	_menu_music = AudioStreamPlayer.new()
	_menu_music.bus = "Music"
	_menu_music.volume_db = -7.0
	add_child(_menu_music)
	_drums = AudioStreamPlayer.new()
	_drums.bus = "Music"
	_drums.volume_db = -80.0
	add_child(_drums)
	GameState.settings_changed.connect(apply_volumes)
	apply_volumes()


func _setup_buses() -> void:
	for n in ["Music", "SFX"]:
		if AudioServer.get_bus_index(n) == -1:
			AudioServer.add_bus()
			var idx := AudioServer.bus_count - 1
			AudioServer.set_bus_name(idx, n)
			AudioServer.set_bus_send(idx, "Master")
	_music_bus = AudioServer.get_bus_index("Music")
	_sfx_bus = AudioServer.get_bus_index("SFX")
	_lp_fx = AudioEffectLowPassFilter.new()
	_lp_fx.cutoff_hz = 20000.0
	AudioServer.add_bus_effect(_music_bus, _lp_fx)


func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(_music_bus, linear_to_db(maxf(0.0001, float(GameState.settings["music"]))) + music_duck_db)
	AudioServer.set_bus_volume_db(_sfx_bus, linear_to_db(maxf(0.0001, float(GameState.settings["sfx"]))))


func play(sfx_name: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = Assets.sfx(sfx_name)
	p.pitch_scale = pitch
	p.volume_db = vol_db
	p.stream_paused = false
	p.play()


func play_voice(voice_name: String, pitch: float = 1.0, vol_db: float = 0.0) -> void:
	var st := Assets.sfx(voice_name)
	if st == null:
		return
	_voice.stream = st
	_voice.pitch_scale = pitch
	_voice.volume_db = vol_db
	_voice.play()


func play_ult_bgm(bgm_name: String, vol_db: float = -6.0, duck_db: float = -26.0) -> void:
	var st := Assets.sfx(bgm_name)
	if st == null:
		return
	if _bgm_tw != null and _bgm_tw.is_valid():
		_bgm_tw.kill()
	_ult_bgm.stop()
	_ult_bgm.stream = st
	_ult_bgm.volume_db = vol_db
	_ult_bgm.stream_paused = false
	_ult_bgm.play()
	_bgm_tw = create_tween()
	_bgm_tw.tween_property(self, "music_duck_db", duck_db, 0.8)


func stop_ult_bgm(fade: float = 0.5, restore_music: float = 1.8) -> void:
	if _bgm_tw != null and _bgm_tw.is_valid():
		_bgm_tw.kill()
	_bgm_tw = create_tween()
	if _ult_bgm.playing:
		_bgm_tw.tween_property(_ult_bgm, "volume_db", -60.0, fade)
		_bgm_tw.tween_callback(_ult_bgm.stop)
	_bgm_tw.tween_property(self, "music_duck_db", 0.0, restore_music)


func cancel_ult_audio() -> void:
	if _bgm_tw != null and _bgm_tw.is_valid():
		_bgm_tw.kill()
	for p in _pool:
		p.stop()
		p.stream_paused = false
	_voice.stop()
	_voice.stream_paused = false
	_ult_bgm.stop()
	_ult_bgm.stream_paused = false
	_bgm_tw = create_tween()
	_bgm_tw.tween_property(self, "music_duck_db", 0.0, 0.4)


func set_ult_audio_paused(on: bool) -> void:
	_ult_bgm.stream_paused = on
	_voice.stream_paused = on


func _load_track(stem: String, fallback: AudioStream) -> AudioStream:
	for ext in ["ogg", "mp3", "wav"]:
		var path := "res://assets/audio/%s.%s" % [stem, ext]
		if not ResourceLoader.exists(path):
			continue
		var resource: Resource = load(path)
		if not (resource is AudioStream):
			push_warning("Audio ditemukan tetapi gagal dimuat sebagai AudioStream: " + path)
			continue
		var stream := resource as AudioStream
		if stream is AudioStreamOggVorbis:
			(stream as AudioStreamOggVorbis).loop = true
		elif stream is AudioStreamMP3:
			(stream as AudioStreamMP3).loop = true
		elif stream is AudioStreamWAV:
			var wav := stream as AudioStreamWAV
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			var bytes_per_frame := 4 if wav.stereo else 2
			wav.loop_begin = 0
			wav.loop_end = maxi(1, int(wav.data.size() / bytes_per_frame))
		print("[AudioManager] Musik dimuat: ", path)
		return stream
	push_warning("File musik '" + stem + "' tidak ditemukan/terbaca. Menggunakan musik bawaan.")
	return fallback

func start_music() -> void:
	var lobby_stream := _load_track("lobby", Assets.menu_music())
	var gameplay_stream := _load_track("gameplay", Assets.music())
	_menu_music.stream = lobby_stream
	_music.stream = gameplay_stream
	_external_gameplay_music = gameplay_stream != Assets.music()
	_drums.stream = Assets.drums()
	set_music_mode("menu")

func set_music_mode(mode: String) -> void:
	if _music_mode == mode and ((_menu_music.playing and mode == "menu") or (_music.playing and mode == "gameplay")): return
	_music_mode = mode
	if mode == "menu":
		_music.stop()
		_drums.stop()
		_menu_music.volume_db = -6.0
		if not _menu_music.playing: _menu_music.play()
	else:
		_menu_music.stop()
		_music.volume_db = -5.0
		if not _music.playing: _music.play()
		if not _external_gameplay_music:
			if not _drums.playing: _drums.play()
		else:
			_drums.stop()


func set_intensity(x: float) -> void:
	_intensity = clampf(x, 0.0, 1.0)
	_drums.volume_db = lerpf(-80.0, -3.0, _intensity) if _intensity > 0.02 else -80.0


func set_muffled(on: bool) -> void:
	var tw := create_tween()
	tw.tween_property(_lp_fx, "cutoff_hz", 700.0 if on else 20000.0, 0.25)
