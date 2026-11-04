class_name UltAura
extends Node2D

var kind := "storm"
var p: Ninja
var world: World
var life := 3.0
var age := 0.0
var light: PointLight2D
var follow := true
var radius := 300.0
var tint := Color(0.75, 1.0, 0.3)


func _ready() -> void:
	z_index = 9
	material = Fx.add_mat()
	light = PointLight2D.new()
	light.texture = TexGen.light_tex(1.5)
	light.range_item_cull_mask = 1
	light.shadow_enabled = false
	light.texture_scale = 3.0
	match kind:
		"storm": light.color = Color(0.5, 1.0, 0.75)
		"meteor": light.color = Color(1.0, 0.55, 0.2)
		"nuke": light.color = Color(0.75, 1.0, 0.3)
		"mushroom":
			light.color = Color(1.0, 0.6, 0.2)
			light.texture_scale = 9.0
		"blast":
			light.color = Color(0.8, 1.0, 0.4)
			light.texture_scale = 7.0
		_: light.color = Color(0.6, 0.9, 1.0)
	add_child(light)


func _process(delta: float) -> void:
	if follow and (p == null or not is_instance_valid(p) or p.dead):
		queue_free()
		return
	age += delta
	if age >= life:
		queue_free()
		return
	if follow:
		global_position = p.global_position + Vector2(0.0, -14.0)
	var fade := _fade()
	light.energy = (1.2 + 0.4 * sin(age * 18.0)) * fade
	if kind == "mushroom":
		light.position = Vector2(0.0, -90.0)
		light.energy = 3.0 * clampf(1.0 - age / 2.6, 0.0, 1.0) * clampf(age / 0.08, 0.0, 1.0)
	elif kind == "blast":
		light.position = Vector2(0.0, -40.0)
		light.energy = 2.6 * clampf(1.0 - age / 0.7, 0.0, 1.0)
	queue_redraw()


func _fade() -> float:
	return clampf(age / 0.2, 0.0, 1.0) * clampf((life - age) / 0.4, 0.0, 1.0)


func _ell(c: Vector2, rx: float, ry: float, a0: float, a1: float, col: Color, wd: float) -> void:
	var pts := PackedVector2Array()
	for i in 13:
		var a := a0 + (a1 - a0) * float(i) / 12.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, col, wd)


func _draw() -> void:
	var fade := _fade()
	match kind:
		"storm": _draw_storm(fade)
		"meteor": _draw_inferno(fade)
		"nuke": _draw_nuke(fade)
		"mushroom": _draw_mushroom()
		"blast": _draw_blast()
		_: _draw_blizzard(fade)


func _draw_storm(fade: float) -> void:
	for k in 9:
		var u := float(k) / 8.0
		var y := 18.0 - u * 56.0
		var rx := lerpf(6.0, 26.0, u)
		var a0 := age * (11.0 + float(k) * 1.4) + float(k) * 0.9
		_ell(Vector2(0.0, y), rx, rx * 0.28, a0, a0 + 2.6, Color(0.55, 1.0, 0.8, 0.65 * fade), 2.0)
		_ell(Vector2(0.0, y), rx * 0.8, rx * 0.22, a0 + 2.2, a0 + 4.2, Color(1, 1, 1, 0.45 * fade), 1.0)
	for i in 7:
		var y2 := -30.0 + float(i) * 8.0
		var x0 := -22.0 - fmod(age * 520.0 + float(i) * 53.0, 170.0)
		draw_line(Vector2(x0, y2), Vector2(x0 - 28.0, y2), Color(0.7, 1.0, 0.85, 0.5 * fade), 1.5)
	draw_circle(Vector2.ZERO, 30.0, Color(0.5, 1.0, 0.75, 0.07 * fade))


func _draw_inferno(fade: float) -> void:
	draw_circle(Vector2.ZERO, 32.0, Color(1.0, 0.5, 0.1, 0.08 * fade))
	for i in 22:
		var ang := age * 4.5 + float(i) * TAU / 22.0
		var rad := 24.0 + 5.0 * sin(age * 8.0 + float(i))
		var pos := Vector2(cos(ang) * rad, sin(ang) * rad * 0.55 - 2.0)
		var sz := 3.2 + 1.6 * sin(age * 10.0 + float(i) * 2.0)
		draw_circle(pos, sz * 1.8, Color(1.0, 0.45, 0.1, 0.22 * fade))
		draw_circle(pos, sz, Color(1.0, 0.6, 0.15, 0.7 * fade))
		draw_circle(pos, sz * 0.5, Color(1.0, 0.95, 0.5, 0.9 * fade))
	for i in 8:
		var x := -14.0 + float(i) * 4.0
		var h := 14.0 + 10.0 * absf(sin(age * 9.0 + float(i) * 1.7))
		var sway := sin(age * 12.0 + float(i)) * 3.0
		draw_line(Vector2(x, 4.0), Vector2(x + sway, 4.0 - h), Color(1.0, 0.45, 0.1, 0.6 * fade), 3.0)
		draw_line(Vector2(x, 4.0), Vector2(x + sway, 4.0 - h * 0.6), Color(1.0, 0.9, 0.4, 0.85 * fade), 1.5)


func _draw_blizzard(fade: float) -> void:
	if age < 0.55:
		var f := 1.0 - age / 0.55
		draw_arc(Vector2.ZERO, age * 700.0, 0.0, TAU, 56, Color(0.7, 0.95, 1.0, f), 3.0)
		draw_arc(Vector2.ZERO, age * 640.0, 0.0, TAU, 56, Color(1, 1, 1, f * 0.6), 1.0)
	for t in 2:
		var pts := PackedVector2Array()
		for i in 4:
			var a := age * (1.6 if t == 0 else -1.2) + float(i) * TAU / 3.0 + float(t) * PI / 3.0
			pts.append(Vector2(cos(a), sin(a)) * 30.0)
		draw_polyline(pts, Color(0.7, 0.95, 1.0, 0.7 * fade), 1.5)
	draw_arc(Vector2.ZERO, 34.0 + 2.0 * sin(age * 7.0), 0.0, TAU, 40, Color(0.6, 0.9, 1.0, 0.45 * fade), 2.0)
	draw_circle(Vector2.ZERO, 30.0, Color(0.6, 0.9, 1.0, 0.07 * fade))
	for i in 20:
		var ang := age * 3.0 + float(i) * 0.7
		var rad := 12.0 + float(i) * 1.9
		var pos := Vector2(cos(ang) * rad, sin(ang) * rad * 0.7 - 4.0 + sin(age * 2.0 + float(i)) * 4.0)
		draw_rect(Rect2(pos - Vector2(1, 1), Vector2(2, 2)), Color(1, 1, 1, 0.85 * fade))
	for i in 6:
		var a2 := -age * 2.2 + float(i) * TAU / 6.0
		var c := Vector2(cos(a2) * 26.0, sin(a2) * 15.0)
		var d := PackedVector2Array([c + Vector2(0, -4), c + Vector2(2.5, 0), c + Vector2(0, 4), c + Vector2(-2.5, 0), c + Vector2(0, -4)])
		draw_polyline(d, Color(0.85, 0.97, 1.0, 0.9 * fade), 1.5)


func _draw_nuke(fade: float) -> void:
	var fired := p != null and is_instance_valid(p) and p._nuke_fired
	if not fired:
		var ch := clampf(age / 1.3, 0.0, 1.0)
		var core_r := 5.0 + 17.0 * ch + 2.0 * sin(age * 28.0)
		draw_circle(Vector2.ZERO, core_r * 2.6, Color(0.7, 1.0, 0.25, 0.08 * fade))
		draw_circle(Vector2.ZERO, core_r * 1.7, Color(0.8, 1.0, 0.3, 0.16 * fade))
		draw_circle(Vector2.ZERO, core_r, Color(1.0, 0.95, 0.5, 0.55 * fade))
		draw_circle(Vector2.ZERO, core_r * 0.5, Color(1, 1, 1, 0.95 * fade))
		for i in 3:
			var u := fposmod(age * 1.6 + float(i) / 3.0, 1.0)
			draw_arc(Vector2.ZERO, lerpf(80.0, 10.0, u), 0.0, TAU, 48, Color(0.7, 1.0, 0.25, (1.0 - u) * 0.8 * fade), 2.0)
		for i in 10:
			var a := age * (4.0 + 6.0 * ch) + float(i) * TAU / 10.0
			var d := Vector2(cos(a), sin(a))
			draw_line(d * core_r * 1.1, d * (core_r * 1.1 + 10.0 + 14.0 * ch), Color(1.0, 0.85, 0.3, 0.8 * fade), 1.5)
		_trefoil(Vector2(0.0, -34.0), 10.0 + 6.0 * ch, age * (2.0 + 5.0 * ch), Color(1.0, 0.9, 0.2, 0.85 * fade))
	else:
		draw_circle(Vector2.ZERO, 36.0, Color(0.6, 1.0, 0.25, 0.09 * fade))
		for i in 18:
			var ang := age * 3.5 + float(i) * TAU / 18.0
			var rad := 26.0 + 5.0 * sin(age * 7.0 + float(i))
			var pos := Vector2(cos(ang) * rad, sin(ang) * rad * 0.6 - 2.0)
			var sz := 2.6 + 1.4 * sin(age * 9.0 + float(i) * 2.0)
			draw_circle(pos, sz * 1.7, Color(0.5, 1.0, 0.2, 0.2 * fade))
			draw_circle(pos, sz, Color(0.8, 1.0, 0.35, 0.8 * fade))
		for i in 7:
			var x := -14.0 + float(i) * 4.5
			var h := 16.0 + 12.0 * absf(sin(age * 8.0 + float(i) * 1.9))
			draw_line(Vector2(x, 4.0), Vector2(x + sin(age * 11.0 + float(i)) * 3.0, 4.0 - h), Color(0.6, 1.0, 0.2, 0.55 * fade), 3.0)
			draw_line(Vector2(x, 4.0), Vector2(x + sin(age * 11.0 + float(i)) * 3.0, 4.0 - h * 0.55), Color(1.0, 1.0, 0.7, 0.85 * fade), 1.5)
		_trefoil(Vector2(0.0, -34.0), 12.0, age * 2.0, Color(0.8, 1.0, 0.3, 0.7 * fade))


func _trefoil(c: Vector2, r: float, rot: float, col: Color) -> void:
	for k in 3:
		var a := rot + float(k) * TAU / 3.0
		draw_arc(c, r, a - 0.5, a + 0.5, 8, col, maxf(2.0, r * 0.45))
	draw_circle(c, maxf(1.5, r * 0.22), col)


func _draw_blast() -> void:
	var f := clampf(age / life, 0.0, 1.0)
	var e := 1.0 - pow(1.0 - f, 2.5)
	var r := radius * e
	var a := 1.0 - f
	draw_circle(Vector2(0, -r * 0.25), r * 0.55, Color(1.0, 0.55, 0.15, 0.20 * a))
	draw_circle(Vector2(0, -r * 0.25), r * 0.35, Color(1.0, 0.8, 0.3, 0.30 * a))
	draw_circle(Vector2(0, -r * 0.2), r * 0.18, Color(1, 1, 0.9, 0.5 * a))
	draw_arc(Vector2(0, 0), r, PI, TAU, 48, Color(tint.r, tint.g, tint.b, 0.9 * a), 4.0 + 5.0 * a)
	draw_arc(Vector2(0, 0), r * 0.92, PI, TAU, 48, Color(1, 1, 1, 0.5 * a), 1.5)
	var pts := PackedVector2Array()
	for i in 41:
		var ang := float(i) / 40.0 * TAU
		pts.append(Vector2(cos(ang) * r * 1.1, sin(ang) * r * 1.1 * 0.18))
	draw_polyline(pts, Color(tint.r, tint.g, tint.b, 0.8 * a), 2.0)


func _draw_mushroom() -> void:
	var fade := clampf((life - age) / 0.8, 0.0, 1.0)
	var rise := 1.0 - pow(1.0 - clampf(age / 1.5, 0.0, 1.0), 2.2)
	if age < 0.9:
		var fb := 1.0 - age / 0.9
		var fr := 40.0 + 120.0 * (1.0 - pow(fb, 2.0))
		draw_circle(Vector2(0, -fr * 0.45), fr, Color(1.0, 0.7, 0.25, 0.28 * fb))
		draw_circle(Vector2(0, -fr * 0.45), fr * 0.6, Color(1.0, 0.95, 0.6, 0.45 * fb))
		draw_circle(Vector2(0, -fr * 0.4), fr * 0.3, Color(1, 1, 1, 0.8 * fb))
	for k in 3:
		var u := clampf(age * 1.1 - float(k) * 0.12, 0.0, 1.0)
		if u > 0.0 and u < 1.0:
			var pts := PackedVector2Array()
			var rr := u * (520.0 + 120.0 * float(k))
			for i in 41:
				var ang := float(i) / 40.0 * TAU
				pts.append(Vector2(cos(ang) * rr, sin(ang) * rr * 0.16))
			draw_polyline(pts, Color(0.8, 1.0, 0.35, (1.0 - u) * 0.8), 3.0)
	var h := 200.0 * rise
	var n := 16
	for i in n:
		var u2 := float(i) / float(n - 1)
		var y := -u2 * h
		var wob := sin(age * 3.0 + float(i) * 0.9) * 5.0 * u2
		var r2 := lerpf(26.0, 15.0, u2) + 3.0 * sin(age * 5.0 + float(i))
		var hot := clampf(1.0 - u2 * 0.9 - age * 0.12, 0.0, 1.0)
		var col := Color(1.0, 0.35 + 0.5 * hot, 0.1 + 0.15 * hot, (0.30 + 0.10 * hot) * fade)
		draw_circle(Vector2(wob, y), r2, col)
		draw_circle(Vector2(wob, y), r2 * 0.55, Color(1.0, 0.8 * hot + 0.2, 0.3 * hot, 0.35 * fade))
	var cap_c := Vector2(0.0, -h - 8.0)
	var cap_r := 24.0 + 86.0 * clampf(age / 1.7, 0.0, 1.0)
	for i in 18:
		var ang2 := float(i) * TAU / 18.0 + age * 0.9
		var pos := cap_c + Vector2(cos(ang2) * cap_r, sin(ang2) * cap_r * 0.42)
		var pr := 20.0 + 6.0 * sin(age * 4.0 + float(i) * 1.3)
		var behind := sin(ang2) < 0.0
		var cc := Color(1.0, 0.42, 0.12, 0.30 * fade) if behind else Color(1.0, 0.6, 0.2, 0.38 * fade)
		draw_circle(pos, pr, cc)
		draw_circle(pos, pr * 0.5, Color(1.0, 0.85, 0.4, 0.28 * fade))
	draw_circle(cap_c + Vector2(0, -4), cap_r * 0.7, Color(1.0, 0.55, 0.15, 0.22 * fade))
	draw_circle(cap_c + Vector2(0, -2), cap_r * 0.4, Color(1.0, 0.9, 0.5, 0.25 * fade))
	draw_circle(Vector2(0, -8), 70.0, Color(0.6, 1.0, 0.25, 0.10 * fade))
	draw_circle(Vector2(0, -8), 38.0, Color(0.8, 1.0, 0.4, 0.14 * fade))
