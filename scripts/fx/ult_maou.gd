extends "res://scripts/fx/ult_dir.gd"

const GOLD := Color(1.0, 0.84, 0.36)
const GOLD_HI := Color(1.0, 0.96, 0.74)
const VIOLET := Color(0.62, 0.30, 1.0)
const BLADE_W := 24.0
const BLADE_L := 188.0
const GUARD_W := 62.0
const PILLAR_HW := 34.0
const PILLAR_OVER := 260.0

var _acc := 0.0
var sun_light: PointLight2D
var dark_top: Node2D


func _pal() -> Array:
	return [GOLD, VIOLET, GOLD_HI]


func _init_fx() -> void:
	sun_light = PointLight2D.new()
	sun_light.texture = TexGen.glow_tex(128)
	sun_light.texture_scale = 7.0
	sun_light.range_item_cull_mask = 1
	sun_light.energy = 0.0
	sun_light.color = Color(1.0, 0.9, 0.62)
	add_child(sun_light)
	dark_top = Node2D.new()
	dark_top.material = Fx.unshaded_mat()
	dark_top.z_as_relative = false
	dark_top.z_index = 23
	dark_top.draw.connect(_on_dark_top_draw)
	add_child(dark_top)


func _light_energy(t: float) -> float:
	var e := 0.5 + 0.7 * smoothstep(0.0, 1.5, t) + 1.3 * smoothstep(Skills.WE_PILLAR, Skills.WE_PILLAR + 0.5, t)
	e += 1.2 * smoothstep(Skills.WE_SWORD, Skills.WE_IMPACT, t)
	if t >= Skills.WE_IMPACT:
		e += 3.5 * exp(-(t - Skills.WE_IMPACT) * 1.8)
	return e


func _ix() -> float:
	return float(p._cine.get("x0", p.global_position.x)) + Skills.WE_DX


func _eye_c() -> Vector2:
	var vr := view()
	return Vector2(_ix(), vr.position.y + vr.size.y * 0.25)


func _eye_half() -> Vector2:
	var vr := view()
	return Vector2(vr.size.x * 0.25, vr.size.y * 0.19)


func _on_dark_top_draw() -> void:
	if w == null or p == null or not is_instance_valid(p):
		return
	_pillar_ribbons(dark_top, p.ultimate_elapsed)


func _sun_k(t: float) -> float:
	var up := smoothstep(Skills.WE_EYE0 + 0.2, Skills.WE_EYE1, t)
	var boost := 1.0 + 0.35 * smoothstep(Skills.WE_PILLAR, Skills.WE_PILLAR + 0.5, t)
	var calm := 1.0 - 0.8 * smoothstep(Skills.WE_SWORD - 0.3, Skills.WE_SWORD + 0.8, t)
	return up * boost * calm * (1.0 - smoothstep(Skills.WE_SHATTER - 0.3, Skills.WE_SHATTER, t))


func _pillar_top() -> float:
	return view().position.y - PILLAR_OVER


func _open(t: float) -> float:
	var u := smoothstep(Skills.WE_EYE0, Skills.WE_EYE1, t)
	return u + 0.12 * sin(u * PI)


func _sword_tip(t: float) -> float:
	var vr := view()
	var y0 := _eye_c().y + _eye_half().y * 0.2
	var u := clampf((t - Skills.WE_SWORD) / (Skills.WE_IMPACT - Skills.WE_SWORD), 0.0, 1.0)
	return lerpf(y0, GY, pow(u, 1.25)) if vr.size.y > 0.0 else GY


func _sword_alpha(t: float) -> float:
	return smoothstep(Skills.WE_SWORD - 0.3, Skills.WE_SWORD + 0.6, t)


func _lid(u: float, open: float, top: bool) -> float:
	var h := _eye_half().y * open * pow(maxf(0.0, 1.0 - u * u), 0.85)
	return -h if top else h * 0.8


func _almond(open: float, grow: float = 1.0) -> PackedVector2Array:
	var c := _eye_c()
	var wh := _eye_half().x * grow
	var pts := PackedVector2Array()
	for k in 25:
		var u := -1.0 + 2.0 * float(k) / 24.0
		pts.append(c + Vector2(u * wh, _lid(u, open, true) * grow))
	for k in 25:
		var u2 := 1.0 - 2.0 * float(k) / 24.0
		pts.append(c + Vector2(u2 * wh, _lid(u2, open, false) * grow))
	return pts


func _tick(t: float, bc: Vector2) -> void:
	_acc += rd
	var vr := view()
	var sk := _sun_k(t)
	sun_light.position = _eye_c()
	dark_top.queue_redraw()
	sun_light.energy = minf(sk, 1.4) * 1.3 * _fade_now()
	if sk > 0.3 and t < Skills.WE_IMPACT:
		w.fx_flash = maxf(w.fx_flash, (0.035 + 0.015 * sin(age * 6.0)) * minf(sk, 1.0))
	while _acc >= 0.04:
		_acc -= 0.04
		if sk > 0.2:
			var sa := randf() * TAU
			var sd := Vector2(cos(sa), sin(sa))
			emit(_eye_c() + sd * _eye_half().x * randf_range(0.3, 1.1), sd * randf_range(30.0, 95.0), randf_range(0.8, 1.7), randf_range(1.6, 2.6), GOLD_HI if randf() < 0.7 else GOLD, 0.0, 0.0, 0)
		var a := randf() * TAU
		emit(bc + Vector2(cos(a) * randf_range(7.0, 24.0), randf_range(-18.0, 14.0)), Vector2(randf_range(-10.0, 10.0), randf_range(-70.0, -130.0)),
			randf_range(0.6, 1.2), 2.0, GOLD if randf() < 0.5 else VIOLET, 0.0, 0.0, 0)
		if t >= Skills.WE_PILLAR + 0.3 and t < Skills.WE_IMPACT:
			emit(Vector2(_ix() + randf_range(-26.0, 26.0), GY - 2.0), Vector2(randf_range(-8.0, 8.0), randf_range(-90.0, -170.0)),
				randf_range(0.8, 1.5), 2.0, GOLD_HI if randf() < 0.6 else VIOLET, 0.0, 0.0, 1)
		if t >= Skills.WE_SWORD and t < Skills.WE_IMPACT:
			var tip := _sword_tip(t)
			var sy := randf_range(tip - BLADE_L, tip)
			emit(Vector2(_ix() + randf_range(-BLADE_W, BLADE_W), sy), Vector2(randf_range(-14.0, 14.0), randf_range(10.0, 50.0)), randf_range(0.5, 1.1), 2.2, GOLD, 40.0, 0.0, 0)
		if t >= Skills.WE_SWORD and t < Skills.WE_SHATTER:
			emit(Vector2(randf_range(vr.position.x, vr.end.x), vr.position.y), Vector2(randf_range(-12.0, 12.0), randf_range(40.0, 110.0)),
				randf_range(1.0, 1.8), randf_range(1.6, 3.2), Color(0.55, 0.45, 0.6, 0.9), 170.0, 0.0, 2, randf_range(-6.0, 6.0))
		if t >= Skills.WE_IMPACT and t < Skills.WE_SHATTER:
			emit(Vector2(_ix() + randf_range(-60.0, 60.0), GY - 2.0), Vector2(randf_range(-60.0, 60.0), randf_range(-160.0, -300.0)), randf_range(0.6, 1.2), 2.6, GOLD_HI, 220.0, 0.0, 1)


func _shade(ci: CanvasItem, t: float, bc: Vector2, _fade: float) -> void:
	var vr := view().grow(8.0)
	var dk := smoothstep(0.0, 1.4, t)
	var dk2 := smoothstep(Skills.WE_EYE0, Skills.WE_PILLAR + 0.5, t)
	var top := Color(0.02, 0.0, 0.07, (0.25 + 0.55 * dk2) * dk)
	var bot := Color(0.04, 0.0, 0.10, (0.12 + 0.28 * dk2) * dk)
	ci.draw_polygon(PackedVector2Array([vr.position, Vector2(vr.end.x, vr.position.y), vr.end, Vector2(vr.position.x, vr.end.y)]), PackedColorArray([top, top, bot, bot]))
	var open := _open(t)
	if open > 0.02:
		_eye_shade(ci, open)
	_pillar_shade(ci, t)
	_sword_body(ci, t)
	_aura_dark(ci, t, bc)
	_cracks(ci, t, false)


func _eye_shade(ci: CanvasItem, open: float) -> void:
	UD.poly(ci, _almond(open, 1.18), Color(0.02, 0.0, 0.06, 0.55), "eye_socket")
	UD.poly(ci, _almond(open), Color(0.01, 0.0, 0.04, 0.97), "eye")


func _pillar_shade(ci: CanvasItem, t: float) -> void:
	var pa := _pillar_alpha(t)
	if pa <= 0.01:
		return
	var ix := _ix()
	var top_y := _pillar_top()
	var y1 := _pillar_front(t)
	var open := smoothstep(Skills.WE_PILLAR, Skills.WE_PILLAR + 0.12, t)
	var hw := PILLAR_HW * (0.35 + 0.65 * pa) * open
	if hw < 0.5 or y1 - top_y < 2.0:
		return
	var n := 9
	for i in n:
		if i % 2 == 0:
			continue
		var u := (float(i) + 0.5) / float(n)
		var x := ix + (u - 0.5) * hw * 2.0 + sin(age * 2.0 + float(i) * 1.7) * hw * 0.1
		ci.draw_rect(Rect2(x - hw / float(n), top_y, hw * 2.3 / float(n), y1 - top_y), Color(0.05, 0.0, 0.11, 0.88 * pa))


func _pillar_ribbons(ci: CanvasItem, t: float) -> void:
	var pa := _pillar_alpha(t)
	if pa <= 0.01:
		return
	var ix := _ix()
	var top_y := _pillar_top()
	var y1 := _pillar_front(t)
	var open := smoothstep(Skills.WE_PILLAR, Skills.WE_PILLAR + 0.12, t)
	var hw := PILLAR_HW * (0.35 + 0.65 * pa) * open
	if hw < 0.5 or y1 - top_y < 2.0:
		return
	for strand in 2:
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		var y := y1
		while y >= top_y:
			var cx := ix + sin(y * 0.05 + age * 9.0 + float(strand) * PI) * hw * 1.25
			var wd := hw * 0.34 * (0.6 + 0.4 * sin(y * 0.11 + age * 9.0))
			left.append(Vector2(cx - wd, y))
			right.append(Vector2(cx + wd, y))
			y -= 12.0
		if left.size() > 1:
			right.reverse()
			left.append_array(right)
			UD.poly(ci, left, Color(0.05, 0.0, 0.11, 0.88 * pa), "pillar_strand")


func _pillar_alpha(t: float) -> float:
	var a := smoothstep(Skills.WE_PILLAR, Skills.WE_PILLAR + 0.3, t)
	return a * (1.0 - 0.9 * smoothstep(Skills.WE_SWORD - 0.2, Skills.WE_SWORD + 1.0, t))


func _pillar_front(t: float) -> float:
	var u := clampf((t - Skills.WE_PILLAR) / 0.4, 0.0, 1.0)
	return lerpf(_pillar_top(), GY, 1.0 - pow(1.0 - u, 3.0))


func _sword_body(ci: CanvasItem, t: float) -> void:
	var sa := _sword_alpha(t)
	if sa <= 0.01:
		return
	var ix := _ix()
	var tip := _sword_tip(t)
	var bt := tip - BLADE_L
	var dkc := Color(0.74, 0.46, 0.10, sa)
	var lgc := Color(1.0, 0.80, 0.28, sa)
	var shoulder := tip - 34.0
	UD.poly(ci, PackedVector2Array([Vector2(ix, tip), Vector2(ix - BLADE_W, shoulder), Vector2(ix - BLADE_W, bt), Vector2(ix, bt)]), dkc, "bladeL")
	UD.poly(ci, PackedVector2Array([Vector2(ix, tip), Vector2(ix + BLADE_W, shoulder), Vector2(ix + BLADE_W, bt), Vector2(ix, bt)]), lgc, "bladeR")
	UD.poly(ci, PackedVector2Array([Vector2(ix, tip - 22.0), Vector2(ix - 4.5, tip - 40.0), Vector2(ix - 4.5, bt + 6.0), Vector2(ix + 4.5, bt + 6.0), Vector2(ix + 4.5, tip - 40.0)]), Color(1.0, 0.93, 0.62, sa), "fuller")
	var y := tip - 52.0
	while y > bt + 10.0:
		ci.draw_line(Vector2(ix - BLADE_W * 0.7, y), Vector2(ix - 6.0, y), Color(0.55, 0.32, 0.06, 0.8 * sa), 1.0)
		ci.draw_line(Vector2(ix + 6.0, y - 3.0), Vector2(ix + BLADE_W * 0.7, y - 3.0), Color(0.55, 0.32, 0.06, 0.8 * sa), 1.0)
		y -= 15.0
	var gy := bt
	for sgn in [-1.0, 1.0]:
		var s: float = sgn
		UD.poly(ci, PackedVector2Array([Vector2(ix + s * BLADE_W * 0.6, gy - 7.0), Vector2(ix + s * GUARD_W * 0.8, gy - 15.0), Vector2(ix + s * GUARD_W * 1.15, gy - 28.0),
			Vector2(ix + s * GUARD_W * 1.1, gy + 3.0), Vector2(ix + s * GUARD_W * 0.5, gy + 8.0), Vector2(ix + s * BLADE_W * 0.6, gy + 7.0)]), Color(0.92, 0.68, 0.18, sa), "guard")
	ci.draw_rect(Rect2(ix - GUARD_W * 0.55, gy - 8.0, GUARD_W * 1.1, 15.0), Color(1.0, 0.78, 0.24, sa))
	ci.draw_rect(Rect2(ix - 6.0, gy - 44.0, 12.0, 38.0), Color(0.22, 0.08, 0.30, sa))
	for k in 5:
		ci.draw_line(Vector2(ix - 6.0, gy - 40.0 + float(k) * 7.5), Vector2(ix + 6.0, gy - 36.0 + float(k) * 7.5), Color(1.0, 0.8, 0.3, sa), 1.4)
	ci.draw_circle(Vector2(ix, gy - 50.0), 9.0, Color(1.0, 0.8, 0.26, sa))
	ci.draw_circle(Vector2(ix, gy), 6.5, Color(0.3, 0.05, 0.55, sa))
	ci.draw_circle(Vector2(ix, gy - 50.0), 4.0, Color(0.3, 0.05, 0.55, sa))


func _aura_dark(ci: CanvasItem, t: float, bc: Vector2) -> void:
	var k := smoothstep(0.0, 1.0, t) * (1.0 - smoothstep(Skills.WE_SHATTER - 0.3, Skills.WE_SHATTER, t))
	if k <= 0.01:
		return
	for i in 10:
		var base := bc + Vector2(-16.0 + float(i) * 3.6, 4.0 + 6.0 * sin(float(i) * 2.1))
		var h := (34.0 + 26.0 * fposmod(float(i) * 0.37, 1.0)) * (1.0 + 0.5 * smoothstep(Skills.WE_PILLAR, Skills.WE_SWORD, t))
		var pts := PackedVector2Array()
		for j in 8:
			var u := float(j) / 7.0
			pts.append(base + Vector2(sin(age * 3.0 + float(i) + u * 4.0) * 7.0 * u, -u * h))
		UD.taper(ci, pts, 5.0, Color(0.06, 0.0, 0.13, 0.7 * k), 2)


func _back(ci: CanvasItem, t: float, bc: Vector2, _fade: float) -> void:
	_sigil(ci, t, bc)
	_aura_light(ci, t, bc)
	var open := _open(t)
	if open > 0.02:
		_eye_light(ci, t, open, bc)
	_sword_light(ci, t)


func _sigil(ci: CanvasItem, t: float, bc: Vector2) -> void:
	var a := smoothstep(0.0, 0.7, t) * (1.0 - smoothstep(Skills.WE_SHATTER - 0.3, Skills.WE_SHATTER, t))
	if a <= 0.01:
		return
	var c := Vector2(bc.x, GY - 2.0)
	UD.ellipse(ci, c, 58.0, 0.24, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.85 * a), 2.0)
	UD.ellipse(ci, c, 42.0, 0.24, Color(GOLD.r, GOLD.g, GOLD.b, 0.85 * a), 1.6)
	UD.dashed_ellipse(ci, c, 72.0, 0.24, t * 1.6, Color(GOLD.r, GOLD.g, GOLD.b, 0.6 * a), 1.5, 18, 0.5)
	UD.dashed_ellipse(ci, c, 50.0, 0.24, -t * 2.2, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.7 * a), 1.4, 10, 0.6)
	UD.hex(ci, c, 36.0, t * 0.8, Color(GOLD_HI.r, GOLD_HI.g, GOLD_HI.b, 0.55 * a), 1.0, 0.24)
	var a2 := smoothstep(Skills.WE_PILLAR, Skills.WE_PILLAR + 0.8, t) * (1.0 - smoothstep(Skills.WE_SHATTER - 0.3, Skills.WE_SHATTER, t))
	if a2 > 0.01:
		var ip := Vector2(_ix(), GY - 2.0)
		var grow := 1.0 + 0.9 * smoothstep(Skills.WE_SWORD, Skills.WE_IMPACT, t)
		UD.ellipse(ci, ip, 62.0 * grow, 0.24, Color(GOLD.r, GOLD.g, GOLD.b, 0.8 * a2), 2.0)
		UD.ellipse(ci, ip, 44.0 * grow, 0.24, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.85 * a2), 1.5)
		UD.dashed_ellipse(ci, ip, 82.0 * grow, 0.24, -t * 1.2, Color(GOLD_HI.r, GOLD_HI.g, GOLD_HI.b, 0.55 * a2), 1.6, 16, 0.55)
		UD.glow(ci, ip + Vector2(0, -4), 70.0 * grow, Color(1.0, 0.8, 0.35, 1.0), 0.3 * a2)


func _aura_light(ci: CanvasItem, t: float, bc: Vector2) -> void:
	var k := smoothstep(0.0, 1.0, t) * (1.0 - smoothstep(Skills.WE_SHATTER - 0.3, Skills.WE_SHATTER, t))
	if k <= 0.01:
		return
	var surge := 1.0 + 0.9 * smoothstep(Skills.WE_PILLAR, Skills.WE_SWORD, t)
	var pul := 0.5 + 0.5 * sin(t * 6.0)
	UD.glow(ci, bc + Vector2(0, -4), (48.0 + 5.0 * pul) * surge, VIOLET, 0.42 * k)
	UD.glow(ci, bc + Vector2(0, -2), 30.0 * surge, Color(1.0, 0.8, 0.3, 1.0), 0.38 * k)
	for i in 10:
		var base := bc + Vector2(-17.0 + float(i) * 3.8, 5.0 + 5.0 * sin(float(i) * 1.7))
		var h := (38.0 + 30.0 * fposmod(float(i) * 0.53, 1.0)) * surge
		var pts := PackedVector2Array()
		for j in 8:
			var u := float(j) / 7.0
			pts.append(base + Vector2(sin(age * 3.4 + float(i) * 1.3 + u * 4.0) * 8.0 * u, -u * h))
		var col := GOLD if i % 2 == 0 else VIOLET
		UD.taper(ci, pts, 4.0, Color(col.r, col.g, col.b, 0.5 * k), 2)
	var hc := bc + Vector2(1.0, -16.0)
	ci.draw_arc(hc, 17.0, t * 1.2, t * 1.2 + TAU * 0.8, 30, Color(GOLD.r, GOLD.g, GOLD.b, 0.85 * k), 1.6)
	ci.draw_arc(hc, 21.0, -t * 0.9, -t * 0.9 + TAU * 0.6, 30, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.8 * k), 1.2)
	for i in 12:
		var an := float(i) * TAU / 12.0 + t * 0.5
		var d := Vector2(cos(an), sin(an))
		ci.draw_line(hc + d * 23.0, hc + d * (29.0 + 4.0 * sin(t * 7.0 + float(i))), Color(GOLD_HI.r, GOLD_HI.g, GOLD_HI.b, 0.55 * k), 1.0)


func _arc_clipped(ci: CanvasItem, c: Vector2, r: float, col: Color, wd: float, open: float, off: Vector2 = Vector2.ZERO) -> void:
	var ec := _eye_c()
	var wh := _eye_half().x
	var prev := Vector2.ZERO
	var has := false
	for k in 49:
		var a := float(k) / 48.0 * TAU
		var q := c + off + Vector2(cos(a), sin(a)) * r
		var u := (q.x - ec.x) / wh
		var ok := absf(u) < 0.99 and q.y > ec.y + _lid(u, open, true) and q.y < ec.y + _lid(u, open, false)
		if ok and has:
			ci.draw_line(prev, q, col, wd)
		prev = q
		has = ok


func _sun(ci: CanvasItem, t: float) -> void:
	var sk := _sun_k(t)
	if sk <= 0.01:
		return
	var a := minf(sk, 1.0)
	var ec := _eye_c()
	var eh := _eye_half()
	var reach := view().size.length() * 0.95
	var pul := 1.0 + 0.05 * sin(age * 7.0) + 0.025 * sin(age * 13.0)
	var grow := 1.0 + 0.25 * maxf(0.0, sk - 1.0)
	UD.glow(ci, ec, eh.x * 3.2 * pul * grow, Color(1.0, 0.5, 0.12), 0.50 * a)
	UD.glow(ci, ec, eh.x * 2.1 * pul * grow, Color(1.0, 0.76, 0.28), 0.65 * a)
	UD.glow(ci, ec, eh.x * 1.25 * pul * grow, Color(1.0, 0.92, 0.62), 0.75 * a)
	UD.glow(ci, ec, eh.x * 0.62 * pul * grow, Color(1.0, 1.0, 0.95), 0.8 * a)
	for grp in 2:
		var n := 22
		var dir_s := 1.0 if grp == 0 else -1.0
		for i in n:
			var h := fposmod(sin(float(i * 37 + grp * 91)) * 43758.5, 1.0)
			var ang := (float(i) + 0.5 * float(grp)) * TAU / float(n) + age * 0.10 * dir_s + h * 0.2
			var ln := reach * (0.45 + 0.55 * h) * (0.82 + 0.18 * sin(age * 3.0 + float(i))) * minf(sk, 1.2)
			var hw := 0.028 + 0.034 * h
			var d0 := Vector2(cos(ang - hw), sin(ang - hw))
			var d1 := Vector2(cos(ang + hw), sin(ang + hw))
			var r0 := eh.x * 0.35
			var bc0 := Color(1.0, 0.92, 0.58, 0.34 * a) if grp == 0 else Color(1.0, 0.72, 0.32, 0.24 * a)
			var tc := Color(bc0.r, bc0.g, bc0.b, 0.0)
			ci.draw_polygon(PackedVector2Array([ec + d0 * r0, ec + d1 * r0, ec + d1 * ln, ec + d0 * ln]), PackedColorArray([bc0, bc0, tc, tc]))
	ci.draw_arc(ec, eh.x * 1.2 * pul, 0.0, TAU, 72, Color(1.0, 0.92, 0.6, 0.30 * a), 2.0)
	ci.draw_arc(ec, eh.x * 1.7 * pul, age * 0.2, age * 0.2 + TAU * 0.85, 72, Color(1.0, 0.8, 0.4, 0.18 * a), 1.5)


func _sun_front(ci: CanvasItem, t: float) -> void:
	var sk := _sun_k(t)
	if sk <= 0.01:
		return
	var a := minf(sk, 1.0)
	var ec := _eye_c()
	var eh := _eye_half()
	var pul := 1.0 + 0.05 * sin(age * 8.0)
	UD.glow(ci, ec, eh.x * 0.8 * pul, Color(1.0, 0.97, 0.85), 0.35 * a)
	UD.glow(ci, ec, view().size.x * 0.8, Color(1.0, 0.82, 0.45), 0.06 * a)


func _eye_light(ci: CanvasItem, t: float, open: float, bc: Vector2) -> void:
	var ec := _eye_c()
	var eh := _eye_half()
	var o := clampf(open, 0.0, 1.2)
	_sun(ci, t)
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for k in 33:
		var u := -1.0 + 2.0 * float(k) / 32.0
		top.append(ec + Vector2(u * eh.x, _lid(u, o, true)))
		bot.append(ec + Vector2(u * eh.x, _lid(u, o, false)))
	ci.draw_polyline(top, Color(GOLD.r, GOLD.g, GOLD.b, 0.35), 5.0)
	ci.draw_polyline(top, Color(GOLD_HI.r, GOLD_HI.g, GOLD_HI.b, 0.95), 1.8)
	ci.draw_polyline(bot, Color(GOLD_HI.r, GOLD_HI.g, GOLD_HI.b, 0.8), 1.4)
	if o < 0.05:
		return
	var look := (bc - ec).normalized() * eh.y * 0.28
	var ri := eh.y * 0.82 * minf(o, 1.0)
	var pulse := 0.85 + 0.15 * sin(age * 5.0)
	_arc_clipped(ci, ec, ri, Color(GOLD.r, GOLD.g, GOLD.b, 0.95 * pulse), 3.0, o, look)
	_arc_clipped(ci, ec, ri * 0.82, Color(1.0, 0.6, 0.15, 0.8), 2.0, o, look)
	_arc_clipped(ci, ec, ri * 0.62, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.9), 2.0, o, look)
	for i in 36:
		var an := float(i) / 36.0 * TAU
		var d := Vector2(cos(an), sin(an))
		var a0 := ec + look + d * ri * 0.4
		var a1 := ec + look + d * ri * 0.98
		var ok := absf((a1.x - ec.x) / eh.x) < 0.99 and a1.y > ec.y + _lid((a1.x - ec.x) / eh.x, o, true) and a1.y < ec.y + _lid((a1.x - ec.x) / eh.x, o, false)
		if ok:
			ci.draw_line(a0, a1, Color(GOLD.r, GOLD.g, GOLD.b, 0.35 + 0.25 * sin(age * 4.0 + float(i))), 1.0)
	var ph := eh.y * 0.95 * minf(o, 1.0)
	var pw := ri * 0.16
	var pc := ec + look
	var slit := PackedVector2Array([pc + Vector2(0, -ph), pc + Vector2(pw, 0), pc + Vector2(0, ph * 0.8), pc + Vector2(-pw, 0), pc + Vector2(0, -ph)])
	ci.draw_polyline(slit, Color(1.0, 0.97, 0.8, 0.95), 1.6)
	var birth := smoothstep(Skills.WE_PILLAR + 0.5, Skills.WE_SWORD, t) * (1.0 - smoothstep(Skills.WE_SWORD, Skills.WE_SWORD + 1.2, t))
	if birth > 0.01:
		UD.glow(ci, pc, 30.0 + 40.0 * birth, GOLD_HI, 0.9 * birth)


func _pillar_light(ci: CanvasItem, t: float) -> void:
	var pa := _pillar_alpha(t)
	if pa <= 0.01:
		return
	var ix := _ix()
	var top_y := _pillar_top()
	var y1 := _pillar_front(t)
	var h := y1 - top_y
	if h < 2.0:
		return
	var open := smoothstep(Skills.WE_PILLAR, Skills.WE_PILLAR + 0.12, t)
	var hw := PILLAR_HW * (1.0 + 0.05 * sin(age * 9.0)) * (0.35 + 0.65 * pa) * open
	if hw < 0.5:
		return
	ci.draw_texture_rect(TexGen.glow_tex(64), Rect2(ix - hw * 3.4, top_y, hw * 6.8, h), false, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.30 * pa))
	ci.draw_rect(Rect2(ix - hw * 1.9, top_y, hw * 3.8, h), Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.16 * pa))
	ci.draw_rect(Rect2(ix - hw * 1.15, top_y, hw * 2.3, h), Color(1.0, 0.82, 0.3, 0.36 * pa))
	ci.draw_line(Vector2(ix - hw * 1.15, top_y), Vector2(ix - hw * 1.15, y1), Color(1.0, 0.93, 0.6, 0.85 * pa), 1.6)
	ci.draw_line(Vector2(ix + hw * 1.15, top_y), Vector2(ix + hw * 1.15, y1), Color(1.0, 0.93, 0.6, 0.85 * pa), 1.6)
	var n := 9
	for i in n:
		if i % 2 == 1:
			continue
		var u := (float(i) + 0.5) / float(n)
		var x := ix + (u - 0.5) * hw * 2.0 + sin(age * 2.0 + float(i) * 1.7) * hw * 0.1
		ci.draw_rect(Rect2(x - hw / float(n), top_y, hw * 2.3 / float(n), h), Color(1.0, 0.9, 0.5, 0.45 * pa))
	ci.draw_rect(Rect2(ix - hw * 0.42, top_y, hw * 0.84, h), Color(1.0, 0.97, 0.82, 0.95 * pa))
	ci.draw_rect(Rect2(ix - hw * 0.16, top_y, hw * 0.32, h), Color(1.0, 1.0, 1.0, 0.95 * pa))
	var pts := PackedVector2Array()
	var y := y1
	while y >= top_y:
		pts.append(Vector2(ix + sin(y * 0.05 + age * 9.0) * hw * 1.05, y))
		y -= 12.0
	if pts.size() > 1:
		ci.draw_polyline(pts, Color(1.0, 0.95, 0.7, 0.9 * pa), 2.4)
	var head := 1.0 - smoothstep(Skills.WE_PILLAR + 0.25, Skills.WE_PILLAR + 0.5, t)
	if head > 0.01:
		UD.glow(ci, Vector2(ix, y1), hw * 2.6, GOLD_HI, 0.9 * head * pa)
	UD.glow(ci, Vector2(ix, GY - 4.0), 104.0, Color(1.0, 0.85, 0.4, 1.0), 0.65 * pa)
	UD.glow(ci, Vector2(ix, GY - 4.0), 70.0, Color(0.7, 0.4, 1.0, 1.0), 0.5 * pa)
	UD.ellipse(ci, Vector2(ix, GY - 2.0), hw * 1.7 + 4.0 * sin(age * 9.0), 0.24, Color(1.0, 0.9, 0.5, 0.85 * pa), 2.0)
	UD.ellipse(ci, Vector2(ix, GY - 2.0), hw * 1.1, 0.24, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.85 * pa), 1.6)


func _sword_light(ci: CanvasItem, t: float) -> void:
	var sa := _sword_alpha(t)
	if sa <= 0.01:
		return
	var ix := _ix()
	var tip := _sword_tip(t)
	var bt := tip - BLADE_L
	var imp := smoothstep(Skills.WE_IMPACT - 0.2, Skills.WE_IMPACT + 0.3, t)
	UD.glow(ci, Vector2(ix, (tip + bt) * 0.5), BLADE_L * 0.7, Color(1.0, 0.75, 0.25, 1.0), (0.10 + 0.20 * imp) * sa)
	ci.draw_texture_rect(TexGen.glow_tex(64), Rect2(ix - BLADE_W * 2.4, bt - 20.0, BLADE_W * 4.8, BLADE_L + 40.0), false, Color(1.0, 0.8, 0.3, 0.10 * sa))
	ci.draw_line(Vector2(ix + BLADE_W, tip - 34.0), Vector2(ix + BLADE_W, bt), Color(1, 1, 0.9, 0.9 * sa), 1.4)
	ci.draw_line(Vector2(ix + BLADE_W, tip - 34.0), Vector2(ix, tip), Color(1, 1, 0.9, 0.9 * sa), 1.4)
	ci.draw_line(Vector2(ix - BLADE_W, tip - 34.0), Vector2(ix, tip), Color(1.0, 0.9, 0.6, 0.6 * sa), 1.0)
	UD.glow(ci, Vector2(ix, tip), 18.0 + 30.0 * imp, GOLD_HI, 0.5 * sa)
	UD.glow(ci, Vector2(ix, bt), 28.0, VIOLET, 0.6 * sa)
	if imp > 0.01:
		var len2 := 150.0 * imp
		ci.draw_line(Vector2(ix - len2, GY - 2.0), Vector2(ix + len2, GY - 2.0), Color(1.0, 0.95, 0.7, 0.8 * imp), 2.0)
		ci.draw_line(Vector2(ix, GY - len2 * 0.8), Vector2(ix, GY), Color(1.0, 0.95, 0.7, 0.5 * imp), 1.5)


func _crack_reach(i: int, t: float) -> float:
	var step := TAU / float(WEMesh.SECTORS)
	var ang := float(i) * step
	var ground := sin(ang) > -0.25
	var g := clampf((t - Skills.WE_IMPACT) / (Skills.WE_SHATTER - Skills.WE_IMPACT - 0.2), 0.0, 1.0)
	var gi := clampf(g * 1.8 - (0.0 if ground else 0.7), 0.0, 1.0)
	return gi * float(WEMesh.RINGS)


func _cracks(ci: CanvasItem, t: float, glow: bool) -> void:
	if t < Skills.WE_IMPACT:
		return
	var m = p._cine.get("mesh")
	if m == null:
		return
	var v: PackedVector2Array = m
	var o := Vector2(_ix(), GY)
	for i in WEMesh.SECTORS:
		var f := _crack_reach(i, t)
		if f <= 0.0:
			continue
		var pts := PackedVector2Array([o])
		var j := 1
		while float(j) <= f and j <= WEMesh.RINGS:
			pts.append(o + v[WEMesh.idx(i, j)])
			j += 1
		var frac := f - floorf(f)
		if j <= WEMesh.RINGS and frac > 0.0:
			var last := pts[pts.size() - 1]
			pts.append(last.lerp(o + v[WEMesh.idx(i, j)], frac))
		if glow:
			ci.draw_polyline(pts, Color(GOLD.r, GOLD.g, GOLD.b, 0.28), 5.0)
			ci.draw_polyline(pts, Color(GOLD_HI.r, GOLD_HI.g, GOLD_HI.b, 0.95), 1.6)
		else:
			ci.draw_polyline(pts, Color(0.02, 0.0, 0.05, 0.9), 4.5)
		for jj in range(1, WEMesh.RINGS + 1):
			if f < float(jj) or _crack_reach(i + 1, t) < float(jj):
				continue
			if fposmod(sin(float(i * 31 + jj * 17)) * 43758.5, 1.0) < 0.25:
				continue
			var a := o + v[WEMesh.idx(i, jj)]
			var b := o + v[WEMesh.idx(i + 1, jj)]
			if glow:
				ci.draw_line(a, b, Color(GOLD.r, GOLD.g, GOLD.b, 0.25), 4.0)
				ci.draw_line(a, b, Color(GOLD_HI.r, GOLD_HI.g, GOLD_HI.b, 0.9), 1.3)
			else:
				ci.draw_line(a, b, Color(0.02, 0.0, 0.05, 0.9), 3.5)


func _front(ci: CanvasItem, t: float, bc: Vector2, _fade: float) -> void:
	_sun_front(ci, t)
	_pillar_light(ci, t)
	var g := smoothstep(Skills.WE_GLOW - 0.2, Skills.WE_GLOW + 0.5, t) * (1.0 - smoothstep(Skills.WE_SHATTER - 0.3, Skills.WE_SHATTER, t))
	if g > 0.01:
		for ex in [1.4, 3.7]:
			var e: Vector2 = bc + Vector2(float(ex), -12.6)
			UD.glow(ci, e, 9.0 + 5.0 * sin(t * 9.0), Color(1.0, 0.85, 0.35, 1.0), 0.95 * g)
			ci.draw_line(e - Vector2(26.0 * g, 0), e + Vector2(26.0 * g, 0), Color(1.0, 0.9, 0.5, 0.8 * g), 1.2)
			ci.draw_line(e - Vector2(0, 9.0 * g), e + Vector2(0, 9.0 * g), Color(1.0, 0.9, 0.5, 0.6 * g), 1.0)
	_cracks(ci, t, true)
	if t >= Skills.WE_IMPACT and t < Skills.WE_IMPACT + 1.2:
		var f := exp(-(t - Skills.WE_IMPACT) * 3.0)
		UD.glow(ci, Vector2(_ix(), GY - 4.0), 220.0 * (0.5 + f), Color(1.0, 0.95, 0.7, 1.0), 0.85 * f)
