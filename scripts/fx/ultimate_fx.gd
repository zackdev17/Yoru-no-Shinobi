extends Node2D

const GY := 216.0

var w: World
var p: Ninja
var age := 0.0
var strike_age := 0.0
var _struck := false
var _mote_acc := 0.0
var _fired := {}
var impact := Vector2.ZERO
var trails: Array = []
var motes: Array = []
var cracks: Array = []
var light: PointLight2D
var shade: Node2D
var ghost_cols: Array = [
	Color(0.65, 0.42, 1.0), Color(0.33, 0.92, 1.0),
	Color(0.96, 0.98, 1.0), Color(0.55, 0.30, 1.0),
]


func setup(world: World, player: Ninja) -> void:
	w = world
	p = player
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = m
	z_index = 22
	for i in 4:
		trails.append([])
	light = PointLight2D.new()
	light.texture = TexGen.glow_tex(128)
	light.texture_scale = 2.4
	light.color = Color(0.55, 0.78, 1.0)
	light.energy = 0.0
	light.range_item_cull_mask = 1
	add_child(light)
	shade = Node2D.new()
	shade.material = Fx.unshaded_mat()
	shade.z_as_relative = false
	shade.z_index = 3
	shade.draw.connect(_on_shade_draw)
	add_child(shade)


func _on_shade_draw() -> void:
	if w == null:
		return
	var z := maxf(w.cam.zoom.x, 0.1)
	var half := Vector2(320.0, 144.0) / z
	var a := smoothstep(0.3, 1.3, age)
	if _struck:
		a *= 1.0 - clampf(strike_age / 0.35, 0.0, 1.0)
	shade.draw_rect(Rect2(w.cam.position - half - Vector2(8, 8), half * 2.0 + Vector2(16, 16)), Color(0.02, 0.0, 0.14, 0.34 * a))


func _body() -> Vector2:
	if is_instance_valid(p.pivot):
		return p.pivot.global_position
	return p.global_position


func _process(delta: float) -> void:
	if w == null or p == null or not is_instance_valid(p):
		queue_free()
		return
	var rd := delta / maxf(Engine.time_scale, 0.05)
	age += rd
	if p.ultimate_strike_done and not _struck:
		_struck = true
		strike_age = 0.0
		_on_strike()
	if _struck:
		strike_age += rd
		if strike_age > 2.0:
			queue_free()
			return
	elif not p.ultimate_active and age > 0.6:
		queue_free()
		return
	var bc := _body()
	_events(age, bc)
	_update_trails()
	_update_motes(rd)
	_update_light(bc)
	queue_redraw()
	shade.queue_redraw()


func _events(t: float, bc: Vector2) -> void:
	var par := get_parent()
	var ox := p.ultimate_origin.x
	if t >= 0.02 and not _fired.has("takeoff"):
		_fired["takeoff"] = true
		for k in 4:
			Fx.smoke(par, Vector2(ox + randf_range(-20.0, 20.0), GY - 2.0))
		Fx.ring(par, Vector2(ox, GY - 2.0), Color("#9fe8ff", 0.8), 6.0, 78.0, 0.42, 3.0)
		Fx.burst(par, Vector2(ox, GY - 2.0), Color("#b9f7ff"), 26, 190.0, 0.6, 360.0, "spark", true, 160.0, Vector2.UP, 2.4)
	if t >= 0.94 and not _fired.has("jump2"):
		_fired["jump2"] = true
		Fx.ring(par, bc, Color("#c9a0ff", 0.9), 6.0, 95.0, 0.45, 3.0)
		Fx.burst(par, bc, Color("#d8c0ff"), 22, 150.0, 0.5, 0.0, "spark", true, 360.0, Vector2.UP, 2.2)
	if t >= 1.42 and not _fired.has("hover"):
		_fired["hover"] = true
		Fx.ring(par, bc, Color("#8beaff", 0.95), 8.0, 140.0, 0.6, 4.0)
		Fx.ring(par, bc, Color("#ffffff", 0.7), 4.0, 80.0, 0.4, 2.0)
		Fx.burst(par, bc, Color("#8beaff"), 36, 210.0, 0.7, -15.0, "spark", true, 360.0, Vector2.UP, 2.6)
		w.big_flash(0.18)
	if t >= 2.62 and not _fired.has("release"):
		_fired["release"] = true
		Fx.ring(par, bc + Vector2(16.0, -24.0), Color("#f4fdff", 1.0), 6.0, 70.0, 0.35, 4.0)
		Fx.burst(par, bc + Vector2(16.0, -24.0), Color("#d8fbff"), 28, 170.0, 0.4, 0.0, "spark", true, 360.0, Vector2.UP, 2.2)
		w.big_flash(0.22)


func _update_trails() -> void:
	for i in trails.size():
		var tr: Array = trails[i]
		if i < p.ultimate_ghosts.size() and is_instance_valid(p.ultimate_ghosts[i]):
			tr.append(p.ultimate_ghosts[i].global_position)
			if tr.size() > 18:
				tr.pop_front()
		elif tr.size() > 0:
			tr.pop_front()


func _update_motes(rd: float) -> void:
	if not _struck and age > 0.5 and age < 2.62 and motes.size() < 170:
		_mote_acc += rd * lerpf(30.0, 90.0, clampf((age - 0.5) / 1.5, 0.0, 1.0))
		while _mote_acc >= 1.0:
			_mote_acc -= 1.0
			motes.append({
				"a": randf() * TAU,
				"r": randf_range(70.0, 150.0),
				"life": randf_range(0.45, 0.85),
				"t": 0.0,
				"c": randi() % 3,
			})
	for i in range(motes.size() - 1, -1, -1):
		var m: Dictionary = motes[i]
		m["t"] = float(m["t"]) + rd
		if float(m["t"]) >= float(m["life"]):
			motes.remove_at(i)


func _update_light(bc: Vector2) -> void:
	var aura := smoothstep(0.2, 1.0, age)
	var charge := clampf((age - 0.92) / 1.15, 0.0, 1.0)
	if _struck:
		var f := clampf(strike_age / 0.9, 0.0, 1.0)
		light.position = impact + Vector2(0.0, -34.0)
		light.texture_scale = lerpf(7.0, 3.0, f)
		light.color = Color(0.8, 0.95, 1.0)
		light.energy = 3.4 * pow(1.0 - f, 1.5)
	else:
		light.position = bc
		light.texture_scale = 2.4 + 1.2 * charge
		light.color = Color(0.55, 0.78, 1.0).lerp(Color(0.75, 0.55, 1.0), 0.5 + 0.5 * sin(age * 6.0))
		light.energy = (0.5 + 1.3 * charge + 0.2 * sin(age * 22.0)) * aura


func _on_strike() -> void:
	impact = Vector2(p.global_position.x + 20.0, GY)
	_make_cracks()
	var par := get_parent()
	Fx.burst(par, impact + Vector2(0.0, -2.0), Color(0.42, 0.36, 0.55, 1.0), 44, 280.0, 0.95, 560.0, "orb", false, 90.0, Vector2.UP, 2.3)
	Fx.burst(par, impact + Vector2(0.0, -2.0), Color("#9fe8ff"), 60, 330.0, 0.8, 380.0, "spark", true, 120.0, Vector2.UP, 2.4)
	for k in 7:
		Fx.smoke(par, impact + Vector2(randf_range(-170.0, 170.0), -2.0), Color(0.62, 0.66, 0.92, 0.75))
	for k in 3:
		Fx.ring(par, impact + Vector2(0.0, -2.0), Color("#8beaff", 0.6), 10.0, 120.0 + 40.0 * k, 0.5 + 0.1 * k, 2.0)


func _make_cracks() -> void:
	cracks.clear()
	for i in 18:
		var dir := -1.0 if i % 2 == 0 else 1.0
		var reach := randf_range(90.0, 310.0)
		var steps := 12
		var pts := PackedVector2Array()
		var x := 0.0
		var y := 0.0
		for j in steps + 1:
			pts.append(impact + Vector2(x, y))
			x += dir * reach / float(steps) * randf_range(0.6, 1.4)
			y = clampf(y + randf_range(-3.5, 4.5), -1.0, 16.0)
		cracks.append({"pts": pts, "delay": randf_range(0.0, 0.14), "seed": float(i) * 3.7})


func _ellipse(c: Vector2, r: float, sq: float, col: Color, wd: float, a0: float = 0.0, a1: float = TAU, seg: int = 40) -> void:
	var pts := PackedVector2Array()
	for i in seg + 1:
		var a := a0 + (a1 - a0) * float(i) / float(seg)
		pts.append(c + Vector2(cos(a) * r, sin(a) * r * sq))
	draw_polyline(pts, col, wd)


func _jag(a: Vector2, b: Vector2, jit: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var q := a.lerp(b, float(i) / float(n))
		if i > 0 and i < n:
			q += Vector2(randf_range(-jit, jit), randf_range(-jit, jit))
		pts.append(q)
	return pts


func _draw() -> void:
	if w == null or p == null or not is_instance_valid(p):
		return
	var t := age
	var bc := _body()
	var rune_c := Vector2(p.ultimate_origin.x, GY)
	if not _struck:
		var inten := smoothstep(0.0, 0.5, t) * (0.8 + 0.2 * sin(t * 9.0))
		inten *= 1.0 + 0.6 * smoothstep(2.6, 3.18, t)
		_runes(rune_c, inten, 1.0, t)
		_aura(bc, t)
		_seal(bc, t)
		_charge_orb(bc, t)
		_telegraph(t)
	else:
		_runes(rune_c, maxf(0.0, 1.0 - strike_age / 0.35), 1.0 + strike_age * 3.0, t)
		_draw_strike(strike_age)
	_draw_trails()
	_draw_motes(bc)


func _seal(bc: Vector2, t: float) -> void:
	var a := smoothstep(0.9, 1.5, t) * (1.0 - smoothstep(2.5, 2.9, t))
	if a <= 0.01 or p.ultimate_ghosts.size() < 4:
		return
	var order := [0, 2, 1, 3]
	var pos: Array[Vector2] = []
	for i in 4:
		var g = p.ultimate_ghosts[i]
		if not is_instance_valid(g):
			return
		pos.append(g.global_position + Vector2(0.0, -8.0))
	for k in 4:
		var s: Vector2 = pos[order[k]]
		var e: Vector2 = pos[order[(k + 1) % 4]]
		UD.bolt(self, s, e, Color(0.55, 0.85, 1.0, 1.0), a, 5.0, 6, 1.4)
		UD.glow(self, s, 22.0, ghost_cols[order[k] % ghost_cols.size()], 0.7 * a)
		var top := Vector2(s.x, w.cam.position.y - 170.0)
		draw_line(s, top, Color(0.7, 0.9, 1.0, 0.16 * a), 1.0)
		if int(t * 14.0 + float(k)) % 3 == 0:
			UD.bolt(self, s, s + Vector2(randf_range(-10.0, 10.0), -70.0), Color(0.8, 0.95, 1.0, 1.0), a * 0.8, 6.0, 5, 1.2)
	if t < 2.62:
		var hand := bc + Vector2(16.0, -24.0)
		for k in 4:
			var d := hand.lerp(pos[k], 0.0)
			draw_line(pos[k], hand, Color(0.7, 0.9, 1.0, 0.22 * a), 1.0)
			var u := fposmod(t * 1.6 + float(k) * 0.25, 1.0)
			draw_circle(pos[k].lerp(hand, u), 2.0, Color(1, 1, 1, 0.9 * a))


func _runes(c: Vector2, inten: float, rmul: float, t: float) -> void:
	if inten <= 0.01:
		return
	var sq := 0.26
	var grow := 0.4 + 0.6 * smoothstep(0.0, 0.6, t)
	var R := 74.0 * grow * rmul
	var cy := Color(0.55, 0.88, 1.0, 0.6 * inten)
	var vi := Color(0.72, 0.46, 1.0, 0.55 * inten)
	_ellipse(c, R * 1.12, sq, Color(cy.r, cy.g, cy.b, 0.28 * inten), 1.0)
	_ellipse(c, R, sq, cy, 1.6)
	_ellipse(c, R * 0.82, sq, vi, 1.0)
	_ellipse(c, R * 0.34, sq, cy, 1.0)
	var rot := t * 0.9
	for k in 8:
		var a1 := rot + float(k) * TAU / 8.0
		var a2 := rot + float(k + 3) * TAU / 8.0
		var pa := c + Vector2(cos(a1) * R * 0.82, sin(a1) * R * 0.82 * sq)
		var pb := c + Vector2(cos(a2) * R * 0.82, sin(a2) * R * 0.82 * sq)
		draw_line(pa, pb, vi, 1.0)
	for k in 24:
		var a := -rot * 0.6 + float(k) * TAU / 24.0
		var d := Vector2(cos(a), sin(a) * sq)
		var len_out := 6.0 if k % 3 == 0 else 3.0
		draw_line(c + d * R * 1.12, c + d * (R * 1.12 + len_out), Color(cy.r, cy.g, cy.b, 0.45 * inten), 1.0)
	for k in 12:
		var a := rot * 0.5 + float(k) * TAU / 12.0
		var base := c + Vector2(cos(a) * R, sin(a) * R * sq)
		var h := (10.0 + 16.0 * (0.5 + 0.5 * sin(t * 5.0 + float(k) * 1.7))) * inten
		draw_line(base, base + Vector2(0.0, -h), Color(0.6, 0.9, 1.0, 0.32 * inten), 1.0)
		draw_line(base, base + Vector2(0.0, -h * 0.5), Color(1, 1, 1, 0.3 * inten), 1.0)
	draw_circle(c, R * 0.22, Color(0.5, 0.85, 1.0, 0.08 * inten))


func _aura(bc: Vector2, t: float) -> void:
	var aura := smoothstep(0.2, 1.0, t)
	if aura <= 0.01:
		return
	var charge := clampf((t - 0.92) / 1.15, 0.0, 1.0)
	for i in 6:
		var r := (40.0 - float(i) * 6.0) * (1.0 + 0.06 * sin(t * 14.0 + float(i)))
		var a := (0.025 + 0.02 * charge) * aura * float(i + 1)
		draw_circle(bc, r, Color(0.5, 0.8, 1.0, a))
	for i in 3:
		var base := t * (5.0 + float(i) * 2.0) + float(i) * 2.1
		var col := Color(0.8, 0.95, 1.0, 0.6 * aura) if i != 1 else Color(0.75, 0.5, 1.0, 0.6 * aura)
		draw_arc(bc, 24.0 + float(i) * 5.0, base, base + 1.6, 14, col, 1.5)
	var n_arcs := 2 + int(charge * 3.0)
	for i in n_arcs:
		var a := randf() * TAU
		var d := Vector2(cos(a), sin(a))
		var pts := _jag(bc + d * 8.0, bc + d * randf_range(26.0, 42.0), 4.0, 5)
		draw_polyline(pts, Color(0.7, 0.95, 1.0, 0.8 * aura), 1.2)
		draw_polyline(pts, Color(1, 1, 1, 0.9 * aura), 0.6)


func _charge_orb(bc: Vector2, t: float) -> void:
	if t < 0.92 or t >= 3.18:
		return
	if t < 2.62:
		var hand := bc + Vector2(16.0, -24.0)
		var ch := clampf((t - 0.92) / 1.15, 0.0, 1.0)
		var r := 3.0 + 9.0 * ch
		draw_circle(hand, r * 2.8, Color(0.4, 0.8, 1.0, 0.06))
		draw_circle(hand, r * 1.9, Color(0.5, 0.85, 1.0, 0.12))
		draw_circle(hand, r * 1.25, Color(0.7, 0.95, 1.0, 0.26))
		draw_circle(hand, r * 0.65, Color(1, 1, 1, 0.92))
		for k in 8:
			var ang := t * 6.0 + float(k) * TAU / 8.0
			var ln := r * (1.5 + 0.8 * sin(t * 20.0 + float(k) * 1.7))
			var d := Vector2(cos(ang), sin(ang))
			draw_line(hand + d * r * 0.8, hand + d * (r * 0.8 + ln), Color(0.75, 0.95, 1.0, 0.7), 1.0)
		draw_arc(hand, r * 1.4, -t * 8.0, -t * 8.0 + TAU * 0.7, 18, Color(0.85, 0.7, 1.0, 0.8), 1.5)
		draw_arc(hand, r * 1.8, t * 5.0, t * 5.0 + TAU * 0.4, 14, Color(0.6, 0.9, 1.0, 0.6), 1.0)
	elif p.ultimate_projectile_launched:
		var pos := p.ultimate_projectile_pos
		var st := p.ultimate_projectile_start
		draw_line(pos, pos.lerp(st, 0.45), Color(0.5, 0.85, 1.0, 0.35), 7.0)
		draw_line(pos, pos.lerp(st, 0.38), Color(0.8, 0.95, 1.0, 0.6), 3.5)
		draw_line(pos, pos.lerp(st, 0.28), Color(1, 1, 1, 0.85), 1.5)
		draw_circle(pos, 15.0, Color(0.4, 0.8, 1.0, 0.1))
		draw_circle(pos, 9.0, Color(0.6, 0.9, 1.0, 0.3))
		draw_circle(pos, 4.5, Color(1, 1, 1, 0.95))


func _telegraph(t: float) -> void:
	if t < 1.2 or t >= 3.18:
		return
	var u := clampf((t - 1.2) / 1.98, 0.0, 1.0)
	var tx := p.global_position.x + 20.0
	var top := w.cam.position.y - 240.0
	var blink := 0.55 + 0.45 * sin(t * (10.0 + 24.0 * u))
	var a := (0.08 + 0.22 * u) * blink
	for k in 3:
		var off := (float(k) - 1.0) * lerpf(40.0, 6.0, u)
		draw_line(Vector2(tx + off, top), Vector2(tx + off, GY), Color(0.6, 0.9, 1.0, a * (0.5 if k != 1 else 1.0)), 1.0)
	var c := Vector2(tx, GY)
	_ellipse(c, lerpf(64.0, 14.0, u), 0.28, Color(0.9, 0.7, 1.0, 0.35 + 0.5 * u), 1.5)
	_ellipse(c, lerpf(34.0, 7.0, u), 0.28, Color(1, 1, 1, 0.3 + 0.5 * u), 1.0)
	draw_line(c + Vector2(-26.0 * (1.0 - u * 0.5), 0.0), c + Vector2(26.0 * (1.0 - u * 0.5), 0.0), Color(0.8, 0.95, 1.0, 0.4 * blink), 1.0)


func _draw_trails() -> void:
	for i in trails.size():
		var tr: Array = trails[i]
		var n := tr.size()
		if n < 2:
			continue
		var gc: Color = ghost_cols[i % ghost_cols.size()]
		for j in range(1, n):
			var f := float(j) / float(n)
			draw_line(tr[j - 1], tr[j], Color(gc.r, gc.g, gc.b, f * 0.55), 1.0 + 3.0 * f)
			draw_line(tr[j - 1], tr[j], Color(1, 1, 1, f * 0.35), 1.0)


func _mote_pos(m: Dictionary, u: float, bc: Vector2) -> Vector2:
	var uu := clampf(u, 0.0, 1.0)
	var r := float(m["r"]) * (1.0 - uu * uu)
	var a := float(m["a"]) + uu * 1.5
	return bc + Vector2(cos(a) * r, sin(a) * r * 0.75)


func _draw_motes(bc: Vector2) -> void:
	var cols := [Color(0.6, 0.92, 1.0), Color(0.78, 0.55, 1.0), Color(1, 1, 1)]
	for m in motes:
		var d: Dictionary = m
		var u := float(d["t"]) / float(d["life"])
		var a := sin(u * PI) * 0.9
		var c: Color = cols[int(d["c"])]
		var p0 := _mote_pos(d, u, bc)
		var p1 := _mote_pos(d, u - 0.12, bc)
		draw_line(p1, p0, Color(c.r, c.g, c.b, a * 0.55), 1.0)
		draw_rect(Rect2(p0 - Vector2(1, 1), Vector2(2, 2)), Color(c.r, c.g, c.b, a))


func _draw_strike(sa: float) -> void:
	var tx := impact.x
	var top := w.cam.position.y - 260.0
	var f := clampf(sa / 0.7, 0.0, 1.0)
	if f < 1.0:
		var wd := 64.0 * pow(1.0 - f, 1.6) + 6.0 * (1.0 - f)
		for k in 4:
			var kw := wd * (1.0 - float(k) * 0.24)
			var col := Color(0.45, 0.85, 1.0, (0.16 + 0.12 * float(k)) * (1.0 - f))
			if k == 3:
				col = Color(1, 1, 1, 0.9 * (1.0 - f))
			draw_rect(Rect2(tx - kw * 0.5, top, kw, GY - top), col)
	for k in 3:
		var ts := sa - float(k) * 0.07
		if ts <= 0.0:
			continue
		var g := clampf(ts / 0.75, 0.0, 1.0)
		var e := 1.0 - pow(1.0 - g, 2.2)
		var a := (1.0 - g) * (0.9 - 0.2 * float(k))
		var r := e * (320.0 + 70.0 * float(k))
		_ellipse(impact, r, 0.2, Color(0.85, 0.97, 1.0, a), maxf(1.0, 5.0 * (1.0 - g)))
		_ellipse(impact, r * 0.94, 0.2, Color(0.7, 0.5, 1.0, a * 0.6), 1.0)
	var fade := 1.0 - clampf((sa - 0.9) / 1.0, 0.0, 1.0)
	for i in cracks.size():
		var cr: Dictionary = cracks[i]
		var pts: PackedVector2Array = cr["pts"]
		var gr := clampf((sa - float(cr["delay"])) / 0.3, 0.0, 1.0)
		if gr <= 0.0:
			continue
		var cnt := maxi(2, int(float(pts.size()) * gr))
		var sub := pts.slice(0, cnt)
		draw_polyline(sub, Color(0.5, 0.88, 1.0, 0.5 * fade), 3.0)
		draw_polyline(sub, Color(0.9, 1.0, 1.0, 0.95 * fade), 1.0)
		for j in range(1, cnt, 3):
			var hh := (8.0 + 10.0 * absf(sin(float(j) * 7.3 + float(cr["seed"])))) * gr * fade
			draw_line(sub[j], sub[j] + Vector2(0.0, -hh), Color(0.7, 0.95, 1.0, 0.5 * fade), 1.0)
	if sa < 0.55:
		var lf := 1.0 - sa / 0.55
		draw_line(impact + Vector2(-240.0 * lf, -6.0), impact + Vector2(240.0 * lf, -6.0), Color(0.8, 0.95, 1.0, 0.8 * lf), 2.0)
		draw_line(impact + Vector2(-140.0 * lf, -6.0), impact + Vector2(140.0 * lf, -6.0), Color(1, 1, 1, lf), 1.0)
		draw_circle(impact + Vector2(0.0, -6.0), 26.0 * lf + 4.0, Color(0.7, 0.95, 1.0, 0.35 * lf))
		draw_circle(impact + Vector2(0.0, -6.0), 12.0 * lf + 2.0, Color(1, 1, 1, 0.8 * lf))
