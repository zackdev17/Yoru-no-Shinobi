class_name Ninja
extends CharacterBody2D

signal hearts_changed
signal died

const GRAVITY := 1750.0
const JUMP_V := -540.0
const DJUMP_V := -470.0
const COYOTE := 0.09
const BUFFER := 0.12
const SLIDE_TIME := 0.55
const DASH_TIME := 0.24

var world: Node
var run_speed := 235.0
var hearts := 3
var max_hearts := 3
var invuln := 0.0
var shield := false
var star_t := 0.0
var magnet_t := 0.0
var ammo := 5
var ammo_timer := 0.0
var dash_cd := 0.0
var dash_t := 0.0
var shadow_attack_t := 0.0
var shadow_attack_active := false
var shadow_targets: Array[Hazard] = []
var shadow_target_index := 0
var shadow_step_t := 0.0
var shadow_origin := Vector2.ZERO
var shadow_attack_cd := 0.0
var char_id := ""
var cdata: Dictionary = {}
var skills: Dictionary = {}
var run_style := "classic"
var speed_mult := 1.0
var jump_mult := 1.0
var grav_mult := 1.0
var ult_cd := 0.0
var _ult_ready_sound_played := false
var _ult_charge_sound_played := false
var ult_mode_t := 0.0
var ult_mode_kind := ""
var ult_mode_total := 0.0
var ult_acc := 0.0
var ult_acc2 := 0.0
var ult_kind := "thunder"
var ult_len := 3.65
var _cine := {}
var dash_kind := "shadow"
var dash_speed := 3.0
var _dash_hit := {}
var _step_idx := 0
var _footstep_t := 0.0
var ski_p: AudioStreamPlayer
var _ski_db := -60.0
var _rad_t := 0.0
var _nuke_fired := false
var core: Polygon2D
var ovl: Node2D
var ultimate_active := false
var ultimate_t := 0.0
var ultimate_used := false
const ULTIMATE_DURATION := 3.65
const FINISH_CUE_DELAY := 0.1
var ultimate_elapsed := 0.0
var ultimate_ghosts: Array[Node2D] = []
var ultimate_ghost_origins: Array[Vector2] = []
var ultimate_origin := Vector2.ZERO
var ultimate_strike_done := false
var ultimate_projectile_pos := Vector2.ZERO
var ultimate_projectile_start := Vector2.ZERO
var ultimate_projectile_launched := false
var _th_throw_played := false
var _th_strike_played := false
var _th_orb_played := false
var slide_t := 0.0
var jumps_left := 2
var coyote := 0.0
var buffer := 0.0
var dead := false
var god := false
var last_safe_x := 0.0
var spin_t := 0.0
var throw_t := 0.0
var hurt_t := 0.0
var phase := 0.0
var was_on_floor := true
var intro_t := 0.0
var ai := {"jump": false, "jump_release": false, "slide": false, "throw": false, "dash": false}
var use_ai := false

var col: CollisionShape2D
var pivot: Node2D
var body: Node2D
var torso: Polygon2D
var head: Polygon2D
var arm_a: Line2D
var arm_b: Line2D
var leg_a: Line2D
var leg_b: Line2D
var scarf: Line2D
var scarf_pts: Array = []
var katana: Line2D
var glow: PointLight2D
var rim: PointLight2D
var bubble: Node2D
var dust: CPUParticles2D
var sparks: CPUParticles2D
var eyes: Array = []
var occluder: LightOccluder2D
var aura_t := 0.0
var _afterimg_t := 0.0

var c_navy := Color("#3a4690")
var c_navy_l := Color("#5666b8")
var c_wrap := Color("#cfd4ea")
var c_red := Color("#d8323e")
var c_skin := Color("#e2b48e")
var eye_col := Color(1.8, 2.0, 2.2)
var glow_col := Color("#7aa8ff")
var trail_col := Color(0.4, 0.9, 1.0, 0.55)
var dust_col := Color(0.8, 0.8, 0.95)


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	z_index = 5
	floor_snap_length = 6.0
	col = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(10, 26)
	col.shape = rs
	col.position = Vector2(0, -13)
	add_child(col)
	ski_p = AudioStreamPlayer.new()
	ski_p.bus = "SFX"
	ski_p.volume_db = -60.0
	add_child(ski_p)
	set_character(GameState.selected)
	_build_rig()
	_build_fx()
	_apply_fx_colors()


func _mk_line(parent: Node, width: float, color: Color) -> Line2D:
	var l := Line2D.new()
	l.width = width
	l.default_color = color
	l.points = PackedVector2Array([Vector2.ZERO, Vector2(0, 5), Vector2(0, 10)])
	parent.add_child(l)
	return l


func _poly(parent: Node, pts: Array, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array(pts)
	p.color = color
	parent.add_child(p)
	return p


func _build_rig() -> void:
	pivot = Node2D.new()
	pivot.position = Vector2(0, -14)
	add_child(pivot)
	body = Node2D.new()
	body.position = Vector2(0, 14)
	pivot.add_child(body)

	arm_b = _mk_line(body, 3.0, c_navy.darkened(0.25))
	leg_b = _mk_line(body, 3.4, c_navy.darkened(0.3))
	katana = Line2D.new()
	katana.width = 1.6
	katana.default_color = Color("#aab4d0")
	katana.points = PackedVector2Array([Vector2(-1, -21), Vector2(-9, -35)])
	body.add_child(katana)
	var handle := Line2D.new()
	handle.width = 2.0
	handle.default_color = Color("#3a2030")
	handle.points = PackedVector2Array([Vector2(-1, -21), Vector2(2, -17)])
	body.add_child(handle)

	torso = _poly(body, [Vector2(-4, -23), Vector2(3.5, -23), Vector2(3, -12), Vector2(-3.5, -12)], c_navy)
	_poly(body, [Vector2(-4, -23), Vector2(-1, -23), Vector2(-1, -12), Vector2(-3.5, -12)], c_navy.darkened(0.25))
	_poly(body, [Vector2(-3.6, -13.5), Vector2(3.1, -13.5), Vector2(3.1, -11.5), Vector2(-3.6, -11.5)], c_red)
	_poly(body, [Vector2(0.5, -22), Vector2(3, -22), Vector2(3, -15), Vector2(1.5, -15)], c_navy_l)

	leg_a = _mk_line(body, 3.4, c_navy)
	head = _poly(body, [Vector2(-4.5, -28), Vector2(-2, -31), Vector2(2, -31), Vector2(4.5, -28), Vector2(4.5, -24), Vector2(2, -22), Vector2(-2, -22), Vector2(-4.5, -24)], c_navy)
	_poly(body, [Vector2(0.5, -27.5), Vector2(4.5, -27.5), Vector2(4.5, -25), Vector2(0.5, -25)], c_skin)
	_poly(body, [Vector2(-4.5, -29.5), Vector2(4.5, -29.5), Vector2(4.5, -28), Vector2(-4.5, -28)], c_red)
	var em := CanvasItemMaterial.new()
	em.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	for ex in [1.4, 3.2]:
		var e := _poly(body, [Vector2(ex, -27.2), Vector2(ex + 1.1, -27.2), Vector2(ex + 1.1, -26), Vector2(ex, -26)], eye_col)
		e.material = em
		eyes.append(e)
	arm_a = _mk_line(body, 3.0, c_navy)

	for l in [arm_a, arm_b, leg_a, leg_b]:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.48, 0.52, 1.0])
		var base: Color = (l as Line2D).default_color
		g.colors = PackedColorArray([base, base, c_wrap.darkened(0.15), c_wrap.darkened(0.15)])
		(l as Line2D).gradient = g

	scarf = Line2D.new()
	scarf.top_level = true
	scarf.width = 3.0
	scarf.default_color = c_red
	var sg := Gradient.new()
	sg.colors = PackedColorArray([c_red.lightened(0.1), c_red.darkened(0.25)])
	scarf.gradient = sg
	scarf.z_index = 4
	add_child(scarf)
	for i in 9:
		scarf_pts.append(global_position + Vector2(-3 - i * 3, -27))

	occluder = LightOccluder2D.new()
	var op := OccluderPolygon2D.new()
	op.polygon = PackedVector2Array([Vector2(-4, 0), Vector2(4, 0), Vector2(4, -26), Vector2(-4, -26)])
	occluder.occluder = op
	occluder.occluder_light_mask = 3
	add_child(occluder)
	_build_extras()


func _build_extras() -> void:
	core = null
	ovl = null
	if String(cdata.get("extras", "")) == "demonlord":
		_build_demonlord()
		return
	if String(cdata.get("extras", "")) != "overlord":
		return
	var dark := c_navy.darkened(0.15)
	_poly(body, [Vector2(-3.2, -29.5), Vector2(-6.5, -38.0), Vector2(-1.2, -30.5)], dark)
	_poly(body, [Vector2(-5.4, -35.2), Vector2(-6.5, -38.0), Vector2(-4.3, -36.4)], c_red)
	_poly(body, [Vector2(2.0, -29.5), Vector2(7.0, -38.5), Vector2(4.5, -29.5)], dark)
	_poly(body, [Vector2(5.6, -35.4), Vector2(7.0, -38.5), Vector2(6.3, -34.2)], c_red)
	_poly(body, [Vector2(-5.0, -22.5), Vector2(-10.0, -28.0), Vector2(-2.5, -23.5)], dark)
	_poly(body, [Vector2(-6.5, -21.0), Vector2(-12.0, -22.5), Vector2(-3.0, -19.5)], dark)
	_poly(body, [Vector2(-9.2, -27.2), Vector2(-10.0, -28.0), Vector2(-8.4, -26.4)], c_red)
	_poly(body, [Vector2(0.5, -25.5), Vector2(4.5, -25.5), Vector2(4.5, -22.8), Vector2(0.5, -22.8)], Color("#c9c4b8"))
	core = _poly(body, [Vector2(0, -20.5), Vector2(2.6, -17.5), Vector2(0, -14.5), Vector2(-2.6, -17.5)], Color(0.75, 1.0, 0.25))
	core.material = Fx.add_mat()
	core.z_index = 1
	ovl = Node2D.new()
	ovl.position = Vector2(-0.5, -18.0)
	ovl.z_index = -1
	ovl.material = Fx.add_mat()
	body.add_child(ovl)
	ovl.draw.connect(_draw_overlord)


func _build_demonlord() -> void:
	var dark := Color("#0b0614")
	var gold := c_red
	_poly(body, [Vector2(-3.4, -29.6), Vector2(-7.6, -33.2), Vector2(-9.6, -40.8), Vector2(-5.2, -34.4), Vector2(-1.6, -30.4)], dark)
	_poly(body, [Vector2(-8.4, -36.0), Vector2(-9.6, -40.8), Vector2(-6.6, -37.0)], gold)
	_poly(body, [Vector2(2.4, -29.6), Vector2(7.2, -33.6), Vector2(9.8, -41.8), Vector2(5.2, -34.8), Vector2(4.6, -30.0)], dark)
	_poly(body, [Vector2(8.0, -36.4), Vector2(9.8, -41.8), Vector2(6.8, -37.2)], gold)
	_poly(body, [Vector2(-5.0, -22.5), Vector2(-11.0, -29.0), Vector2(-2.5, -23.5)], dark)
	_poly(body, [Vector2(-6.5, -21.0), Vector2(-13.0, -23.0), Vector2(-3.0, -19.5)], dark)
	_poly(body, [Vector2(-10.2, -28.2), Vector2(-11.0, -29.0), Vector2(-9.2, -27.4)], gold)
	_poly(body, [Vector2(0.5, -25.5), Vector2(4.5, -25.5), Vector2(4.5, -22.8), Vector2(0.5, -22.8)], Color("#d8c690"))
	core = _poly(body, [Vector2(0, -20.8), Vector2(2.8, -17.5), Vector2(0, -14.2), Vector2(-2.8, -17.5)], Color(1.0, 0.82, 0.3))
	core.material = Fx.add_mat()
	core.z_index = 1
	_poly(body, [Vector2(0, -19.0), Vector2(1.2, -17.5), Vector2(0, -16.0), Vector2(-1.2, -17.5)], Color(0.1, 0.0, 0.2))
	ovl = Node2D.new()
	ovl.position = Vector2(-0.5, -18.0)
	ovl.z_index = -1
	ovl.material = Fx.add_mat()
	body.add_child(ovl)
	ovl.draw.connect(_draw_demonlord)
	var specs := [
		[Color(1.0, 0.84, 0.36, 0.9), true, 16, 11.0, "spark"],
		[Color(0.65, 0.35, 1.0, 0.9), true, 16, 13.0, "spark"],
		[Color(0.08, 0.0, 0.16, 0.75), false, 8, 9.0, "orb"],
	]
	for sp in specs:
		var ps := CPUParticles2D.new()
		ps.local_coords = false
		ps.amount = int(sp[2])
		ps.lifetime = 1.1
		ps.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		ps.emission_sphere_radius = float(sp[3])
		ps.direction = Vector2.UP
		ps.spread = 35.0
		ps.gravity = Vector2(0, -26)
		ps.initial_velocity_min = 8.0
		ps.initial_velocity_max = 26.0
		ps.scale_amount_min = 0.6
		ps.scale_amount_max = 1.6 if not bool(sp[1]) else 1.2
		ps.texture = TexGen.shape_tex(String(sp[4]))
		var gr := Gradient.new()
		var cc: Color = sp[0]
		gr.set_color(0, cc)
		gr.set_color(1, Color(cc.r, cc.g, cc.b, 0.0))
		ps.color_ramp = gr
		ps.material = Fx.add_mat() if bool(sp[1]) else Fx.unshaded_mat()
		ps.position = Vector2(0, -16)
		ps.z_index = -1
		body.add_child(ps)
		ps.emitting = true


func _draw_demonlord() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var gt := TexGen.glow_tex(64)
	var pul := 0.5 + 0.5 * sin(t * 5.0)
	ovl.draw_texture_rect(gt, Rect2(Vector2(-40, -40), Vector2(80, 80)), false, Color(0.55, 0.25, 1.0, 0.30 + 0.08 * pul))
	ovl.draw_texture_rect(gt, Rect2(Vector2(-26, -26), Vector2(52, 52)), false, Color(1.0, 0.8, 0.3, 0.24))
	ovl.draw_arc(Vector2.ZERO, 26.0, t * 2.0, t * 2.0 + TAU * 0.7, 28, Color(0.75, 0.45, 1.0, 0.7), 1.4)
	ovl.draw_arc(Vector2.ZERO, 31.0, -t * 1.4, -t * 1.4 + TAU * 0.55, 28, Color(1.0, 0.84, 0.35, 0.7), 1.2)
	var hc := Vector2(0.5, -8.5)
	ovl.draw_arc(hc, 10.5, t * 1.2, t * 1.2 + TAU * 0.8, 20, Color(1.0, 0.84, 0.35, 0.9), 1.4)
	ovl.draw_arc(hc, 13.0, -t * 0.9, -t * 0.9 + TAU * 0.6, 20, Color(0.7, 0.4, 1.0, 0.8), 1.0)
	for i in 8:
		var a := t * 0.8 + float(i) * TAU / 8.0
		var d := Vector2(cos(a), sin(a))
		ovl.draw_line(d * 20.0, d * (28.0 + 4.0 * sin(t * 6.0 + float(i))), Color(1.0, 0.9, 0.5, 0.45) if i % 2 == 0 else Color(0.7, 0.4, 1.0, 0.5), 1.0)


func _draw_overlord() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	ovl.draw_circle(Vector2.ZERO, 27.0 + 2.0 * sin(t * 8.0), Color(0.55, 1.0, 0.2, 0.07))
	ovl.draw_circle(Vector2.ZERO, 18.0, Color(0.7, 1.0, 0.3, 0.07))
	ovl.draw_arc(Vector2.ZERO, 22.0, t * 2.0, t * 2.0 + TAU * 0.75, 24, Color(0.7, 1.0, 0.3, 0.6), 1.5)
	ovl.draw_arc(Vector2.ZERO, 28.0, -t * 1.5, -t * 1.5 + TAU * 0.6, 24, Color(1.0, 0.35, 0.15, 0.55), 1.2)
	for i in 8:
		var a := t * 0.8 + float(i) * TAU / 8.0
		var d := Vector2(cos(a), sin(a))
		ovl.draw_line(d * 18.0, d * (30.0 + 4.0 * sin(t * 6.0 + float(i))), Color(0.8, 1.0, 0.3, 0.5), 1.0)
	for k in 3:
		var a2 := -t * 1.2 + float(k) * TAU / 3.0
		var c := Vector2(cos(a2), sin(a2)) * 7.0
		ovl.draw_arc(c, 4.0, a2 - 0.9, a2 + 0.9, 8, Color(1.0, 0.9, 0.2, 0.6), 2.0)


func _build_fx() -> void:
	glow = PointLight2D.new()
	glow.texture = TexGen.light_tex(1.5)
	glow.texture_scale = 1.6
	glow.color = glow_col
	glow.energy = 0.45
	glow.position = Vector2(0, -16)
	glow.range_item_cull_mask = 1
	add_child(glow)

	bubble = Node2D.new()
	bubble.visible = false
	bubble.position = Vector2(0, -14)
	bubble.z_index = 8
	bubble.material = Fx.add_mat()
	add_child(bubble)
	bubble.draw.connect(_draw_bubble)

	dust = CPUParticles2D.new()
	dust.amount = 14
	dust.lifetime = 0.45
	dust.local_coords = false
	dust.direction = Vector2(-1, -0.4)
	dust.spread = 25.0
	dust.initial_velocity_min = 25.0
	dust.initial_velocity_max = 60.0
	dust.gravity = Vector2(0, -30)
	dust.scale_amount_min = 1.0
	dust.scale_amount_max = 2.2
	dust.texture = TexGen.shape_tex("dust")
	var r := Gradient.new()
	r.set_color(0, Color(0.8, 0.8, 0.95, 0.55))
	r.set_color(1, Color(0.8, 0.8, 0.95, 0.0))
	dust.color_ramp = r
	dust.material = Fx.unshaded_mat()
	dust.position = Vector2(-2, 0)
	dust.z_index = 3
	dust.emitting = false
	add_child(dust)

	sparks = CPUParticles2D.new()
	sparks.amount = 18
	sparks.lifetime = 0.3
	sparks.local_coords = false
	sparks.direction = Vector2(-1, -0.6)
	sparks.spread = 35.0
	sparks.initial_velocity_min = 50.0
	sparks.initial_velocity_max = 120.0
	sparks.gravity = Vector2(0, 280)
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 1.6
	sparks.texture = TexGen.shape_tex("spark")
	var r2 := Gradient.new()
	r2.set_color(0, Color(1.0, 0.8, 0.35, 1.0))
	r2.set_color(1, Color(1.0, 0.3, 0.1, 0.0))
	sparks.color_ramp = r2
	sparks.material = Fx.add_mat()
	sparks.position = Vector2(4, -1)
	sparks.z_index = 7
	sparks.emitting = false
	add_child(sparks)


func _draw_bubble() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var pulse := 1.0 + sin(t * 6.0) * 0.04
	bubble.draw_circle(Vector2.ZERO, 19.0 * pulse, Color(0.3, 0.8, 1.0, 0.10))
	bubble.draw_arc(Vector2.ZERO, 19.0 * pulse, 0, TAU, 28, Color(0.5, 0.9, 1.0, 0.7), 1.5)
	bubble.draw_arc(Vector2.ZERO, 16.0 * pulse, -2.4, -1.0, 8, Color(1, 1, 1, 0.7), 1.0)


func cancel_ultimate() -> void:
	ultimate_active = false
	ultimate_t = 0.0
	ultimate_elapsed = 0.0
	ultimate_strike_done = false
	ultimate_projectile_launched = false
	_cine.clear()
	for ghost in ultimate_ghosts:
		if is_instance_valid(ghost):
			ghost.queue_free()
	ultimate_ghosts.clear()
	ultimate_ghost_origins.clear()
	shadow_attack_active = false
	modulate = Color.WHITE
	if pivot != null:
		pivot.position = Vector2(0, -14)
		pivot.rotation = 0.0
		pivot.scale = Vector2.ONE
		pivot.modulate = Color.WHITE
	if katana != null:
		katana.width = 2.0


func reset_for_run(spawn: Vector2) -> void:
	cancel_ultimate()
	if char_id != GameState.selected:
		set_character(GameState.selected)
	dead = false
	position = spawn
	velocity = Vector2.ZERO
	max_hearts = GameState.max_hearts() + int(cdata.get("bonus_hearts", 0))
	hearts = max_hearts
	invuln = 1.0
	shield = GameState.upgrade_level("ward") > 0 or bool(cdata.get("start_shield", false))
	_nuke_fired = false
	_rad_t = 0.0
	star_t = 0.0
	magnet_t = 0.0
	ammo = GameState.max_ammo()
	ammo_timer = 0.0
	dash_cd = 0.0
	dash_t = 0.0
	shadow_attack_cd = 0.0
	shadow_attack_active = false
	ult_mode_t = 0.0
	ult_acc = 0.0
	ult_cd = GameState.ulti_cooldown() * float(cdata.get("ult_start", Characters.ULTI_START_FRACTION))
	slide_t = 0.0
	spin_t = 0.0
	jumps_left = 2
	visible = true
	last_safe_x = spawn.x
	for i in scarf_pts.size():
		scarf_pts[i] = global_position + Vector2(-3 - i * 3, -27)
	hearts_changed.emit()


func _act(name: String) -> bool:
	if use_ai:
		return bool(ai.get(name, false))
	return Input.is_action_just_pressed(name)


func _act_released(name: String) -> bool:
	if use_ai:
		return bool(ai.get(name + "_release", false))
	return Input.is_action_just_released(name)


func _physics_process(delta: float) -> void:
	if dead or world == null:
		return
	var floor_now := is_on_floor()
	invuln = maxf(0.0, invuln - delta)
	star_t = maxf(0.0, star_t - delta)
	magnet_t = maxf(0.0, magnet_t - delta)
	dash_cd = maxf(0.0, dash_cd - delta)
	shadow_attack_cd = maxf(0.0, shadow_attack_cd - delta)
	if not ultimate_active and ult_mode_t <= 0.0:
		var previous_ult_cd := ult_cd
		ult_cd = maxf(0.0, ult_cd - delta)
		if ult_cd > 0.0 and ult_cd <= 2.0 and previous_ult_cd > 2.0 and not _ult_charge_sound_played:
			Sfx.play("skill_recharge", 0.9, -5.0)
			_ult_charge_sound_played = true
		if ult_cd <= 0.0 and previous_ult_cd > 0.0 and not _ult_ready_sound_played:
			Sfx.play("skill_ready", 1.0, -3.0)
			_ult_ready_sound_played = true
	throw_t = maxf(0.0, throw_t - delta)
	hurt_t = maxf(0.0, hurt_t - delta)
	buffer = maxf(0.0, buffer - delta)
	coyote = maxf(0.0, coyote - delta)
	if floor_now:
		coyote = COYOTE
		jumps_left = 2
		if global_position.y > Ground.GROUND_Y - 3.0:
			last_safe_x = global_position.x
	if ammo < GameState.max_ammo():
		ammo_timer += delta
		if ammo_timer >= Characters.SHURIKEN_RECHARGE:
			ammo_timer = 0.0
			ammo += 1
	var passive := String(cdata.get("passive", ""))
	if passive == "radiation" or passive == "eclipse":
		_rad_t -= delta
		if _rad_t <= 0.0:
			if passive == "radiation":
				_rad_t = 0.3
				Skills.radiation_pulse(self)
			else:
				_rad_t = 0.22
				Skills.eclipse_pulse(self)
	if world.demo:
		god = true

	if _act("jump"):
		buffer = BUFFER
	if _act("throw"):
		throw_shuriken()
	if _act("ultimate") and not ultimate_active and ult_mode_t <= 0.0 and ult_cd <= 0.0:
		start_ultimate()
	if _act("shadow_attack") and shadow_attack_cd <= 0.0 and not shadow_attack_active and not ultimate_active:
		start_special()
	if _act("dash") and dash_cd <= 0.0 and dash_t <= 0.0:
		start_dash()
	if _act("slide"):
		if floor_now:
			start_slide()
		else:
			velocity.y = maxf(velocity.y, 720.0)
	if buffer > 0.0:
		if floor_now or coyote > 0.0:
			do_jump(JUMP_V * jump_mult, false)
		elif jumps_left > 0:
			do_jump(DJUMP_V * jump_mult, true)
	if _act_released("jump") and velocity.y < -220.0 and spin_t <= 0.0:
		velocity.y *= 0.55

	if ultimate_active:
		_update_ultimate(delta)
		return
	if shadow_attack_active:
		_update_shadow_attack(delta)
		return

	var target := run_speed * speed_mult * (1.18 if star_t > 0.0 else 1.0)
	if ult_mode_t > 0.0 and ult_mode_kind == "storm":
		target = run_speed * speed_mult * 1.9
	if dash_t > 0.0:
		dash_t -= delta
		target = run_speed * speed_mult * dash_speed
		_afterimg_t -= delta
		if _afterimg_t <= 0.0:
			_afterimg_t = 0.03
			_spawn_afterimage()
			Skills.dash_tick(self, dash_kind)
		if dash_t <= 0.0:
			velocity.y = minf(velocity.y, 0.0)
	elif slide_t > 0.0:
		target = run_speed * 1.15
	velocity.x = lerpf(velocity.x, target, minf(1.0, delta * 14.0))
	if intro_t > 0.0:
		intro_t -= delta

	if dash_t > 0.0:
		velocity.y = 0.0
	else:
		velocity.y += GRAVITY * grav_mult * delta
		velocity.y = minf(velocity.y, 900.0)

	if slide_t > 0.0:
		slide_t -= delta
		if slide_t <= 0.0 or not floor_now:
			end_slide()
		else:
			sparks.emitting = true
	else:
		sparks.emitting = false

	move_and_slide()

	_update_ski_sound(delta)

	if char_id != "kori" and is_on_floor() and not ultimate_active and slide_t <= 0.0 and dash_t <= 0.0 and absf(velocity.x) > 70.0:
		_footstep_t -= delta
		if _footstep_t <= 0.0:
			_footstep_t = 0.31 if (char_id == "kakuou" or char_id == "maou") else (0.22 if char_id == "hayate" else 0.26)
			Sfx.play("step_" + char_id, randf_range(0.96, 1.04), -10.0 if (char_id != "kakuou" and char_id != "maou") else -7.0)
	else:
		_footstep_t = minf(_footstep_t, 0.06)

	if is_on_floor() and not was_on_floor:
		Sfx.play("land_" + char_id, 1.0, -8.0)
		Fx.burst(world.fx_root, global_position + Vector2(0, -1), Color(0.8, 0.8, 0.95, 0.7), 8, 45.0, 0.4, -10.0, "dust", false, 160.0, Vector2.UP, 2.0)
		spin_t = 0.0
	was_on_floor = is_on_floor()
	dust.emitting = is_on_floor() and slide_t <= 0.0

	if global_position.y > Ground.GROUND_Y + 56.0:
		world.player_fell(self)

	glow.energy = 0.85 + (0.35 * (0.5 + 0.5 * sin(aura_t * 12.0)) if star_t > 0.0 else 0.0)
	glow.color = Color.from_hsv(fposmod(aura_t * 1.5, 1.0), 0.6, 1.0) if star_t > 0.0 else glow_col
	glow.texture_scale = 2.4 if star_t > 0.0 else 1.6
	bubble.visible = shield and not ultimate_active
	if shield:
		bubble.queue_redraw()
	modulate.a = 1.0
	if invuln > 0.0 and not god and ult_mode_t <= 0.0:
		modulate.a = 0.35 if int(invuln * 18.0) % 2 == 0 else 1.0
	if star_t > 0.0:
		modulate = Color.from_hsv(fposmod(aura_t * 2.0, 1.0), 0.35, 1.4)
	elif ult_mode_t > 0.0:
		match ult_mode_kind:
			"storm": modulate = Color(0.85, 1.3, 1.0)
			"meteor": modulate = Color(1.35, 0.95, 0.75)
			_: modulate = Color(0.9, 1.15, 1.4)
	else:
		modulate.r = 1.0
		modulate.g = 1.0
		modulate.b = 1.0


func _process(delta: float) -> void:
	if world == null:
		return
	aura_t += delta
	if is_instance_valid(core):
		core.modulate.a = 0.7 + 0.3 * sin(aura_t * 7.0)
	if is_instance_valid(ovl):
		ovl.queue_redraw()
	if not ultimate_active:
		_animate(delta)
		_update_scarf(delta)


func do_jump(v: float, double: bool) -> void:
	buffer = 0.0
	coyote = 0.0
	if slide_t > 0.0:
		end_slide()
	velocity.y = v
	if double:
		jumps_left -= 1
		spin_t = 0.38
		Sfx.play("djump_" + char_id, 1.0, -3.0)
		Fx.ring(world.fx_root, global_position + Vector2(0, -6), Color(0.8, 0.95, 1.0, 0.9), 3.0, 18.0, 0.3, 2.0)
		Fx.burst(world.fx_root, global_position + Vector2(0, -4), Color(1, 1, 1, 0.9), 8, 60.0, 0.35, 40.0, "orb", false, 360.0, Vector2.DOWN, 1.6)
	else:
		jumps_left -= 1
		Sfx.play("jump_" + char_id, 1.0, -4.0)
		Fx.burst(world.fx_root, global_position + Vector2(0, -1), Color(0.85, 0.85, 1.0, 0.8), 6, 40.0, 0.35, -10.0, "dust", false, 120.0, Vector2.UP, 2.0)


func start_slide() -> void:
	if slide_t > 0.0:
		return
	slide_t = SLIDE_TIME
	var rs := col.shape as RectangleShape2D
	rs.size = Vector2(12, 11)
	col.position = Vector2(0, -5.5)
	Sfx.play("slide_" + char_id, 1.0, -5.0)


func end_slide() -> void:
	slide_t = 0.0
	var rs := col.shape as RectangleShape2D
	rs.size = Vector2(10, 26)
	col.position = Vector2(0, -13)


func start_dash() -> void:
	var d: Dictionary = skills["dash"]
	var dur := float(d["time"])
	dash_kind = String(d["kind"])
	dash_speed = float(d["speed"])
	dash_t = dur
	dash_cd = GameState.dash_cooldown()
	invuln = maxf(invuln, dur + 0.12)
	if slide_t > 0.0:
		end_slide()
	world.dash_fx(true)
	Fx.slash(world.fx_root, global_position + Vector2(18, -14), trail_col.lightened(0.3), 28.0)
	Skills.dash_begin(self, dash_kind)


func set_character(id: String) -> void:
	char_id = id
	cdata = Characters.get_def(id)
	skills = cdata["skills"]
	var pal: Dictionary = cdata["pal"]
	c_navy = pal["navy"]
	c_navy_l = pal["navy_l"]
	c_wrap = pal["wrap"]
	c_red = pal["red"]
	c_skin = pal["skin"]
	eye_col = pal["eye"]
	glow_col = pal["glow"]
	trail_col = pal["trail"]
	dust_col = pal["dust"]
	run_style = String(cdata["run_style"])
	speed_mult = float(cdata["speed"])
	jump_mult = float(cdata["jump"])
	grav_mult = float(cdata["gravity"])
	dash_kind = String(skills["dash"]["kind"])
	dash_speed = float(skills["dash"]["speed"])
	if pivot != null:
		_rebuild_rig()
		_apply_fx_colors()


func _rebuild_rig() -> void:
	for n in [pivot, scarf, occluder]:
		if is_instance_valid(n):
			(n as Node).queue_free()
	eyes.clear()
	scarf_pts.clear()
	_build_rig()


func _apply_fx_colors() -> void:
	if glow != null:
		glow.color = glow_col
	if dust != null:
		var r := Gradient.new()
		r.set_color(0, Color(dust_col.r, dust_col.g, dust_col.b, 0.55))
		r.set_color(1, Color(dust_col.r, dust_col.g, dust_col.b, 0.0))
		dust.color_ramp = r


func start_special() -> void:
	var kind := String(skills["special"]["kind"])
	if kind == "shadow":
		start_shadow_attack()
	else:
		Skills.special(self, kind)


func cd_left(slot: String) -> float:
	match slot:
		"dash": return dash_cd
		"special": return shadow_attack_cd
		"ultimate": return ult_cd
	return 0.0


func cd_total(slot: String) -> float:
	match slot:
		"dash": return GameState.dash_cooldown()
		"special": return GameState.special_cooldown()
		"ultimate": return GameState.ulti_cooldown()
	return 1.0


func ult_active_left() -> float:
	if ultimate_active:
		return ultimate_t
	return maxf(0.0, ult_mode_t)


func start_shadow_attack() -> void:
	if world == null or shadow_attack_active:
		return
	shadow_targets.clear()
	var candidates: Array[Hazard] = []
	for node in world.ent_root.get_children():
		if node is Hazard and not (node is Spikes) and not (node is Strike):
			var h := node as Hazard
			if not h.dying and h.hp > 0 and h.global_position.x > global_position.x - 36.0 and h.global_position.x < global_position.x + 310.0:
				candidates.append(h)
	candidates.sort_custom(func(a: Hazard, b: Hazard) -> bool: return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position))
	for i in mini(3 + GameState.upgrade_level("unique"), candidates.size()):
		shadow_targets.append(candidates[i])
	if shadow_targets.is_empty():
		shadow_origin = global_position
		shadow_attack_active = true
		shadow_attack_t = 0.18
		shadow_target_index = 0
	else:
		shadow_attack_active = true
		shadow_attack_t = 0.14
		shadow_step_t = 0.0
		shadow_target_index = 0
	shadow_attack_cd = GameState.special_cooldown()
	invuln = maxf(invuln, 1.1)
	velocity = Vector2.ZERO
	if slide_t > 0.0: end_slide()
	modulate = Color(0.42, 0.25, 0.9, 0.65)
	Sfx.play("shadow_dash", 1.0, -2.0)
	world.dash_fx(true)
	Fx.ring(world.fx_root, global_position + Vector2(0, -12), Color(0.55, 0.35, 1.0, 0.95), 4.0, 36.0, 0.28, 4.0)


func _update_shadow_attack(delta: float) -> void:
	shadow_attack_t -= delta
	shadow_step_t -= delta
	velocity = Vector2.ZERO
	invuln = maxf(invuln, 0.08)
	_afterimg_t -= delta
	if _afterimg_t <= 0.0:
		_afterimg_t = 0.025
		_spawn_afterimage()
	if shadow_target_index < shadow_targets.size() and shadow_step_t <= 0.0:
		var target := shadow_targets[shadow_target_index]
		if is_instance_valid(target) and not target.dying:
			var from := global_position
			global_position = target.global_position + Vector2(-14.0, -2.0)
			Fx.slash(world.fx_root, from + Vector2(10, -15), Color(0.45, 0.25, 1.0, 0.95), 34.0)
			Fx.bolt(world.fx_root, from + Vector2(0, -14), target.global_position + Vector2(0, -12), Color(0.55, 0.35, 1.0, 0.95))
			Fx.burst(world.fx_root, target.global_position, Color("#b56cff"), 28, 210.0, 0.42, -25.0, "spark", true, 360.0, Vector2.UP, 3.0)
			Fx.burst(world.fx_root, target.global_position, Color("#e9fbff"), 12, 115.0, 0.3, 20.0, "orb", true, 360.0, Vector2.UP, 2.2)
			Fx.ring(world.fx_root, target.global_position, Color("#9a55ff", 0.95), 5.0, 52.0, 0.32, 4.0)
			world.shake(5.5, 0.18)
			target.kill("shadow_dash")
			shadow_attack_cd = maxf(0.0, shadow_attack_cd - 0.9)
			world.shake(2.5, 0.1)
		shadow_target_index += 1
		shadow_step_t = 0.075
	if shadow_target_index >= shadow_targets.size() and shadow_attack_t <= 0.0:
		var at := global_position + Vector2(18, -15)
		Fx.slash(world.fx_root, at, Color(0.8, 0.95, 1.0, 1.0), 40.0)
		var cross_slash := FxShape.new()
		cross_slash.kind = "slash"
		cross_slash.col = Color(0.65, 0.25, 1.0, 0.98)
		cross_slash.r0 = 28.0
		cross_slash.r1 = 40.0
		cross_slash.life = 0.24
		cross_slash.width = 5.0
		cross_slash.angle0 = -1.3
		cross_slash.angle1 = 1.3
		cross_slash.position = at
		cross_slash.rotation = PI * 0.5
		world.fx_root.add_child(cross_slash)
		Fx.ring(world.fx_root, at, Color(0.65, 0.35, 1.0, 0.9), 5.0, 42.0, 0.32, 4.0)
		shadow_attack_active = false
		modulate = Color.WHITE
		invuln = maxf(invuln, 0.12)
		world.dash_fx(false)
		Sfx.play("shadow_slash_finish", 1.0, -3.0)
		return
	if shadow_targets.is_empty() and shadow_attack_t <= 0.0:
		shadow_attack_active = false
		modulate = Color.WHITE
		world.dash_fx(false)

func start_ultimate() -> void:
	if world == null or ultimate_active or dead:
		return
	ult_kind = String(skills["ultimate"]["kind"])
	ult_len = float(skills["ultimate"].get("len", ULTIMATE_DURATION))
	ultimate_active = true
	ultimate_used = false
	ultimate_strike_done = false
	ultimate_projectile_launched = false
	_th_orb_played = false
	_th_throw_played = false
	_th_strike_played = false
	ultimate_t = ult_len
	ultimate_elapsed = 0.0
	ultimate_origin = global_position
	ultimate_ghosts.clear()
	ultimate_ghost_origins.clear()

	invuln = ult_len + 0.4
	velocity = Vector2.ZERO
	if slide_t > 0.0:
		end_slide()
	var charge_key := "ult_charge_thunder"
	match ult_kind:
		"storm": charge_key = "ult_charge_storm"
		"meteor": charge_key = "ult_charge_meteor"
		"blizzard": charge_key = "ult_charge_blizzard"
		"nuke": charge_key = "ult_charge_nuke"
		"worldend": charge_key = "ult_charge_worldend"
	Sfx.play(charge_key, 0.95 if ult_kind == "worldend" else 1.0, -2.0)
	if ult_kind == "worldend":
		Sfx.play_voice("ult_maou_voice", 1.0, 0.0)
		Sfx.play_ult_bgm("ult_maou_bgm", -6.0)
	_ult_charge_sound_played = false
	_ult_ready_sound_played = false
	world.ultimate_begin(ult_kind)
	if ult_kind != "thunder":
		_cine = {}
		Skills.cine_begin(self, ult_kind)
		return
	var ghost_colors: Array[Color] = [Color("#a66bff", 0.88), Color("#55eaff", 0.86), Color("#f4fbff", 0.82), Color("#8b4cff", 0.9)]
	for i in 4:
		var ghost := pivot.duplicate() as Node2D
		ghost.position = Vector2.ZERO
		ghost.rotation = 0.0
		ghost.scale = Vector2.ONE
		ghost.modulate = ghost_colors[i]
		ghost.z_index = 24 + i
		world.fx_root.add_child(ghost)
		ultimate_ghosts.append(ghost)
		ultimate_ghost_origins.append(ultimate_origin)
	Fx.ring(world.fx_root, ultimate_origin + Vector2(0, -14), Color("#b56cff", 0.95), 8.0, 76.0, 0.45, 4.0)
	Fx.burst(world.fx_root, ultimate_origin + Vector2(0, -16), Color("#b9f7ff"), 18, 90.0, 0.5, -10.0, "spark", true, 360.0, Vector2.UP, 2.5)
	world.big_flash(0.28)
	world.shake(3.5, 0.25)

func _update_ultimate(delta: float) -> void:
	var real_delta := delta / maxf(Engine.time_scale, 0.05)
	ultimate_elapsed += real_delta
	ultimate_t = maxf(0.0, ult_len - ultimate_elapsed)
	velocity = Vector2.ZERO
	invuln = maxf(invuln, 0.12)
	var t := ultimate_elapsed
	if ult_kind != "thunder":
		Skills.cine_update(self, delta, real_delta, t)
		if t >= ult_len:
			_finish_ultimate()
		return

	var jump_y := 0.0
	if t < 0.48:
		jump_y = -150.0 * sin(clampf(t / 0.48, 0.0, 1.0) * PI * 0.5)
		pivot.rotation = -PI * 2.0 * clampf(t / 0.48, 0.0, 1.0)
	elif t < 0.94:
		jump_y = -150.0 * cos(clampf((t - 0.48) / 0.46, 0.0, 1.0) * PI * 0.5)
		pivot.rotation = -PI * 2.0
	elif t < 1.42:
		var u := (t - 0.94) / 0.48
		jump_y = -190.0 * sin(u * PI)
		pivot.rotation = -PI * 2.0 - u * PI * 2.0
	elif t < 2.62:
		jump_y = -110.0 - sin((t - 1.42) * 4.0) * 18.0
		pivot.rotation = -PI * 4.0 - (t - 1.42) * 8.0
	else:
		var fall := clampf((t - 2.62) / 0.62, 0.0, 1.0)
		jump_y = lerpf(-110.0, 0.0, fall)
		pivot.rotation = -PI * 4.0 - (2.62 - 1.42) * 8.0 + fall * 0.22
	pivot.position = Vector2(0, -14.0 + jump_y)

	if t >= 0.92 - Skills.audio_lead() and not _th_orb_played:
		_th_orb_played = true
		Sfx.play("ult_thunder_orb", 1.0, -1.0)
	var charge := clampf((t - 0.92) / 1.15, 0.0, 1.0)
	_limb(arm_a, Vector2(-2.0, -20.0), -2.2, 0.12)
	_limb(arm_b, Vector2(3.0, -20.0), lerpf(-1.0, -2.75, charge), 0.08)
	_limb(leg_a, Vector2(-2.0, -9.0), 1.6 + sin(t * 12.0) * 0.3, -0.2)
	_limb(leg_b, Vector2(2.0, -9.0), 1.2 - sin(t * 12.0) * 0.3, -0.1)
	katana.default_color = Color("#e8fbff")
	katana.width = 3.8

	for i in ultimate_ghosts.size():
		var ghost := ultimate_ghosts[i]
		if not is_instance_valid(ghost):
			continue
		var open := smoothstep(0.5, 1.45, t)
		var form: Array[Vector2] = [Vector2(-128.0, -6.0), Vector2(128.0, -6.0), Vector2(0.0, -96.0), Vector2(0.0, 60.0)]
		var sa := t * 5.0 + float(i) * PI * 0.5
		var spiral := Vector2(cos(sa), sin(sa) * 0.6) * lerpf(34.0, 70.0, minf(1.0, t / 0.9))
		var target: Vector2 = form[i] + Vector2(0.0, sin(t * 3.0 + float(i)) * 4.0)
		ghost.global_position = ultimate_origin + spiral.lerp(target, open) + Vector2(0, -14 + jump_y)
		ghost.rotation = lerpf(pivot.rotation + float(i) * 0.16, 0.0, open)
		ghost.modulate.a = 0.72 if t < 2.5 else clampf(1.0 - (t - 2.5) / 0.5, 0.0, 0.72)
		if int(t * 16.0) != int((t - real_delta) * 16.0):
			Fx.bolt(world.fx_root, ghost.global_position + Vector2(-8, -12), global_position + Vector2(0, jump_y - 25), Color("#72eaff", 0.62))

	var hand := global_position + Vector2(16, jump_y - 38)
	if t >= 0.92 and t < 2.62:
		var pulse := 1.0 + 0.22 * sin(t * 19.0)
		Fx.ring(world.fx_root, hand, Color("#6ceaff", 0.72), 4.0, 18.0 * pulse, 0.20, 2.0)
		if int(t * 12.0) != int((t - real_delta) * 12.0):
			Fx.bolt(world.fx_root, hand + Vector2(randf_range(-12, 12), randf_range(-12, 12)), hand + Vector2(randf_range(-5, 5), randf_range(-5, 5)), Color("#d8fbff", 1.0))
		if int(t * 8.0) != int((t - real_delta) * 8.0):
			Fx.burst(world.fx_root, hand, Color("#83eaff"), 5, 65.0, 0.24, -20.0, "spark", true, 360.0, Vector2.UP, 1.8)

	if t >= 2.62 - Skills.audio_lead() and not _th_throw_played:
		_th_throw_played = true
		Sfx.play("ult_thunder_throw", 1.0, -1.0)
	if t >= 3.18 - Skills.audio_lead() and not _th_strike_played:
		_th_strike_played = true
		Sfx.play("ult_thunder_crack", 1.0, -2.0)
		Sfx.play("ult_impact_thunder", 0.95, -1.0)
	if t >= 2.62 and not ultimate_projectile_launched:
		ultimate_projectile_launched = true
		ultimate_projectile_start = hand
		ultimate_projectile_pos = hand
	if ultimate_projectile_launched and t < 3.18:
		var f := clampf((t - 2.62) / 0.56, 0.0, 1.0)
		ultimate_projectile_pos = ultimate_projectile_start.lerp(Vector2(global_position.x + 20, Ground.GROUND_Y - 12), f * f)
		Fx.ring(world.fx_root, ultimate_projectile_pos, Color("#baf7ff", 0.9), 5.0, 24.0 + 10.0 * sin(t * 28.0), 0.16, 3.0)
		Fx.burst(world.fx_root, ultimate_projectile_pos, Color("#d8fbff"), 3, 48.0, 0.18, 0.0, "spark", true, 360.0, Vector2.UP, 1.8)

	if t >= 3.18 and not ultimate_strike_done:
		ultimate_strike_done = true
		world.ultimate_strike()
		for ghost in ultimate_ghosts:
			if is_instance_valid(ghost): ghost.queue_free()
		ultimate_ghosts.clear()
		Fx.ring(world.fx_root, Vector2(global_position.x + 20, Ground.GROUND_Y - 12), Color("#f0fdff"), 12.0, 270.0, 0.48, 8.0)
		Fx.ring(world.fx_root, Vector2(global_position.x + 20, Ground.GROUND_Y - 12), Color("#6ceaff"), 8.0, 330.0, 0.62, 5.0)
		Fx.burst(world.fx_root, Vector2(global_position.x + 20, Ground.GROUND_Y - 12), Color("#c9faff"), 90, 330.0, 0.72, -45.0, "spark", true, 360.0, Vector2.UP, 4.0)
		world.big_flash(0.75)
		world.shake(24.0, 0.85)
	if t >= ult_len:
		_finish_ultimate()


func _finish_ultimate() -> void:
	if ult_kind == "worldend":
		_finish_worldend()
		return
	if ult_kind != "thunder":
		Skills.cine_end(self)
	if ult_kind != "nuke":
		var finish_key := "ult_finish_thunder"
		match ult_kind:
			"storm": finish_key = "ult_finish_storm"
			"meteor": finish_key = "ult_finish_meteor"
			"blizzard": finish_key = "ult_finish_blizzard"
		get_tree().create_timer(FINISH_CUE_DELAY).timeout.connect(func(): Sfx.play(finish_key, 0.9, -2.0))
	ultimate_active = false
	ult_cd = GameState.ulti_cooldown()
	modulate = Color.WHITE
	pivot.position = Vector2(0, -14)
	pivot.rotation = 0.0
	katana.width = 2.0
	for ghost in ultimate_ghosts:
		if is_instance_valid(ghost):
			ghost.queue_free()
	ultimate_ghosts.clear()
	world.ultimate_end()

func _finish_worldend() -> void:
	Skills.cine_end(self)
	ultimate_active = false
	Sfx.stop_ult_bgm(0.35, 1.8)
	if world != null and world.demo:
		cancel_ultimate()
		world.ultimate_end()
		return
	dead = true
	visible = false
	scarf.visible = false
	modulate = Color.WHITE
	pivot.position = Vector2(0, -14)
	pivot.rotation = 0.0
	for ghost in ultimate_ghosts:
		if is_instance_valid(ghost):
			ghost.queue_free()
	ultimate_ghosts.clear()
	world.ultimate_end()
	world.finish_world_end()


func throw_shuriken() -> void:
	if ammo <= 0 or throw_t > 0.12:
		return
	ammo -= 1
	throw_t = 0.2
	world.spawn_shuriken(global_position + Vector2(8, -17))
	Sfx.play("throw_" + char_id, 1.0, -4.0)


func bounce(v: float = -400.0) -> void:
	velocity.y = v
	jumps_left = maxi(jumps_left, 1)
	spin_t = 0.0
	Sfx.play("jump_" + char_id, 1.15, -3.0)


func hazard_contact(h: Hazard) -> void:
	if dead or h.dying:
		return
	if shadow_attack_active:
		return
	if ult_mode_t > 0.0:
		if h.shurikenable and h.hp > 0:
			Fx.burst(world.fx_root, h.global_position + Vector2(0, -10), trail_col.lightened(0.3), 10, 140.0, 0.35, 80.0, "spark", true, 360.0, Vector2.UP, 2.0)
			h.kill("ultimate")
		return
	if dash_t > 0.0 and h.hp > 0 and not (h is Spikes) and not (h is Strike):
		h.take_damage(1, "dash")
		return
	var feet := global_position.y
	var falling := velocity.y > 40.0
	if falling and feet < h.top_y() + 9.0:
		if h.stompable:
			h.take_damage(1, "stomp")
			bounce(-390.0)
			return
		if h.bouncy:
			bounce(-600.0)
			Fx.ring(world.fx_root, h.global_position + Vector2(0, -18), Color(1, 0.9, 0.5, 0.9), 3.0, 16.0, 0.25)
			Sfx.play("powerup", 1.5, -8.0)
			return
	if invuln > 0.0 or star_t > 0.0:
		if star_t > 0.0 and h.hp > 0 and not (h is Spikes) and not (h is Strike):
			h.kill("star")
		return
	take_hit(h.global_position)


func take_hit(src: Vector2) -> void:
	if dead:
		return
	if shield:
		shield = false
		invuln = 1.0
		Sfx.play("shield", 0.7)
		Fx.ring(world.fx_root, global_position + Vector2(0, -14), Color(0.5, 0.9, 1.0), 10.0, 40.0, 0.35, 3.0)
		Fx.burst(world.fx_root, global_position + Vector2(0, -14), Color(0.5, 0.9, 1.0), 14, 120.0, 0.4, 100.0)
		world.shake(3.0, 0.2)
		return
	if god:
		invuln = 0.8
		return
	hearts -= 1
	invuln = 1.6
	hurt_t = 0.5
	velocity.y = -330.0
	hearts_changed.emit()
	world.on_player_hurt(src)
	if hearts <= 0:
		die()


func heal(n: int = 1) -> void:
	hearts = mini(max_hearts, hearts + n)
	hearts_changed.emit()


func _update_ski_sound(delta: float) -> void:
	if ski_p == null:
		return
	var want := char_id == "kori" and not use_ai and not dead and is_on_floor() and not ultimate_active \
		and slide_t <= 0.0 and dash_t <= 0.0 and absf(velocity.x) > 70.0
	var target := -8.0 if want else -60.0
	_ski_db = move_toward(_ski_db, target, (90.0 if want else 140.0) * delta)
	if _ski_db <= -48.0:
		if ski_p.playing:
			ski_p.stop()
		return
	if not ski_p.playing:
		ski_p.stream = Assets.ski_loop()
		ski_p.play(randf() * 0.5)
	ski_p.volume_db = _ski_db
	ski_p.pitch_scale = clampf(0.86 + absf(velocity.x) / 700.0, 0.9, 1.3)


func die() -> void:
	if dead:
		return
	dead = true
	if ski_p:
		ski_p.stop()
	visible = false
	scarf.visible = false
	Fx.smoke(world.fx_root, global_position + Vector2(0, -14), Color(0.3, 0.3, 0.55, 0.9))
	Fx.burst(world.fx_root, global_position + Vector2(0, -14), Color(0.9, 0.2, 0.3), 20, 140.0, 0.7, 260.0)
	died.emit()


func _spawn_afterimage() -> void:
	var c := pivot.duplicate() as Node2D
	c.global_position = pivot.global_position
	c.modulate = trail_col
	world.fx_root.add_child(c)
	var tw := c.create_tween()
	tw.tween_property(c, "modulate:a", 0.0, 0.28)
	tw.tween_callback(c.queue_free)


func _limb(l: Line2D, origin: Vector2, a1: float, a2: float, l1: float = 6.0, l2: float = 6.0) -> void:
	var mid := origin + Vector2(sin(a1), cos(a1)) * l1
	var end := mid + Vector2(sin(a1 + a2), cos(a1 + a2)) * l2
	l.points = PackedVector2Array([origin, mid, end])


func _animate(delta: float) -> void:
	var sp := clampf(absf(velocity.x) / 235.0, 0.5, 2.5)
	var on_floor := is_on_floor()
	var shoulder := Vector2(-0.5, -21.5)
	var hip := Vector2(0, -12.5)
	var rot := 0.1
	var py := -14.0
	var bob := 0.0

	if dash_t > 0.0:
		rot = 1.35
		py = -10.0
		_limb(arm_a, shoulder, 2.0, 0.0)
		_limb(arm_b, shoulder, 2.4, -0.2)
		_limb(leg_a, hip, -1.1, 0.4)
		_limb(leg_b, hip, -1.5, 0.3)
	elif slide_t > 0.0:
		rot = -1.3
		py = -8.0
		_limb(arm_a, shoulder, 1.0, 0.6)
		_limb(arm_b, shoulder, 2.4, 0.2)
		_limb(leg_a, hip, 0.1, -0.2)
		_limb(leg_b, hip, 0.35, -0.3)
	elif not on_floor:
		if spin_t > 0.0:
			spin_t = maxf(0.0, spin_t - delta)
			rot = (1.0 - spin_t / 0.38) * TAU
			_limb(arm_a, shoulder, -0.5, -1.8)
			_limb(arm_b, shoulder, 0.5, -1.8)
			_limb(leg_a, hip, 0.8, -1.6)
			_limb(leg_b, hip, -0.2, -1.6)
		elif velocity.y < 0.0:
			rot = -0.05
			_limb(arm_a, shoulder, -2.5, -0.3)
			_limb(arm_b, shoulder, -2.1, -0.4)
			_limb(leg_a, hip, 0.8, -1.3)
			_limb(leg_b, hip, -0.6, -0.9)
		else:
			rot = 0.18
			_limb(arm_a, shoulder, -2.9, 0.2)
			_limb(arm_b, shoulder, -2.6, 0.2)
			_limb(leg_a, hip, 0.35, -0.3)
			_limb(leg_b, hip, -0.25, -0.2)
	else:
		var cadence := 1.0
		match run_style:
			"sprint": cadence = 1.25
			"stomp": cadence = 0.85
			"skate": cadence = 0.7
			"titan": cadence = 0.8
		phase += delta * 15.0 * sp * cadence
		var s := sin(phase)
		var c := cos(phase)
		match run_style:
			"sprint":
				bob = absf(s) * -1.8
				rot = 0.36
				_limb(arm_a, shoulder, -0.2 + s * 0.9, 1.4)
				_limb(arm_b, shoulder, -0.2 - s * 0.9, 1.4)
				_limb(leg_a, hip, s * 1.15, -0.4 - maxf(0.0, c) * 1.15)
				_limb(leg_b, hip, -s * 1.15, -0.4 - maxf(0.0, -c) * 1.15)
			"stomp":
				bob = absf(s) * -2.6
				rot = 0.08
				_limb(arm_a, shoulder, -0.2 + s * 1.0, 0.5)
				_limb(arm_b, shoulder, -0.2 - s * 1.0, 0.5)
				_limb(leg_a, hip, s * 0.85, -0.2 - maxf(0.0, c) * 1.2)
				_limb(leg_b, hip, -s * 0.85, -0.2 - maxf(0.0, -c) * 1.2)
				var idx := int(floor(phase / PI))
				if idx != _step_idx:
					_step_idx = idx
					Fx.burst(world.fx_root, global_position + Vector2(0, -1), Color(1.0, 0.55, 0.2, 0.9), 5, 60.0, 0.3, 60.0, "spark", true, 120.0, Vector2.UP, 1.6)
			"titan":
				bob = absf(s) * -3.0
				rot = 0.12
				_limb(arm_a, shoulder, -0.4 + s * 0.9, 0.35)
				_limb(arm_b, shoulder, -0.4 - s * 0.9, 0.35)
				_limb(leg_a, hip, s * 1.0, -0.25 - maxf(0.0, c) * 1.3)
				_limb(leg_b, hip, -s * 1.0, -0.25 - maxf(0.0, -c) * 1.3)
				var tidx := int(floor(phase / PI))
				if tidx != _step_idx:
					_step_idx = tidx
					Fx.burst(world.fx_root, global_position + Vector2(0, -1), Color(0.65, 1.0, 0.2, 0.95), 7, 80.0, 0.35, 70.0, "spark", true, 140.0, Vector2.UP, 1.8)
					Fx.burst(world.fx_root, global_position + Vector2(-4, -1), Color(0.4, 0.35, 0.3, 0.8), 4, 40.0, 0.5, 20.0, "dust", false, 140.0, Vector2.UP, 2.0)
					world.shake(1.0, 0.07)
			"skate":
				bob = sin(phase * 0.5) * -0.8
				rot = 0.22
				_limb(arm_a, shoulder, 1.25 + s * 0.15, -0.05)
				_limb(arm_b, shoulder, -1.35 - s * 0.15, -0.05)
				_limb(leg_a, hip, 0.55 + s * 0.25, -0.2)
				_limb(leg_b, hip, -0.5 - s * 0.25, -0.1)
			_:
				bob = absf(s) * -1.4
				rot = 0.16
				_limb(arm_a, shoulder, -1.95 + s * 0.12, -0.15)
				_limb(arm_b, shoulder, -1.75 - s * 0.12, -0.15)
				_limb(leg_a, hip, s * 0.95, -0.35 - maxf(0.0, c) * 0.95)
				_limb(leg_b, hip, -s * 0.95, -0.35 - maxf(0.0, -c) * 0.95)

	if throw_t > 0.0:
		var k := throw_t / 0.2
		_limb(arm_a, shoulder, 1.55 + (1.0 - k) * 0.2, 0.0)
	if hurt_t > 0.0:
		rot = -0.6 * (hurt_t / 0.5)
		_limb(arm_a, shoulder, 0.6, 0.5)
		_limb(arm_b, shoulder, -0.6, 0.5)

	pivot.rotation = lerp_angle(pivot.rotation, rot, minf(1.0, delta * 22.0)) if spin_t <= 0.0 else rot
	pivot.position = pivot.position.lerp(Vector2(0, py + bob), minf(1.0, delta * 20.0))
	katana.default_color = Color("#aab4d0")


func _update_scarf(delta: float) -> void:
	if scarf_pts.is_empty() or dead:
		return
	var anchor := global_position + Vector2(-3.0, -26.5 + (pivot.position.y + 14.0))
	if dash_t > 0.0:
		anchor = global_position + Vector2(-2.0, -14.0)
	scarf_pts[0] = anchor
	var t := Time.get_ticks_msec() / 1000.0
	var seg := 3.2
	for i in range(1, scarf_pts.size()):
		var prev: Vector2 = scarf_pts[i - 1]
		var cur: Vector2 = scarf_pts[i]
		var wind := Vector2(-40.0 - velocity.x * 0.12, sin(t * 11.0 - i * 0.9) * 14.0 + 6.0 - velocity.y * 0.03)
		cur += wind * delta
		var d := cur - prev
		var ln := d.length()
		if ln > 0.001:
			cur = prev + d / ln * seg
		scarf_pts[i] = cur
	scarf.points = PackedVector2Array(scarf_pts)
