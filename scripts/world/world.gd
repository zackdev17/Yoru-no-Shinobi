class_name World
extends Node2D

signal popup(world_pos: Vector2, text: String, color: Color)
signal stage_changed(index: int, title: String)
signal run_ended(stats: Dictionary)
signal pickup(kind: String)
signal hurt

const GY := 216.0
const ULTIMATE_ZOOM := 2.25
const ULTIMATE_MIN_ZOOM := 0.95
const ULTIMATE_TOP_MARGIN := 56.0
const ULTIMATE_GROUND_MARGIN := 22.0
const ULTIMATE_USABLE := 0.88
const ULTIMATE_FX_PATH := "res://scripts/fx/ultimate_fx.gd"

var demo := true
var running := false
var player: Ninja
var cam: Camera2D
var bg: Background
var weather: Weather
var cm: CanvasModulate
var moon_light: DirectionalLight2D
var env: Environment
var ground_root: Node2D
var prop_root: Node2D
var ent_root: Node2D
var fx_root: Node2D
var gen := LevelGen.new()
var fireflies: Array = []
var mist: Array = []

var cam_x := 130.0
var cam_y := 144.0
var stage := 0
var applied_stage := -1
var horde_warned := -1
var speed_base := 228.0
var coins_run := 0
var money_run := 0
var kills := 0
var bonus := 0
var combo := 0
var combo_t := 0.0
var best_combo := 0
var dist_m := 0.0
var time_run := 0.0
var shake_amp := 0.0
var shake_t := 0.0
var zoom_punch := 0.0
var lightning_timer := 6.0
var cull_timer := 0.0
var t_all := 0.0
var transitioning := false
var ultimate_zoom_t := 0.0
var ultimate_active := false
var ultimate_base_zoom := 1.0
var ultimate_elapsed := 0.0
var ult_fit_zoom := 2.25
const STAGE_GRACE := 2.0
const STAGE_GRACE_AFTER := 2.5
var ult_zoom := 2.25
var ult_len := 3.65
var fx_tint := Color(0.78, 0.86, 1.18)
var fx_raycol := Color(0.30, 0.55, 1.0)
var ultimate_time_restore_timer: SceneTreeTimer

var fx_flash := 0.0
var fx_damage := 0.0
var fx_ab := 0.0
var fx_dash := 0.0
var fx_fade := 0.0
var fx_cine := 0.0
var fx_rays := 0.0
var fx_fade_col := Color(0.8, 0.85, 1.0)


func _ready() -> void:
	gen.w = self
	cm = CanvasModulate.new()
	add_child(cm)
	bg = Background.new()
	add_child(bg)
	ground_root = Node2D.new()
	add_child(ground_root)
	prop_root = Node2D.new()
	add_child(prop_root)
	ent_root = Node2D.new()
	add_child(ent_root)
	player = Ninja.new()
	player.world = self
	add_child(player)
	fx_root = Node2D.new()
	add_child(fx_root)
	weather = Weather.new()
	add_child(weather)

	cam = Camera2D.new()
	cam.position = Vector2(cam_x, 144)
	add_child(cam)
	cam.make_current()

	moon_light = DirectionalLight2D.new()
	moon_light.energy = 0.55
	moon_light.height = 0.55
	moon_light.max_distance = 500.0
	moon_light.range_item_cull_mask = 1
	add_child(moon_light)

	var we := WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.85
	env.glow_strength = 1.0
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 0.82
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	we.environment = env
	add_child(we)

	for i in 12:
		var f := Firefly.new()
		f.setup(Color("#fff3a0"), i < 5)
		f.position = Vector2(randf_range(-300, 300), randf_range(100, 200))
		f.visible = false
		add_child(f)
		fireflies.append(f)
	for i in 7:
		var s := Sprite2D.new()
		s.texture = TexGen.glow_tex(64)
		s.scale = Vector2(7.0, 0.9)
		s.material = Fx.add_mat()
		s.z_index = 6
		s.set_meta("o", randf() * 800.0)
		s.position.y = 196.0 + randf() * 18.0
		add_child(s)
		mist.append(s)

	player.died.connect(_on_player_died)
	GameState.settings_changed.connect(_apply_settings)
	_apply_settings()


func _apply_settings() -> void:
	if env:
		env.glow_enabled = bool(GameState.settings["bloom"])


func _clear() -> void:
	for r in [ground_root, prop_root, ent_root, fx_root]:
		for c in (r as Node).get_children():
			c.queue_free()


func start(is_demo: bool) -> void:
	demo = is_demo
	if player != null and player.ultimate_active:
		Sfx.cancel_ult_audio()
	if ultimate_active or (player != null and player.ultimate_active):
		ultimate_end()
	Engine.time_scale = 1.0
	fx_flash = 0.0
	fx_ab = 0.0
	fx_dash = 0.0
	zoom_punch = 0.0
	fx_tint = Color(0.78, 0.86, 1.18)
	fx_raycol = Color(0.30, 0.55, 1.0)
	_clear()
	running = true
	coins_run = 0
	money_run = 0
	kills = 0
	bonus = 0
	combo = 0
	combo_t = 0.0
	best_combo = 0
	dist_m = 0.0
	time_run = 0.0
	stage = 0
	horde_warned = -1
	transitioning = false
	fx_fade = 0.0
	fx_cine = 0.0
	fx_rays = 0.0
	player.scarf.visible = true
	player.god = is_demo
	player.use_ai = is_demo
	player.reset_for_run(Vector2(0, GY - 2.0))
	player.end_slide()
	player.intro_t = 0.0
	cam_x = 130.0
	cam_y = 144.0
	gen.reset(700.0)
	add_ground(-700.0, 700.0, 0)
	_props_start()
	apply_theme(0)
	if not is_demo:
		stage_changed.emit(0, Themes.at(0)["name"])


func _props_start() -> void:
	add_prop("stone_lantern", 150.0, 0)
	add_prop("paper_pole", 330.0, 0)
	add_prop("banner", 520.0, 0)
	add_prop("bush", 60.0, 0)
	add_gate(-60.0, 0)


func stop_run() -> void:
	running = false


func apply_theme(idx: int) -> void:
	applied_stage = idx
	var th := Themes.at(idx)
	cm.color = th["ambient"]
	env.glow_hdr_threshold = float(th.get("glow_thr", 0.82))
	env.glow_intensity = float(th.get("glow_int", 0.85))
	bg.apply_theme(th)
	weather.set_kind(th["weather"], th)
	moon_light.color = th["moon_light"]
	moon_light.energy = th["moon_energy"]
	var mx: float = (th["moon"]["pos"] as Vector2).x
	moon_light.rotation_degrees = 30.0 if mx > 320.0 else -30.0
	moon_light.shadow_enabled = bool(GameState.settings["shadows"])
	moon_light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
	moon_light.shadow_filter_smooth = 2.0
	var fc: Dictionary = th["firefly"]
	for i in fireflies.size():
		var f: Firefly = fireflies[i]
		f.visible = i < int(fc["count"])
		f.recolor(fc["col"])
	for m in mist:
		var s: Sprite2D = m
		var fog: Color = th["fog"]
		s.modulate = Color(fog.r, fog.g, fog.b, fog.a * 0.55)


func add_ground(x0: float, x1: float, st: int) -> void:
	var g := Ground.new()
	g.setup(x0, x1, st)
	g.set_meta("ex", x1)
	ground_root.add_child(g)


func add_water(x0: float, x1: float, st: int) -> void:
	var wt := Water.new()
	wt.setup(x0, x1, Themes.at(st))
	wt.set_meta("ex", x1)
	ground_root.add_child(wt)


func add_platform(x: float, y: float, wd: float, st: int) -> void:
	var p := Platform.new()
	p.setup(x, y, wd, Themes.at(st))
	p.set_meta("ex", x + wd)
	ground_root.add_child(p)


func add_prop(k: String, x: float, st: int, sc: float = 1.0) -> void:
	var p := Prop.new()
	p.setup(k, x, Themes.at(st), sc)
	p.set_meta("ex", x + 80.0)
	prop_root.add_child(p)


func add_gate(x: float, st: int) -> void:
	add_prop("torii", x, st, 1.5)


func spawn_coin(pos: Vector2) -> void:
	var c := Coin.new()
	c.world = self
	c.position = pos
	ent_root.add_child(c)


func spawn_powerup(k: String, pos: Vector2) -> void:
	var p := PowerUp.new()
	p.kind = k
	p.world = self
	p.position = pos
	ent_root.add_child(p)


func spawn_hazard(k: String, pos: Vector2, st: int, wd: float = 24.0) -> void:
	var h: Hazard
	match k:
		"oni": h = Oni.new()
		"crow": h = Crow.new()
		"wisp": h = Wisp.new()
		"barrel": h = Barrel.new()
		"strike": h = Strike.new()
		_:
			var sp := Spikes.new()
			sp.w = wd
			h = sp
	h.world = self
	h.tint = st
	h.position = pos
	ent_root.add_child(h)


func spawn_shuriken(pos: Vector2) -> void:
	var s := Shuriken.new()
	s.world = self
	s.position = pos
	ent_root.add_child(s)


func collect_coin(c: Coin) -> void:
	combo += 1
	combo_t = 1.6
	best_combo = maxi(best_combo, combo)
	coins_run += 1
	var mult := 1.0 + float(combo) / 12.0
	if player.star_t > 0.0:
		mult *= 2.0
	money_run += int(round(c.value * mult * GameState.coin_mult()))
	Sfx.play("coin", 1.0 + minf(combo, 14) * 0.035, -6.0)
	Fx.burst(fx_root, c.global_position, Color(1.0, 0.85, 0.3), 5, 50.0, 0.3, 60.0)
	if combo % 5 == 0:
		popup.emit(player.global_position + Vector2(0, -34), "x%d COMBO!" % (combo / 5 + 1), Color(1.0, 0.85, 0.3))


func collect_powerup(kind: String, pos: Vector2) -> void:
	Sfx.play("powerup")
	pickup.emit(kind)
	Fx.ring(fx_root, pos, PowerUp.COLORS[kind], 4.0, 34.0, 0.45, 3.0)
	Fx.burst(fx_root, pos, PowerUp.COLORS[kind], 14, 90.0, 0.5, 60.0)
	var label := ""
	match kind:
		"shield":
			player.shield = true
			label = "SHIELD"
		"magnet":
			player.magnet_t = GameState.magnet_time()
			label = "MAGNET"
		"star":
			player.star_t = 7.0
			label = "INVINCIBLE!"
		"lightning":
			_chain_lightning()
			label = "RAIJIN STRIKE"
		"heart":
			player.heal(1)
			Sfx.play("heart")
			label = "+1 HEART"
	popup.emit(pos + Vector2(0, -18), label, PowerUp.COLORS[kind])


func _chain_lightning() -> void:
	var from := player.global_position + Vector2(0, -14)
	var n := 0
	for h in ent_root.get_children():
		if h is Hazard and not (h is Spikes) and not (h is Strike):
			var hz := h as Hazard
			if absf(hz.global_position.x - cam_x) < 340.0 and not hz.dying:
				Fx.bolt(fx_root, from, hz.global_position + Vector2(0, -10))
				hz.kill("lightning")
				n += 1
	big_flash(0.7)
	shake(4.0, 0.3)
	Sfx.play("zap")
	Sfx.play("thunder", 1.3, -8.0)
	bg.lightning(randf_range(120, 520))


func on_hazard_killed(h: Hazard, by: String) -> void:
	kills += 1
	bonus += h.score_value
	combo += 1
	combo_t = 1.6
	var death_key := "kill"
	match by:
		"shuriken": death_key = "enemy_death_shuriken"
		"fire", "meteor": death_key = "enemy_death_fire"
		"freeze", "shatter": death_key = "enemy_death_ice"
		"plasma", "radiation", "nuke", "eclipse": death_key = "enemy_death_plasma"
		"wave": death_key = "enemy_death_skill"
		"shadow_dash": death_key = "shadow_impact"
	Sfx.play(death_key, randf_range(0.94, 1.06), -6.0)
	Fx.smoke(fx_root, h.global_position + Vector2(0, -10))
	Fx.ring(fx_root, h.global_position + Vector2(0, -10), Color(1, 0.9, 0.6, 0.9), 3.0, 20.0, 0.25)
	if h.score_value > 0:
		popup.emit(h.global_position + Vector2(0, -26), "+%d" % h.score_value, Color(1, 0.6, 0.4))
	if by == "stomp" or by == "dash":
		hitstop(0.05)
		shake(2.5, 0.12)


func on_player_hurt(src: Vector2) -> void:
	combo = 0
	hitstop(0.09)
	shake(6.0, 0.35)
	zoom_punch = 0.07
	Sfx.play("hurt_" + player.char_id, 1.0, -3.0)
	hurt.emit()
	var tw := create_tween()
	fx_damage = 1.0
	fx_ab = 1.0
	tw.tween_property(self, "fx_damage", 0.0, 0.7)
	tw.parallel().tween_property(self, "fx_ab", 0.0, 0.5)
	Fx.burst(fx_root, player.global_position + Vector2(0, -14), Color(1.0, 0.35, 0.4), 12, 130.0, 0.5, 300.0)


func player_fell(p: Ninja) -> void:
	Sfx.play("splash")
	Fx.burst(fx_root, Vector2(p.global_position.x, GY + 4.0), Color(0.7, 0.85, 1.0), 16, 150.0, 0.6, 400.0, "orb", false, 60.0, Vector2.UP, 1.6)
	Fx.ring(fx_root, Vector2(p.global_position.x, GY + 4.0), Color(0.8, 0.9, 1.0, 0.8), 3.0, 26.0, 0.5)
	if not p.god:
		p.hearts -= 1
		p.hearts_changed.emit()
		on_player_hurt(p.global_position)
		if p.hearts <= 0:
			p.die()
			return
	p.global_position = Vector2(maxf(p.last_safe_x - 30.0, cam_x - 250.0), GY - 40.0)
	p.velocity = Vector2(0, 0)
	p.invuln = 2.0
	p.jumps_left = 2


func _on_player_died() -> void:
	running = false
	Sfx.play("gameover")
	hitstop(0.12)
	var score := compute_score()
	var st := {
		"dist": int(dist_m), "coins": coins_run, "money": money_run, "kills": kills,
		"combo": best_combo, "score": score, "stage": stage,
		"new_best": score > GameState.best_score,
	}
	if not demo:
		GameState.add_coins(money_run)
		GameState.total_runs += 1
		GameState.best_m = maxi(GameState.best_m, int(dist_m))
		GameState.best_score = maxi(GameState.best_score, score)
		GameState.save_game()
		run_ended.emit(st)


func finish_world_end() -> void:
	if not running:
		return
	running = false
	var score := compute_score()
	var st := {
		"dist": int(dist_m), "coins": coins_run, "money": money_run, "kills": kills,
		"combo": best_combo, "score": score, "stage": stage,
		"new_best": score > GameState.best_score,
	}
	if not demo:
		GameState.add_coins(money_run)
		GameState.total_runs += 1
		GameState.best_m = maxi(GameState.best_m, int(dist_m))
		GameState.best_score = maxi(GameState.best_score, score)
		GameState.save_game()
		run_ended.emit(st)


func compute_score() -> int:
	return int(dist_m * 2.0) + money_run * 5 + bonus


func ultimate_begin(kind: String = "thunder") -> void:
	ultimate_active = true
	ultimate_elapsed = 0.0
	var usk: Dictionary = GameState.char_def()["skills"]["ultimate"]
	ult_len = float(usk.get("len", 3.65))
	ult_zoom = float(usk.get("zoom", ULTIMATE_ZOOM)) if kind != "thunder" else ULTIMATE_ZOOM
	fx_tint = Color(0.78, 0.86, 1.18)
	fx_raycol = Color(0.30, 0.55, 1.0)
	ultimate_zoom_t = ult_len
	ult_fit_zoom = ult_zoom
	ultimate_base_zoom = 1.0
	zoom_punch = 0.0
	fx_ab = 0.35
	fx_dash = 0.55
	big_flash(0.45)
	shake(3.0, 0.24)
	Engine.time_scale = 0.24
	if kind == "thunder":
		var ufx_script := load(ULTIMATE_FX_PATH) as GDScript
		if ufx_script:
			var ufx := ufx_script.new() as Node2D
			ufx.call("setup", self, player)
			fx_root.add_child(ufx)
	for i in (24 if kind == "thunder" else 12):
		var y := randf_range(-100.0, 100.0)
		var start := player.global_position + Vector2(randf_range(-250.0, 250.0), y)
		var finish := player.global_position + Vector2(randf_range(-26.0, 26.0), y * 0.18)
		var ln := Line2D.new()
		ln.points = PackedVector2Array([start, finish])
		ln.width = randf_range(1.0, 3.2)
		ln.default_color = _ult_line_cols(kind)[i % 3]
		ln.z_index = 18
		fx_root.add_child(ln)
		var tw := ln.create_tween()
		tw.tween_property(ln, "modulate:a", 0.0, 0.68)
		tw.tween_callback(ln.queue_free)

func _ult_line_cols(kind: String) -> Array:
	match kind:
		"storm": return [Color("#7dffc4", 0.75), Color("#c9ffe8", 0.7), Color("#3fd6a0", 0.7)]
		"meteor": return [Color("#ff9a3a", 0.8), Color("#ffd27a", 0.75), Color("#ff5a1f", 0.75)]
		"blizzard": return [Color("#a9eaff", 0.8), Color("#ffffff", 0.7), Color("#6fb6ff", 0.75)]
		"nuke": return [Color("#b8ff3a", 0.8), Color("#ffe14a", 0.75), Color("#ff5a2a", 0.7)]
		"worldend": return [Color("#ffd75a", 0.8), Color("#b07aff", 0.8), Color("#fff2c0", 0.7)]
	return [Color("#8beaff", 0.8), Color("#c08aff", 0.85), Color("#ffffff", 0.72)]


func ultimate_strike() -> void:
	var left := cam_x - 310.0
	for i in 13:
		var x := left + float(i) * 52.0 + randf_range(-12.0, 12.0)
		var top := Vector2(x, cam.position.y - 175.0)
		var bottom := Vector2(x + randf_range(-12.0, 12.0), cam.position.y + 125.0)
		Fx.bolt(fx_root, top, bottom, Color("#b8f7ff", 1.0))
		Fx.burst(fx_root, bottom, Color("#baf7ff"), 8, 115.0, 0.35, -10.0, "spark", true, 360.0, Vector2.UP, 2.2)
	for n in ent_root.get_children():
		if n is Hazard:
			var h := n as Hazard
			if not h.dying:
				Fx.burst(fx_root, h.global_position, Color("#b98aff"), 18, 180.0, 0.55, 240.0)
				if not (h is Spikes) and not (h is Strike):
					h.kill("ultimate")
				else:
					h.queue_free()
	for n in prop_root.get_children():
		Fx.burst(fx_root, n.global_position + Vector2(0, -20), Color("#8beaff"), 12, 145.0, 0.45, 180.0)
		n.queue_free()
	for ang in [-0.78, 0.78, 0.0, 1.57]:
		var slash := FxShape.new()
		slash.kind = "slash"
		slash.col = Color("#eafcff", 1.0) if ang == 0.0 else Color("#a86bff", 0.98)
		slash.r0 = 72.0
		slash.r1 = 210.0
		slash.life = 0.42
		slash.width = 8.0 if ang == 0.0 else 5.0
		slash.angle0 = -1.25
		slash.angle1 = 1.25
		slash.position = player.global_position + Vector2(0, -16)
		slash.rotation = ang
		fx_root.add_child(slash)
	Fx.ring(fx_root, player.global_position + Vector2(0, -15), Color("#f4fdff", 1.0), 12.0, 190.0, 0.38, 8.0)
	Fx.ring(fx_root, player.global_position + Vector2(0, -15), Color("#a65cff", 0.95), 8.0, 235.0, 0.52, 5.0)
	Fx.burst(fx_root, player.global_position + Vector2(0, -15), Color("#d6faff"), 64, 290.0, 0.58, -45.0, "spark", true, 360.0, Vector2.UP, 3.8)
	Fx.burst(fx_root, player.global_position + Vector2(0, -15), Color("#a45bff"), 48, 220.0, 0.65, 35.0, "orb", true, 360.0, Vector2.UP, 3.0)
	shake(18.0, 0.62)
	big_flash(0.75)
	fx_ab = 0.7
	fx_dash = 1.0

func ultimate_end() -> void:
	ultimate_active = false
	Engine.time_scale = 1.0
	zoom_punch = 0.0
	fx_ab = 0.0
	fx_dash = 0.0
	cam.zoom = Vector2.ONE

func shake(amp: float, t: float) -> void:
	if not GameState.settings["shake"]:
		return
	shake_amp = maxf(shake_amp, amp)
	shake_t = maxf(shake_t, t)


func big_flash(v: float) -> void:
	fx_flash = maxf(fx_flash, v)


func dash_fx(on: bool) -> void:
	if on:
		var tw := create_tween()
		tw.tween_property(self, "fx_dash", 1.0, 0.06)
		tw.tween_property(self, "fx_dash", 0.0, 0.3)
		zoom_punch = -0.05


func hitstop(t: float) -> void:
	Engine.time_scale = 0.06
	get_tree().create_timer(t, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)


func _physics_process(delta: float) -> void:
	t_all += delta
	if running:
		time_run += delta
		var prog := player.global_position.x / Themes.STAGE_PX
		player.run_speed = minf(228.0 + 14.0 * prog, 345.0)
		dist_m = maxf(dist_m, player.global_position.x / Themes.PX_PER_M)
		if combo_t > 0.0:
			combo_t -= delta
			if combo_t <= 0.0:
				combo = 0
		gen.update(player.global_position.x)
		_check_stage()
		_check_horde_warning()
		if demo:
			_demo_ai(delta)
		Sfx.set_intensity(clampf((prog - 0.15) / 1.2 + 0.25, 0.0, 1.0) if not demo else 0.4)
		if Themes.at(applied_stage)["lightning"]:
			lightning_timer -= delta
			if lightning_timer <= 0.0:
				lightning_timer = randf_range(4.0, 9.0)
				_sky_lightning()
	cull_timer -= delta
	if cull_timer <= 0.0:
		cull_timer = 0.6
		_cull()


func _process(delta: float) -> void:
	var real_delta := delta / maxf(Engine.time_scale, 0.05)
	var off := Vector2.ZERO
	if shake_t > 0.0:
		shake_t -= delta
		off = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake_amp
		if shake_t <= 0.0:
			shake_amp = 0.0

	zoom_punch = move_toward(zoom_punch, 0.0, delta * 0.35)
	var z := 1.0 + zoom_punch
	var vh := get_viewport_rect().size.y
	if vh <= 1.0:
		vh = 288.0
	var ult_mid_y := 144.0
	if ultimate_active:
		ultimate_elapsed += real_delta
		var zoom_in := 1.0
		var out_start := ult_len - 0.8
		if ultimate_elapsed < 0.55:
			zoom_in = lerpf(1.0, ult_zoom, smoothstep(0.0, 0.55, ultimate_elapsed))
		elif ultimate_elapsed < out_start:
			zoom_in = ult_zoom
		else:
			zoom_in = lerpf(ult_zoom, 1.0, smoothstep(out_start, ult_len, ultimate_elapsed))
		var top_y := player.pivot.global_position.y - ULTIMATE_TOP_MARGIN
		var bot_y := GY + ULTIMATE_GROUND_MARGIN
		var fit := clampf(vh * ULTIMATE_USABLE / maxf(bot_y - top_y, 1.0), ULTIMATE_MIN_ZOOM, ult_zoom)
		ult_fit_zoom = lerpf(ult_fit_zoom, fit, minf(1.0, real_delta * 10.0))
		z = minf(zoom_in, ult_fit_zoom) + zoom_punch
		ult_mid_y = (top_y + bot_y) * 0.5
		ultimate_zoom_t = maxf(0.0, ultimate_zoom_t - delta)

	var target_x := player.global_position.x + (-90.0 if demo else 130.0)
	var target_y := 144.0
	var rate := 9.0
	if ultimate_active:
		var body := player.pivot.global_position
		target_x = body.x
		var half_h := vh * 0.5 / z
		target_y = clampf(ult_mid_y, half_h - 64.0, vh - half_h + 8.0)
		rate = 14.0
	if running or not player.dead:
		var k := minf(1.0, real_delta * rate)
		cam_x = lerpf(cam_x, target_x, k)
		cam_y = lerpf(cam_y, target_y, k)
	cam.position = Vector2(roundf(cam_x), roundf(cam_y)) + off.round()
	cam.zoom = Vector2(z, z)
	var cine_target := 1.0 if ultimate_active else 0.0
	fx_cine = move_toward(fx_cine, cine_target, real_delta * (3.0 if ultimate_active else 2.2))
	var rays_target := 0.0
	if ultimate_active:
		rays_target = clampf((ultimate_elapsed - 0.6) / 1.5, 0.0, 1.0)
	fx_rays = move_toward(fx_rays, rays_target, real_delta * 2.0)
	bg.update_scroll(roundf(cam_x), delta)
	weather.follow(cam_x)
	fx_flash = move_toward(fx_flash, 0.0, (real_delta * 3.2 if ultimate_active else delta * 2.2))
	for f in fireflies:
		if (f as Firefly).visible:
			(f as Firefly).step(delta, cam_x)
	for m in mist:
		var s: Sprite2D = m
		s.position.x = cam_x - 400.0 + fposmod(float(s.get_meta("o")) + t_all * 7.0 - cam_x * 0.35, 800.0)
	var th := Themes.at(applied_stage)
	moon_light.energy = float(th["moon_energy"]) * (0.95 + 0.05 * sin(t_all * 0.8)) + fx_flash * 1.6


func _cull() -> void:
	for r in [ground_root, prop_root]:
		for c in (r as Node).get_children():
			if c.has_meta("ex") and float(c.get_meta("ex")) < cam_x - 460.0:
				c.queue_free()


func horde_zone() -> bool:
	if demo:
		return false
	return fposmod(player.global_position.x / Themes.STAGE_PX, 1.0) >= LevelGen.HORDE_START - 0.03


func _check_horde_warning() -> void:
	if not horde_zone():
		return
	var s := int(player.global_position.x / Themes.STAGE_PX)
	if horde_warned == s:
		return
	horde_warned = s
	Sfx.play("warn", 0.8, -2.0)
	shake(3.0, 0.3)
	popup.emit(player.global_position + Vector2(0, -60), "HORDE INCOMING!", Color(1.0, 0.3, 0.3))


func _check_stage() -> void:
	var s := int(player.global_position.x / Themes.STAGE_PX)
	if s > stage and not transitioning:
		stage = s
		transitioning = true
		_stage_grace(STAGE_GRACE)
		Sfx.play("stage")
		var tw := create_tween()
		tw.tween_property(self, "fx_fade", 1.0, 0.45)
		tw.tween_callback(func():
			apply_theme(stage)
			_stage_grace(STAGE_GRACE_AFTER)
			stage_changed.emit(stage, Themes.at(stage)["name"]))
		tw.tween_property(self, "fx_fade", 0.0, 0.9)
		tw.tween_callback(func(): transitioning = false)


func _stage_grace(dur: float) -> void:
	if player == null or player.dead:
		return
	if player.invuln < dur:
		player.invuln = dur
		Fx.ring(fx_root, player.global_position + Vector2(0, -14), Color(0.6, 1.0, 0.9, 0.9), 8.0, 46.0, 0.45, 3.0)


func _sky_lightning() -> void:
	bg.lightning(randf_range(80.0, 560.0))
	big_flash(0.45)
	Fx.ring(fx_root, Vector2(cam_x, 60.0), Color(0.8, 0.85, 1.0, 0.0), 1.0, 2.0, 0.1)
	var d := randf_range(0.35, 1.3)
	get_tree().create_timer(d).timeout.connect(func():
		Sfx.play("thunder", randf_range(0.8, 1.1), -5.0)
		shake(2.0, 0.4))
	get_tree().create_timer(0.18).timeout.connect(func(): big_flash(0.3))


func ground_at(x: float) -> bool:
	for g in ground_root.get_children():
		if g is Ground and x >= (g as Ground).x0 and x <= (g as Ground).x1:
			return true
	return false


func _demo_ai(_delta: float) -> void:
	var a := player.ai
	for k in a.keys():
		a[k] = false
	var px := player.global_position.x
	var floor_now := player.is_on_floor()
	if floor_now and not ground_at(px + 58.0):
		a["jump"] = true
	elif not floor_now and player.velocity.y > 0.0 and player.jumps_left > 0 \
			and not ground_at(px + 14.0) and player.global_position.y > GY - 50.0:
		a["jump"] = true
	for h in ent_root.get_children():
		if not (h is Hazard):
			continue
		var dx: float = (h as Hazard).global_position.x - px
		if dx < 0.0 or dx > 150.0:
			continue
		if h is Oni:
			if player.ammo > 0 and dx < 150.0 and dx > 80.0:
				a["throw"] = true
			elif dx < 64.0 and floor_now:
				a["jump"] = true
		elif h is Crow or h is Wisp:
			if dx < 70.0 and floor_now:
				a["slide"] = true
		elif h is Barrel:
			if dx < 74.0 and floor_now:
				a["jump"] = true
		elif h is Spikes:
			if dx < 58.0 + (h as Spikes).w * 0.3 and floor_now:
				a["jump"] = true
