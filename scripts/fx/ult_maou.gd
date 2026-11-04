extends "res://scripts/fx/ult_dir.gd"

const GOLD := Color(1.0, 0.84, 0.36)
const GOLD_HI := Color(1.0, 0.96, 0.74)
const VIOLET := Color(0.62, 0.30, 1.0)
const SWORD_S := 1.8  # skala pedang dunia nyata (setara kesan pedang di kota)
const BLADE_W := 24.0 * SWORD_S
const BLADE_L := 188.0 * SWORD_S
const GUARD_W := 62.0 * SWORD_S
const PILLAR_HW := 34.0
const PILLAR_OVER := 260.0

var _acc := 0.0
var sun_light: PointLight2D
var dark_top: Node2D
var sky: Node2D


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
	sky = Node2D.new()
	sky.material = Fx.unshaded_mat()
	sky.z_as_relative = false
	sky.z_index = 21
	sky.draw.connect(_on_sky_draw)
	add_child(sky)


func _light_energy(t: float) -> float:
	var e := 0.5 + 0.6 * smoothstep(0.0, 6.0, t) + 0.9 * smoothstep(Skills.WE_IGNITE, Skills.WE_IGNITE + 3.0, t)
	e += 1.3 * smoothstep(Skills.WE_PILLAR, Skills.WE_PILLAR + 0.5, t)
	e *= 1.0 - 0.75 * smoothstep(Skills.WE_ASCEND, Skills.WE_ASCEND + 1.0, t)
	e += 1.4 * smoothstep(Skills.WE_FALL, Skills.WE_IMPACT, t) * (1.0 - smoothstep(Skills.WE_IMPACT - 0.5, Skills.WE_IMPACT, t))
	if t >= Skills.WE_IMPACT:
		e += 3.5 * exp(-(t - Skills.WE_IMPACT) * 1.8)
	return e


func _ix() -> float:
	return p.pivot.global_position.x + Skills.WE_DX


func _eye_c() -> Vector2:
	var vr := view()
	return Vector2(p.pivot.global_position.x + Skills.WE_EYE_DX, vr.position.y + vr.size.y * 0.25)


func _eye_half() -> Vector2:
	var vr := view()
	return Vector2(vr.size.x * 0.25, vr.size.y * 0.19)


# pusat & radius lingkaran sihir mata (iris): sama persis dengan yang digambar di _eye_light
func _iris_c() -> Vector2:
	var ec := _eye_c()
	return ec + (p.pivot.global_position - ec).normalized() * _eye_half().y * 0.28


func _iris_r() -> float:
	return _eye_half().y * 0.82


func _on_sky_draw() -> void:
	if w == null or p == null or not is_instance_valid(p):
		return
	_sky(sky, p.ultimate_elapsed)


func _on_dark_top_draw() -> void:
	if w == null or p == null or not is_instance_valid(p):
		return
	_pillar_ribbons(dark_top, p.ultimate_elapsed)
	_city_ribbons(dark_top, p.ultimate_elapsed)


func _sun_k(t: float) -> float:
	var up := smoothstep(Skills.WE_EYE0 + 0.2, Skills.WE_EYE1, t)
	var boost := 1.0 + 0.35 * smoothstep(Skills.WE_PILLAR, Skills.WE_PILLAR + 0.5, t)
	return up * boost * (1.0 - smoothstep(Skills.WE_ASCEND - 0.8, Skills.WE_ASCEND + 0.3, t))


func _pillar_top() -> float:
	return view().position.y - PILLAR_OVER


func _open(t: float) -> float:
	var u := smoothstep(Skills.WE_EYE0, Skills.WE_EYE1, t)
	return (u + 0.12 * sin(u * PI)) * (1.0 - smoothstep(Skills.WE_ASCEND - 0.6, Skills.WE_ASCEND + 0.3, t))


func _sword_tip(t: float) -> float:
	var y0 := view().position.y - BLADE_L - 30.0
	var u := clampf((t - (Skills.WE_IMPACT - 0.4)) / 0.4, 0.0, 1.0)
	return lerpf(y0, GY, pow(u, 1.5))


func _sword_alpha(t: float) -> float:
	return smoothstep(Skills.WE_IMPACT - 0.45, Skills.WE_IMPACT - 0.3, t)


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
	sun_light.position = _iris_c()
	dark_top.queue_redraw()
	sky.queue_redraw()
	# sinar radial layar: berpusat di lingkaran mata (setelah mata terbuka), di karakter sebelum itu; mati di adegan kota
	var rv := view()
	var eye_uv := (_iris_c() - rv.position) / rv.size
	var bc_uv := (bc - rv.position) / rv.size
	var eu := smoothstep(Skills.WE_EYE0 - 0.5, Skills.WE_EYE0 + 1.5, t) * (1.0 - smoothstep(Skills.WE_ASCEND - 1.0, Skills.WE_ASCEND, t))
	w.fx_ray_center = bc_uv.lerp(eye_uv, eu)
	w.fx_rays_cap = 1.0 - _sky_alpha(t)
	var sky_on := _sky_alpha(t) > 0.01
	if sky_on:
		parts.clear()
	sun_light.energy = minf(sk, 1.4) * 1.3 * _fade_now()
	if sk > 0.3 and t < Skills.WE_IMPACT:
		w.fx_flash = maxf(w.fx_flash, (0.035 + 0.015 * sin(age * 6.0)) * minf(sk, 1.0))
	while _acc >= 0.04:
		_acc -= 0.04
		if sky_on:
			continue
		if sk > 0.2:
			var sa := randf() * TAU
			var sd := Vector2(cos(sa), sin(sa))
			emit(_iris_c() + sd * _eye_half().x * randf_range(0.3, 1.1), sd * randf_range(30.0, 95.0), randf_range(0.8, 1.7), randf_range(1.6, 2.6), GOLD_HI if randf() < 0.7 else GOLD, 0.0, 0.0, 0)
		var a := randf() * TAU
		emit(bc + Vector2(cos(a) * randf_range(7.0, 24.0), randf_range(-18.0, 14.0)), Vector2(randf_range(-10.0, 10.0), randf_range(-70.0, -130.0)),
			randf_range(0.6, 1.2), 2.0, GOLD if randf() < 0.5 else VIOLET, 0.0, 0.0, 0)
		if t >= Skills.WE_PILLAR + 0.3 and t < Skills.WE_ASCEND:
			emit(Vector2(_ix() + randf_range(-26.0, 26.0), GY - 2.0), Vector2(randf_range(-8.0, 8.0), randf_range(-90.0, -170.0)),
				randf_range(0.8, 1.5), 2.0, GOLD_HI if randf() < 0.6 else VIOLET, 0.0, 0.0, 1)
		if t >= Skills.WE_IGNITE and t < Skills.WE_ASCEND:
			var ig := smoothstep(Skills.WE_IGNITE, Skills.WE_BURST, t)
			for k in 1 + int(ig * 3.0):
				emit(bc + Vector2(randf_range(-30.0, 30.0), 10.0), Vector2(randf_range(-26.0, 26.0), randf_range(-120.0, -260.0) * (0.6 + 0.6 * ig)),
					randf_range(0.7, 1.5), randf_range(1.4, 2.8), GOLD_HI if randf() < 0.6 else GOLD, 0.0, 0.0, 1)
		if t >= Skills.WE_BURST and t < Skills.WE_ASCEND and t >= Skills.WE_BURST - 0.1:
			emit(Vector2(randf_range(vr.position.x, vr.end.x), vr.end.y), Vector2(randf_range(-14.0, 14.0), randf_range(-70.0, -150.0)),
				randf_range(1.2, 2.4), randf_range(1.6, 3.0), Color(0.55, 0.45, 0.6, 0.9), -4.0, 0.0, 2, randf_range(-5.0, 5.0))
		if t >= Skills.WE_IMPACT and t < Skills.WE_SHATTER:
			emit(Vector2(_ix() + randf_range(-60.0, 60.0), GY - 2.0), Vector2(randf_range(-60.0, 60.0), randf_range(-160.0, -300.0)), randf_range(0.6, 1.2), 2.6, GOLD_HI, 220.0, 0.0, 1)


func _shade(ci: CanvasItem, t: float, bc: Vector2, _fade: float) -> void:
	var vr := view().grow(8.0)
	var dk := smoothstep(0.0, 3.0, t)
	var dk2 := smoothstep(Skills.WE_IGNITE, Skills.WE_PILLAR + 0.5, t)
	var top := Color(0.02, 0.0, 0.07, (0.5 + 0.38 * dk2) * dk)
	var bot := Color(0.04, 0.0, 0.10, (0.3 + 0.3 * dk2) * dk)
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
	var by := p.pivot.global_position.y
	for strand in 2:
		var y := y1
		var px := 0.0
		var pwd := 0.0
		var py := y1
		var first := true
		while y >= top_y:
			var cx := ix + sin(y * 0.05 + age * 9.0 + float(strand) * PI) * hw * 1.25
			var wd := hw * 0.34 * (0.6 + 0.4 * sin(y * 0.11 + age * 9.0))
			if not first:
				# menipis (bukan terpotong) di sekitar tubuh karakter supaya siluetnya tetap terlihat
				var fade := clampf((absf((y + py) * 0.5 - by) - 8.0) / 46.0, 0.0, 1.0)
				fade = 0.15 + 0.85 * fade
				UD.poly(ci, PackedVector2Array([Vector2(px - pwd, py), Vector2(px + pwd, py), Vector2(cx + wd, y), Vector2(cx - wd, y)]),
					Color(0.05, 0.0, 0.11, 0.88 * pa * fade), "pillar_strand")
			px = cx
			pwd = wd
			py = y
			first = false
			y -= 12.0


func _pillar_alpha(t: float) -> float:
	var a := smoothstep(Skills.WE_PILLAR, Skills.WE_PILLAR + 0.3, t)
	return a * (1.0 - smoothstep(Skills.WE_ASCEND - 1.0, Skills.WE_ASCEND, t))


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
	var S := SWORD_S
	var shoulder := tip - 34.0 * S
	UD.poly(ci, PackedVector2Array([Vector2(ix, tip), Vector2(ix - BLADE_W, shoulder), Vector2(ix - BLADE_W, bt), Vector2(ix, bt)]), dkc, "bladeL")
	UD.poly(ci, PackedVector2Array([Vector2(ix, tip), Vector2(ix + BLADE_W, shoulder), Vector2(ix + BLADE_W, bt), Vector2(ix, bt)]), lgc, "bladeR")
	UD.poly(ci, PackedVector2Array([Vector2(ix, tip - 22.0 * S), Vector2(ix - 4.5 * S, tip - 40.0 * S), Vector2(ix - 4.5 * S, bt + 6.0), Vector2(ix + 4.5 * S, bt + 6.0), Vector2(ix + 4.5 * S, tip - 40.0 * S)]), Color(1.0, 0.93, 0.62, sa), "fuller")
	var y := tip - 52.0 * S
	while y > bt + 10.0:
		ci.draw_line(Vector2(ix - BLADE_W * 0.7, y), Vector2(ix - 6.0 * S, y), Color(0.55, 0.32, 0.06, 0.8 * sa), 1.5)
		ci.draw_line(Vector2(ix + 6.0 * S, y - 3.0), Vector2(ix + BLADE_W * 0.7, y - 3.0), Color(0.55, 0.32, 0.06, 0.8 * sa), 1.5)
		y -= 15.0 * S
	var gy := bt
	for sgn in [-1.0, 1.0]:
		var s: float = sgn
		UD.poly(ci, PackedVector2Array([Vector2(ix + s * BLADE_W * 0.6, gy - 7.0 * S), Vector2(ix + s * GUARD_W * 0.8, gy - 15.0 * S), Vector2(ix + s * GUARD_W * 1.15, gy - 28.0 * S),
			Vector2(ix + s * GUARD_W * 1.1, gy + 3.0 * S), Vector2(ix + s * GUARD_W * 0.5, gy + 8.0 * S), Vector2(ix + s * BLADE_W * 0.6, gy + 7.0 * S)]), Color(0.92, 0.68, 0.18, sa), "guard")
	ci.draw_rect(Rect2(ix - GUARD_W * 0.55, gy - 8.0 * S, GUARD_W * 1.1, 15.0 * S), Color(1.0, 0.78, 0.24, sa))
	ci.draw_rect(Rect2(ix - 6.0 * S, gy - 44.0 * S, 12.0 * S, 38.0 * S), Color(0.22, 0.08, 0.30, sa))
	for k in 5:
		ci.draw_line(Vector2(ix - 6.0 * S, gy - 40.0 * S + float(k) * 7.5 * S), Vector2(ix + 6.0 * S, gy - 36.0 * S + float(k) * 7.5 * S), Color(1.0, 0.8, 0.3, sa), 1.4)
	ci.draw_circle(Vector2(ix, gy - 50.0 * S), 9.0 * S, Color(1.0, 0.8, 0.26, sa))
	ci.draw_circle(Vector2(ix, gy), 6.5 * S, Color(0.3, 0.05, 0.55, sa))
	ci.draw_circle(Vector2(ix, gy - 50.0 * S), 4.0 * S, Color(0.3, 0.05, 0.55, sa))


func _aura_dark(ci: CanvasItem, t: float, bc: Vector2) -> void:
	var k := smoothstep(0.0, 1.0, t) * (1.0 - smoothstep(Skills.WE_SHATTER - 0.3, Skills.WE_SHATTER, t))
	if k <= 0.01:
		return
	for i in 10:
		var base := bc + Vector2(-16.0 + float(i) * 3.6, 4.0 + 6.0 * sin(float(i) * 2.1))
		var h := (34.0 + 26.0 * fposmod(float(i) * 0.37, 1.0)) * (1.0 + 0.5 * smoothstep(Skills.WE_IGNITE, Skills.WE_BURST, t))
		var pts := PackedVector2Array()
		for j in 8:
			var u := float(j) / 7.0
			pts.append(base + Vector2(sin(age * 3.0 + float(i) + u * 4.0) * 7.0 * u, -u * h))
		UD.taper(ci, pts, 5.0, Color(0.06, 0.0, 0.13, 0.7 * k), 2)


func _back(ci: CanvasItem, t: float, bc: Vector2, _fade: float) -> void:
	_pillar_light(ci, t)
	_sigil(ci, t, bc)
	_aura_flames(ci, t, bc)
	_aura_light(ci, t, bc)
	var open := _open(t)
	if open > 0.02:
		_eye_light(ci, t, open, bc)
	_sword_light(ci, t)


func _sigil(ci: CanvasItem, t: float, bc: Vector2) -> void:
	var a := smoothstep(0.4, 4.0, t) * (1.0 - smoothstep(Skills.WE_SHATTER - 0.3, Skills.WE_SHATTER, t))
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
		var grow := 1.0 + 0.9 * smoothstep(Skills.WE_PILLAR, Skills.WE_ASCEND, t)
		UD.ellipse(ci, ip, 62.0 * grow, 0.24, Color(GOLD.r, GOLD.g, GOLD.b, 0.8 * a2), 2.0)
		UD.ellipse(ci, ip, 44.0 * grow, 0.24, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.85 * a2), 1.5)
		UD.dashed_ellipse(ci, ip, 82.0 * grow, 0.24, -t * 1.2, Color(GOLD_HI.r, GOLD_HI.g, GOLD_HI.b, 0.55 * a2), 1.6, 16, 0.55)
		UD.glow(ci, ip + Vector2(0, -4), 70.0 * grow, Color(1.0, 0.8, 0.35, 1.0), 0.3 * a2)


func _aura_light(ci: CanvasItem, t: float, bc: Vector2) -> void:
	var k := smoothstep(0.0, 1.0, t) * (1.0 - smoothstep(Skills.WE_SHATTER - 0.3, Skills.WE_SHATTER, t))
	if k <= 0.01:
		return
	var surge := 1.0 + 1.2 * smoothstep(Skills.WE_IGNITE, Skills.WE_BURST, t)
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
	var ec := _iris_c()
	var eh := _eye_half()
	var ri := _iris_r()
	var reach := view().size.length() * 0.95
	var pul := 1.0 + 0.05 * sin(age * 7.0) + 0.025 * sin(age * 13.0)
	var grow := 1.0 + 0.25 * maxf(0.0, sk - 1.0)
	UD.glow(ci, ec, eh.x * 3.2 * pul * grow, Color(1.0, 0.5, 0.12), 0.50 * a)
	UD.glow(ci, ec, eh.x * 2.1 * pul * grow, Color(1.0, 0.76, 0.28), 0.65 * a)
	UD.glow(ci, ec, eh.x * 1.25 * pul * grow, Color(1.0, 0.92, 0.62), 0.75 * a)
	UD.glow(ci, ec, ri * 1.25 * pul * grow, Color(1.0, 1.0, 0.95), 0.8 * a)
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
			var r0 := ri * 0.9
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
	var ec := _iris_c()
	var pul := 1.0 + 0.05 * sin(age * 8.0)
	UD.glow(ci, ec, _iris_r() * 1.1 * pul, Color(1.0, 0.97, 0.85), 0.35 * a)
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
	var birth := smoothstep(Skills.WE_ASCEND - 1.8, Skills.WE_ASCEND - 0.3, t) * (1.0 - smoothstep(Skills.WE_ASCEND - 0.3, Skills.WE_ASCEND + 0.6, t))
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
	ci.draw_line(Vector2(ix + BLADE_W, tip - 34.0 * SWORD_S), Vector2(ix + BLADE_W, bt), Color(1, 1, 0.9, 0.9 * sa), 1.4)
	ci.draw_line(Vector2(ix + BLADE_W, tip - 34.0 * SWORD_S), Vector2(ix, tip), Color(1, 1, 0.9, 0.9 * sa), 1.4)
	ci.draw_line(Vector2(ix - BLADE_W, tip - 34.0 * SWORD_S), Vector2(ix, tip), Color(1.0, 0.9, 0.6, 0.6 * sa), 1.0)
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
	_burst_fx(ci, t, bc)
	_sun_front(ci, t)
	_halo(ci, t)
	_prism(ci, t)
	_city_pillar(ci, t)
	_bolts(ci, t)
	_sky_sword_glow(ci, t)
	_fall_fx(ci, t)
	var g := smoothstep(Skills.WE_GLOW - 0.2, Skills.WE_GLOW + 0.5, t) * (1.0 - smoothstep(Skills.WE_SHATTER - 0.3, Skills.WE_SHATTER, t)) * (1.0 - _sky_alpha(t))
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


# =====================================================================
#  ADEGAN BARU (timeline panjang 71,7 dtk)
# =====================================================================
const PRISM_COLS := [Color(0.2, 0.95, 1.0), Color(1.0, 0.25, 0.7), Color(1.0, 0.92, 0.2), Color(1.0, 0.5, 0.15), Color(0.5, 1.0, 0.35), Color(1.0, 1.0, 1.0)]
const BOLT_AT := [0.0, 0.2, 0.9]
const SB_L := 175.0
const SB_W := 19.0
const NIGHT_TOP := Color(0.012, 0.025, 0.07)
const NIGHT_MID := Color(0.035, 0.075, 0.15)
const NIGHT_HOR := Color(0.11, 0.18, 0.28)


func _h(i: int, s: float = 0.0) -> float:
	return fposmod(sin(float(i) * 12.9898 + s * 78.233) * 43758.5453, 1.0)


func _cx() -> float:
	var vr := view()
	return vr.position.x + vr.size.x * 0.5


# ---------- Aura api emas (Act II-V) ----------
func _aura_flames(ci: CanvasItem, t: float, bc: Vector2) -> void:
	var k := smoothstep(Skills.WE_IGNITE, Skills.WE_IGNITE + 2.5, t) * (1.0 - smoothstep(Skills.WE_ASCEND - 1.0, Skills.WE_ASCEND, t))
	if k <= 0.01:
		return
	var big := 1.0 + 1.1 * smoothstep(Skills.WE_IGNITE, Skills.WE_BURST, t) + 0.5 * smoothstep(Skills.WE_BURST, Skills.WE_BURST + 1.0, t)
	var fy := bc.y + 16.0
	UD.glow(ci, Vector2(bc.x, fy - 40.0 * big), 90.0 * big, Color(1.0, 0.6, 0.15), 0.32 * k)
	UD.glow(ci, Vector2(bc.x, fy - 30.0 * big), 40.0 * big, Color(1.0, 0.85, 0.5), 0.28 * k)
	var n := 15
	for pass_i in 2:
		for i in n:
			var u := float(i) / float(n - 1) * 2.0 - 1.0
			var hx := _h(i, 1.0)
			var fl := 0.65 + 0.35 * sin(age * (9.0 + hx * 6.0) + float(i) * 1.9)
			var hgt := (50.0 + 80.0 * (1.0 - absf(u)) * (0.6 + 0.4 * hx)) * big * fl * (1.0 if pass_i == 0 else 0.62)
			var bx := bc.x + u * 24.0 * (1.0 + 0.4 * big)
			var wd := (6.5 if pass_i == 0 else 3.2) * big
			var tipx := bx + sin(age * 3.0 + float(i)) * 6.0 + u * 16.0
			var pts := PackedVector2Array([Vector2(bx - wd, fy - hgt * 0.18), Vector2(tipx, fy - hgt), Vector2(bx + wd, fy - hgt * 0.18), Vector2(bx, fy + 2.0)])
			var bcol := Color(1.0, 0.68, 0.16, 0.34 * k) if pass_i == 0 else Color(1.0, 0.9, 0.5, 0.34 * k)
			var zc := Color(bcol.r, bcol.g, bcol.b, 0.0)
			ci.draw_polygon(pts, PackedColorArray([bcol, zc, bcol, zc]))
	UD.ellipse(ci, Vector2(bc.x, fy), 30.0 * big + 3.0 * sin(age * 9.0), 0.24, Color(1.0, 0.9, 0.5, 0.8 * k), 2.0)


# ---------- Gelombang kejut (Act III) ----------
func _burst_fx(ci: CanvasItem, t: float, bc: Vector2) -> void:
	var u := (t - Skills.WE_BURST) / 1.7
	if u < 0.0 or u > 1.0:
		return
	var e := 1.0 - pow(1.0 - u, 3.0)
	var c := bc + Vector2(0.0, 8.0)  # gelombang kejut berpusat di karakter, bukan di tanah
	var r := 780.0 * e
	var fa := 1.0 - u
	UD.ellipse(ci, c, r, 0.2, Color(1.0, 0.95, 0.7, 0.95 * fa), 8.0 * fa + 1.0)
	UD.ellipse(ci, c, r * 0.82, 0.2, Color(0.7, 0.4, 1.0, 0.75 * fa), 4.0)
	UD.ellipse(ci, c, r * 0.62, 0.2, Color(1.0, 0.7, 0.25, 0.6 * fa), 3.0)
	UD.glow(ci, bc, 120.0 + 280.0 * e, Color(1.0, 0.9, 0.6), 0.85 * fa)
	for i in 28:
		var ang := float(i) / 28.0 * TAU + _h(i, 2.0)
		var d := Vector2(cos(ang), sin(ang))
		var r0 := 30.0 + 160.0 * e
		ci.draw_line(bc + d * r0, bc + d * (r0 + 40.0 + 220.0 * _h(i, 3.0) * e), Color(1.0, 0.92, 0.6, 0.7 * fa), 1.5)


# ---------- Badai tebasan prisma (Act IV) ----------
func _prism(ci: CanvasItem, t: float) -> void:
	if t < Skills.WE_PRISM - 0.1 or t > Skills.WE_PRISM_END + 1.4:
		return
	var vr := view()
	for i in 16:
		var s := Skills.WE_PRISM + float(i) * 0.21
		var u := (t - s) / 0.75
		if u < 0.0 or u > 1.5:
			continue
		var h1 := _h(i, 4.0)
		var flip := (i % 2) == 1
		var a := Vector2(vr.position.x - 60.0, vr.position.y + h1 * vr.size.y)
		var b := Vector2(vr.end.x + 60.0, vr.position.y + (1.0 - h1) * vr.size.y + (_h(i, 5.0) - 0.5) * 80.0)
		if flip:
			var tmp := a
			a = b
			b = tmp
		var ctrl := (a + b) * 0.5 + Vector2(0.0, (_h(i, 6.0) - 0.5) * 160.0)
		var e := 1.0 - pow(1.0 - clampf(u, 0.0, 1.0), 2.0)
		var col: Color = PRISM_COLS[i % PRISM_COLS.size()]
		var fa := 1.0 - smoothstep(1.0, 1.5, u)
		var pts := PackedVector2Array()
		for j in 14:
			var q := clampf(e - float(j) * 0.05, 0.0, 1.0)
			var qq := 1.0 - q
			pts.append(a * qq * qq + ctrl * 2.0 * qq * q + b * q * q)
		pts.reverse()
		UD.taper(ci, pts, 7.0 + 5.0 * _h(i, 7.0), Color(col.r, col.g, col.b, 0.85 * fa), 2)
		ci.draw_polyline(pts, Color(1, 1, 1, 0.9 * fa), 1.5)
		var head := pts[pts.size() - 1]
		UD.glow(ci, head, 22.0, col, 0.9 * fa)
	var k := smoothstep(Skills.WE_PRISM_END - 0.8, Skills.WE_PRISM_END, t) * (1.0 - smoothstep(Skills.WE_PRISM_END, Skills.WE_PRISM_END + 0.6, t))
	if k > 0.01:
		var ec := _eye_c()
		ci.draw_line(ec - Vector2(vr.size.x, 0.0), ec + Vector2(vr.size.x, 0.0), Color(1, 1, 1, 0.9 * k), 3.0)
		UD.glow(ci, ec, 160.0, Color(1.0, 0.95, 0.8), 0.8 * k)


# ---------- Cincin pita emas (Act V) ----------
func _halo(ci: CanvasItem, t: float) -> void:
	var a := smoothstep(Skills.WE_HALO, Skills.WE_HALO + 2.0, t) * (1.0 - smoothstep(Skills.WE_ASCEND - 0.8, Skills.WE_ASCEND, t))
	if a <= 0.01:
		return
	var bcc := p.pivot.global_position
	var grow := 0.55 + 0.45 * smoothstep(Skills.WE_HALO, Skills.WE_HALO + 3.0, t)
	var tilts := [-0.30, 0.24, -0.08, 0.38]
	var spds := [0.9, -0.7, 1.25, -0.5]
	for k in 4:
		var c := bcc + Vector2(0.0, -6.0 + (float(k) - 1.5) * 9.0)
		var rx := (62.0 + 30.0 * float(k)) * grow
		var ry := 15.0 + 8.0 * float(k)
		var tilt: float = tilts[k]
		var spd: float = spds[k]
		var back_pts := PackedVector2Array()
		var front_pts := PackedVector2Array()
		for i in 49:
			var an := float(i) / 48.0 * TAU
			var lp := Vector2(cos(an) * rx, sin(an) * ry).rotated(tilt)
			if sin(an) < 0.0:
				back_pts.append(c + lp)
			else:
				front_pts.append(c + lp)
		var gold := Color(1.0, 0.86, 0.3)
		var lime := Color(0.85, 1.0, 0.35)
		var col := gold if k % 2 == 0 else lime
		if back_pts.size() > 1:
			ci.draw_polyline(back_pts, Color(col.r, col.g, col.b, 0.35 * a), 3.0)
		if front_pts.size() > 1:
			ci.draw_polyline(front_pts, Color(col.r, col.g, col.b, 0.28 * a), 9.0)
			ci.draw_polyline(front_pts, Color(1.0, 0.97, 0.75, 0.9 * a), 2.2)
		var hd := age * spd + float(k) * 1.7
		var trail := PackedVector2Array()
		for j in 16:
			var an2 := hd - float(j) * 0.07 * signf(spd)
			trail.append(c + Vector2(cos(an2) * rx, sin(an2) * ry).rotated(tilt))
		trail.reverse()
		UD.taper(ci, trail, 5.0, Color(1.0, 0.95, 0.6, 0.8 * a), 2)
		UD.glow(ci, trail[trail.size() - 1], 18.0, Color(1.0, 0.95, 0.7), 0.9 * a)


# ---------- Pilar cahaya emas dari gedung ke langit (Act VI, 47,3 dtk di video) ----------
# Memakai lapisan yang sama dengan pilar di karakter (dari maou-fix): halo ungu, badan emas, pita gelap, inti putih, gelombang
func _cpillar_geo(t: float) -> Dictionary:
	var s := t - Skills.WE_CPILLAR
	if s < 0.0 or s > 2.4 or _sky_alpha(t) <= 0.01:
		return {}
	var vr := view()
	var base_y := _skyline_y(t) + 2.0
	var e := 1.0 - pow(1.0 - clampf(s / 0.45, 0.0, 1.0), 3.0)
	var top := lerpf(base_y, vr.position.y - 20.0, e)
	var thin := smoothstep(1.1, 2.0, s)
	var pa := 1.0 - smoothstep(1.9, 2.4, s)
	var open := smoothstep(0.0, 0.12, s)
	var hw := lerpf(15.0, 3.2, thin) * open * (1.0 + 0.05 * sin(age * 9.0))
	return {"s": s, "cx": _cx(), "base": base_y, "top": top, "hw": hw, "pa": pa}


# Pilar emas dari gedung ke langit: lapisan yang sama dengan pilar di karakter (halo ungu, badan emas, pita, inti putih, gelombang)
func _city_pillar(ci: CanvasItem, t: float) -> void:
	var g := _cpillar_geo(t)
	if g.is_empty():
		return
	var s: float = g["s"]
	var ix: float = g["cx"]
	var y1: float = g["base"]
	var top_y: float = g["top"]
	var hw: float = g["hw"]
	var pa: float = g["pa"]
	var h := y1 - top_y
	if hw < 0.5 or h < 2.0:
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
	var head := 1.0 - smoothstep(0.3, 0.55, s)
	if head > 0.01:
		UD.glow(ci, Vector2(ix, top_y + h * 0.0), hw * 2.6, GOLD_HI, 0.9 * head * pa)
	UD.glow(ci, Vector2(ix, y1 - 2.0), 80.0, Color(1.0, 0.85, 0.4, 1.0), 0.65 * pa)
	UD.glow(ci, Vector2(ix, y1 - 2.0), 54.0, Color(0.7, 0.4, 1.0, 1.0), 0.5 * pa)
	UD.ellipse(ci, Vector2(ix, y1), hw * 1.7 + 3.0 * sin(age * 9.0), 0.24, Color(1.0, 0.9, 0.5, 0.85 * pa), 2.0)
	UD.ellipse(ci, Vector2(ix, y1), hw * 1.1, 0.24, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.85 * pa), 1.6)
	for i in 26:
		var life := fposmod(s * (0.7 + 0.6 * _h(i, 80.0)) + _h(i, 81.0), 1.0)
		var px := ix + (_h(i, 82.0) - 0.5) * hw * 3.4 + sin(life * 6.0 + float(i)) * 3.0
		var py := lerpf(y1, top_y, life)
		var gcol := GOLD_HI if i % 3 != 0 else VIOLET
		ci.draw_line(Vector2(px, py), Vector2(px, py + 7.0), Color(gcol.r, gcol.g, gcol.b, 0.9 * sin(life * PI) * pa), 1.4)


func _city_ribbons(ci: CanvasItem, t: float) -> void:
	var g := _cpillar_geo(t)
	if g.is_empty():
		return
	var ix: float = g["cx"]
	var y1: float = g["base"]
	var top_y: float = g["top"]
	var hw: float = g["hw"]
	var pa: float = g["pa"]
	if hw < 0.5 or y1 - top_y < 2.0:
		return
	for strand in 2:
		var y := y1
		var px := 0.0
		var pwd := 0.0
		var py := y1
		var first := true
		while y >= top_y:
			var cx := ix + sin(y * 0.05 + age * 9.0 + float(strand) * PI) * hw * 1.25
			var wd := hw * 0.34 * (0.6 + 0.4 * sin(y * 0.11 + age * 9.0))
			if not first:
				UD.poly(ci, PackedVector2Array([Vector2(px - pwd, py), Vector2(px + pwd, py), Vector2(cx + wd, y), Vector2(cx - wd, y)]),
					Color(0.05, 0.0, 0.11, 0.6 * pa), "cpillar_strand")
			px = cx
			pwd = wd
			py = y
			first = false
			y -= 12.0


# ---------- Petir biru tunggal (50,6 dtk di video) ----------
func _bolts(ci: CanvasItem, t: float) -> void:
	var vr := view()
	var cx := _cx()
	var cyan := Color(0.5, 0.92, 1.0)
	for f in BOLT_AT.size():
		var s: float = Skills.WE_BOLT0 + float(BOLT_AT[f])
		var u := t - s
		if u < 0.0 or u > 0.5:
			continue
		var env := (1.0 - u / 0.5) * (0.6 + 0.4 * sin(u * 70.0))
		var pw := 1.0 if f == 0 else 0.55
		ci.draw_rect(vr, Color(0.45, 0.8, 1.0, 0.26 * env * pw))
		if f == 0:
			ci.draw_rect(Rect2(cx - 24.0, vr.position.y, 48.0, vr.size.y), Color(0.85, 0.97, 1.0, 0.6 * env))
			for sd in [-1.0, 1.0]:
				UD.bolt(ci, Vector2(cx + sd * 26.0, vr.position.y - 6.0), Vector2(cx + sd * 30.0, vr.end.y), cyan, env, 7.0, 16, 2.2)
		for k in 3:
			var x0 := cx + (float(k) - 1.0) * 120.0 * (0.6 + 0.8 * _h(f * 7 + k, 8.0)) + (_h(f + k, 9.0) - 0.5) * 60.0
			var from := Vector2(x0, vr.position.y - 10.0)
			var to := Vector2(x0 + (_h(f * 7 + k, 10.0) - 0.5) * 120.0, vr.position.y + vr.size.y * (0.45 + 0.25 * _h(f + k, 11.0)))
			UD.bolt(ci, from, to, cyan, env * pw, 14.0, 11, 2.0 * pw)


# ---------- Langit malam & kota (Act VI-VIII) ----------
func _sky_alpha(t: float) -> float:
	return smoothstep(Skills.WE_ASCEND + 0.1, Skills.WE_SKY, t) * (1.0 - smoothstep(Skills.WE_IMPACT - 0.5, Skills.WE_IMPACT - 0.42, t))


func _scene_shift(t: float, h: float) -> float:
	return -(1.0 - smoothstep(Skills.WE_ASCEND + 0.1, Skills.WE_SKY + 2.2, t)) * 0.42 * h


func _skyline_y(t: float) -> float:
	var vr := view()
	return vr.position.y + vr.size.y * 0.74 + _scene_shift(t, vr.size.y)


func _sword_params(t: float) -> Dictionary:
	var vr := view()
	var hang := vr.position.y + vr.size.y * 0.60 + sin(age * 1.3) * 3.0
	# ujung pedang muncul dari tepi atas lalu turun ke posisi menggantung (video 51,8 -> 54 dtk)
	var rise := smoothstep(Skills.WE_SWORD, Skills.WE_SWORD + 5.0, t)
	var tip := lerpf(vr.position.y - 6.0, hang, rise)
	var u := clampf((t - Skills.WE_FALL) / (Skills.WE_CONTACT - Skills.WE_FALL), 0.0, 1.0)
	var land := _skyline_y(t) + 6.0
	tip = lerpf(tip, land, pow(u, 1.9))
	var sc := 1.0 + 0.3 * u
	var al := smoothstep(Skills.WE_SWORD - 0.05, Skills.WE_SWORD + 0.15, t)
	return {"tip": tip, "sc": sc, "a": al, "wk": 1.0, "u": u}


# Awan cahaya oranye berlubang di belakang pedang: berkas vertikal bercelah (bukan cahaya menempel di pedang)
func _light_fan(ci: CanvasItem, t: float, a: float) -> void:
	# bertahan sampai adegan kota selesai (hilang bersama langit saat whiteout, bukan saat pedang mulai jatuh)
	var k := smoothstep(Skills.WE_CPILLAR + 2.0, Skills.WE_CPILLAR + 2.7, t)
	if k <= 0.01:
		return
	var vr := view()
	var cx := _cx()
	var sc := 0.8 + 0.3 * smoothstep(Skills.WE_CPILLAR + 2.0, Skills.WE_SWORD + 2.0, t)
	var half_w := 82.0 * sc
	var h := 92.0 * sc
	var y0 := vr.position.y + 2.0
	UD.glow(ci, Vector2(cx, y0 + h * 0.3), 120.0 * sc, Color(1.0, 0.5, 0.14), 0.5 * k * a)
	UD.glow(ci, Vector2(cx, y0 + h * 0.15), 60.0 * sc, Color(1.0, 0.7, 0.3), 0.35 * k * a)
	var n := 28
	for i in n:
		if _h(i, 90.0) < 0.26:
			continue
		var u := float(i) / float(n - 1) * 2.0 - 1.0
		var x := cx + u * half_w
		var wd := (2.5 + 4.5 * _h(i, 91.0)) * (1.0 - 0.45 * absf(u))
		var ln := h * (0.5 + 0.5 * (1.0 - absf(u)) * (0.6 + 0.4 * _h(i, 92.0))) * (0.92 + 0.08 * sin(age * 3.0 + float(i)))
		var sp := u * 12.0
		var top_c := Color(1.0, 0.64, 0.22, 0.72 * k * a)
		var bot_c := Color(1.0, 0.45, 0.12, 0.0)
		ci.draw_polygon(PackedVector2Array([Vector2(x - wd * 0.5, y0), Vector2(x + wd * 0.5, y0), Vector2(x + sp + wd * 0.35, y0 + ln), Vector2(x + sp - wd * 0.35, y0 + ln)]),
			PackedColorArray([top_c, top_c, bot_c, bot_c]))


func _sky(ci: CanvasItem, t: float) -> void:
	var a := _sky_alpha(t)
	if a <= 0.01:
		return
	var vr := view().grow(14.0)
	var h := vr.size.y
	var sh := _scene_shift(t, h)
	var hy := vr.position.y + h * 0.74 + sh
	var y0 := vr.position.y
	var y1 := vr.end.y
	var x0 := vr.position.x
	var x1 := vr.end.x
	var top := Color(NIGHT_TOP.r, NIGHT_TOP.g, NIGHT_TOP.b, a)
	var mid := Color(NIGHT_MID.r, NIGHT_MID.g, NIGHT_MID.b, a)
	var hor := Color(NIGHT_HOR.r, NIGHT_HOR.g, NIGHT_HOR.b, a)
	var ym := hy - h * 0.38
	ci.draw_polygon(PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, ym), Vector2(x0, ym)]), PackedColorArray([top, top, mid, mid]))
	ci.draw_polygon(PackedVector2Array([Vector2(x0, ym), Vector2(x1, ym), Vector2(x1, hy), Vector2(x0, hy)]), PackedColorArray([mid, mid, hor, hor]))
	var cx := _cx()
	var contact := smoothstep(Skills.WE_CONTACT, Skills.WE_CONTACT + 0.6, t)
	for i in 80:
		var sx := x0 + vr.size.x * _h(i, 13.0)
		var sy := y0 + (hy - y0) * 0.8 * _h(i, 14.0) * _h(i, 14.0)
		var tw := 0.4 + 0.6 * absf(sin(age * (0.8 + _h(i, 15.0) * 2.0) + float(i)))
		ci.draw_rect(Rect2(sx, sy, 1.2, 1.2), Color(0.8, 0.9, 1.0, 0.8 * tw * a))
	for b in 3:
		var cy := ym + h * (0.05 + 0.16 * float(b)) + sin(age * 0.3 + float(b)) * 2.0
		var drift := fposmod(age * (5.0 + 3.0 * float(b)) + float(b) * 200.0, vr.size.x + 400.0) - 200.0
		var pts := PackedVector2Array()
		var cw := vr.size.x * 0.9
		for k in 16:
			var u := float(k) / 15.0
			pts.append(Vector2(x0 + drift + u * cw - cw * 0.35, cy - 8.0 * sin(u * PI) * (0.6 + 0.4 * _h(k + b * 20, 16.0))))
		for k in 16:
			var u2 := 1.0 - float(k) / 15.0
			pts.append(Vector2(x0 + drift + u2 * cw - cw * 0.35, cy + 6.0 * sin(u2 * PI)))
		var lit := Color(0.2 + 0.7 * contact * 0.5, 0.28 + 0.45 * contact * 0.5, 0.40, (0.55 - 0.1 * float(b)) * a)
		UD.poly(ci, pts, lit, "cloud")
	ci.draw_polygon(PackedVector2Array([Vector2(x0, hy - 24.0), Vector2(x1, hy - 24.0), Vector2(x1, hy), Vector2(x0, hy)]),
		PackedColorArray([Color(hor.r, hor.g, hor.b, 0.0), Color(hor.r, hor.g, hor.b, 0.0), Color(0.2, 0.3, 0.42, 0.55 * a), Color(0.2, 0.3, 0.42, 0.55 * a)]))
	_city(ci, t, hy, a, contact, cx)
	var sp := _sword_params(t)
	var sa: float = sp["a"] * a
	_light_fan(ci, t, a)
	_wind_clouds(ci, t, cx, float(sp["tip"]) - SB_L * float(sp["sc"]) * 0.75, a)
	if sa > 0.01:
		_blade_body(ci, cx, float(sp["tip"]), float(sp["sc"]), float(sp["wk"]), sa)
		_wind_ring(ci, t, cx, float(sp["tip"]), sa)
	_rocks(ci, t, hy, a, cx)


func _city(ci: CanvasItem, t: float, hy: float, a: float, contact: float, cx: float) -> void:
	var vr := view().grow(14.0)
	var x := vr.position.x - 4.0
	var i := 0
	while x < vr.end.x:
		var wb := 9.0 + 16.0 * _h(i, 20.0)
		var hb := 14.0 + 40.0 * _h(i, 21.0) * (0.5 + 0.5 * _h(i + 3, 22.0))
		ci.draw_rect(Rect2(x, hy - hb, wb + 1.0, hb + 4.0), Color(0.05, 0.085, 0.15, a))
		x += wb
		i += 1
	x = vr.position.x - 6.0
	i = 0
	while x < vr.end.x:
		var wb2 := 13.0 + 22.0 * _h(i, 23.0)
		var hb2 := 8.0 + 34.0 * _h(i, 24.0) + (24.0 if _h(i, 25.0) > 0.86 else 0.0)
		ci.draw_rect(Rect2(x, hy - hb2, wb2 + 1.0, hb2 + 4.0), Color(0.018, 0.03, 0.06, a))
		var cols := int(wb2 / 5.0)
		var rows := int(hb2 / 7.0)
		for r in rows:
			for c in cols:
				var hh := _h(i * 31 + r * 7 + c, 26.0)
				if hh < 0.42:
					var fl := 0.7 + 0.3 * sin(age * (1.0 + hh * 3.0) + hh * 40.0)
					var wx := x + 2.0 + float(c) * 5.0
					var near := clampf(1.0 - absf(wx - cx) / 340.0, 0.0, 1.0)
					var wc := Color(1.0, 0.82, 0.48, 0.55 * a * fl).lerp(Color(1.0, 0.95, 0.7, 0.95 * a), contact * near)
					ci.draw_rect(Rect2(wx, hy - hb2 + 3.0 + float(r) * 7.0, 2.0, 3.0), wc)
		if hb2 > 40.0 and int(age * 1.5 + float(i)) % 2 == 0:
			ci.draw_rect(Rect2(x + wb2 * 0.5, hy - hb2 - 3.0, 2.0, 2.0), Color(1.0, 0.2, 0.15, a))
		x += wb2
		i += 1
	ci.draw_rect(Rect2(vr.position.x, hy + 2.0, vr.size.x, vr.end.y - hy + 40.0), Color(0.012, 0.02, 0.04, a))


func _blade_fade_y(tip: float, sc: float) -> Vector2:
	# (yz, yf): alpha 0 di yz, penuh di yf. Bilah memudar ke langit tepat di tepi atas layar sehingga tidak tampak terpotong.
	var vr := view()
	var bt := tip - SB_L * sc
	var yz := maxf(bt, vr.position.y - 6.0)
	var yf := maxf(bt + 100.0 * sc, vr.position.y + 100.0)
	yf = minf(yf, tip - 40.0 * sc)
	return Vector2(yz, yf)


func _blade_body(ci: CanvasItem, ix: float, tip: float, sc: float, wk: float, a: float) -> void:
	var bw := SB_W * sc * maxf(wk, 0.04)
	var zf := _blade_fade_y(tip, sc)
	var yz := zf.x
	var yf := zf.y
	if yf <= yz + 1.0:
		return
	var shoulder := tip - 38.0 * sc
	var dk := Color(0.78, 0.48, 0.10, a)
	var lg := Color(1.0, 0.82, 0.30, a)
	var dk0 := Color(dk.r, dk.g, dk.b, 0.0)
	var lg0 := Color(lg.r, lg.g, lg.b, 0.0)
	UD.poly(ci, PackedVector2Array([Vector2(ix, tip), Vector2(ix - bw, shoulder), Vector2(ix - bw, yf), Vector2(ix, yf)]), dk, "sbL")
	UD.poly(ci, PackedVector2Array([Vector2(ix, tip), Vector2(ix + bw, shoulder), Vector2(ix + bw, yf), Vector2(ix, yf)]), lg, "sbR")
	ci.draw_polygon(PackedVector2Array([Vector2(ix - bw, yf), Vector2(ix, yf), Vector2(ix, yz), Vector2(ix - bw, yz)]), PackedColorArray([dk, dk, dk0, dk0]))
	ci.draw_polygon(PackedVector2Array([Vector2(ix, yf), Vector2(ix + bw, yf), Vector2(ix + bw, yz), Vector2(ix, yz)]), PackedColorArray([lg, lg, lg0, lg0]))
	var fc := Color(1.0, 0.95, 0.66, a)
	var fc0 := Color(fc.r, fc.g, fc.b, 0.0)
	UD.poly(ci, PackedVector2Array([Vector2(ix, tip - 26.0 * sc), Vector2(ix - 5.0 * sc, tip - 44.0 * sc), Vector2(ix - 5.0 * sc, yf), Vector2(ix + 5.0 * sc, yf), Vector2(ix + 5.0 * sc, tip - 44.0 * sc)]), fc, "sbF")
	ci.draw_polygon(PackedVector2Array([Vector2(ix - 5.0 * sc, yf), Vector2(ix + 5.0 * sc, yf), Vector2(ix + 5.0 * sc, yz), Vector2(ix - 5.0 * sc, yz)]), PackedColorArray([fc, fc, fc0, fc0]))
	var y := tip - 58.0 * sc
	while y > yf:
		ci.draw_line(Vector2(ix - bw * 0.7, y), Vector2(ix - 7.0 * sc, y), Color(0.55, 0.32, 0.06, 0.8 * a), 1.0)
		ci.draw_line(Vector2(ix + 7.0 * sc, y - 3.0), Vector2(ix + bw * 0.7, y - 3.0), Color(0.55, 0.32, 0.06, 0.8 * a), 1.0)
		y -= 15.0 * sc


func _sky_sword_glow(ci: CanvasItem, t: float) -> void:
	var a := _sky_alpha(t)
	if a <= 0.01 or t < Skills.WE_SWORD - 0.1:
		return
	var cx := _cx()
	var sp := _sword_params(t)
	var tip: float = sp["tip"]
	var sc: float = sp["sc"]
	var al: float = sp["a"] * a
	if al <= 0.01:
		return
	var bt := tip - SB_L * sc
	# hanya tepi bilah yang bercahaya (tidak ada halo besar menempel di pedang)
	UD.glow(ci, Vector2(cx, tip), 18.0 * sc, Color(1.0, 0.96, 0.8), 0.55 * al)
	var yf := _blade_fade_y(tip, sc).y
	ci.draw_line(Vector2(cx + SB_W * sc, tip - 38.0 * sc), Vector2(cx + SB_W * sc, yf), Color(1, 1, 0.85, 0.9 * al), 1.4)
	ci.draw_line(Vector2(cx + SB_W * sc, tip - 38.0 * sc), Vector2(cx, tip), Color(1, 1, 0.85, 0.9 * al), 1.4)
	ci.draw_line(Vector2(cx - SB_W * sc, tip - 38.0 * sc), Vector2(cx - SB_W * sc, yf), Color(1, 0.9, 0.4, 0.55 * al), 1.2)
	ci.draw_line(Vector2(cx - SB_W * sc, tip - 38.0 * sc), Vector2(cx, tip), Color(1, 0.9, 0.4, 0.55 * al), 1.2)
	_wind_aura(ci, t, cx, tip, bt, sc, al, float(sp["u"]))


# Percikan listrik: lengkung acak bercabang yang muncul sesaat di tepi bilah (bukan garis paralel terus-menerus)
func _arc(ci: CanvasItem, p0: Vector2, ang0: float, length: float, seed_i: int, col: Color, al: float, depth: int) -> void:
	var pts := PackedVector2Array([p0])
	var p := p0
	var ang := ang0
	var fork_at := 2 + int(_h(seed_i, 101.0) * 3.0)
	for j in 7:
		ang += (_h(seed_i * 17 + j, 102.0) - 0.5) * 1.0
		p += Vector2.from_angle(ang) * (length / 7.0)
		pts.append(p)
		if j == fork_at and depth < 1:
			_arc(ci, p, ang + (0.7 if _h(seed_i, 103.0) > 0.5 else -0.7), length * 0.55, seed_i + 91, col, al * 0.8, depth + 1)
	ci.draw_polyline(pts, Color(col.r, col.g, col.b, 0.16 * al), 5.0)
	ci.draw_polyline(pts, Color(col.r, col.g, col.b, 0.45 * al), 2.4)
	ci.draw_polyline(pts, Color(1.0, 1.0, 0.8, 0.95 * al), 1.0)


func _wind_aura(ci: CanvasItem, t: float, cx: float, tip: float, bt: float, sc: float, al: float, fu: float) -> void:
	var ramp := smoothstep(Skills.WE_SWORD + 1.5, Skills.WE_SWORD + 4.0, t)
	var wa := al * ramp * (1.0 - smoothstep(Skills.WE_IMPACT - 2.5, Skills.WE_IMPACT - 0.6, t))
	if wa <= 0.01:
		return
	var lime := Color(0.86, 1.0, 0.36)
	var rate := 2.4 + 2.2 * fu
	for k in 8:
		var side := -1.0 if k % 2 == 0 else 1.0
		var spd := rate * (0.6 + 0.7 * _h(k, 70.0))
		var cyc := age * spd + _h(k, 71.0)
		var ph := fposmod(cyc, 1.0)
		if ph > 0.3:
			continue
		var burst := int(cyc)
		var env := sin(ph / 0.3 * PI) * (0.7 + 0.3 * sin(age * 70.0 + float(k)))
		var y := tip - (8.0 + 95.0 * _h(burst * 5 + k, 72.0)) * sc
		var p0 := Vector2(cx + side * SB_W * sc * 0.96, y)
		var ang0 := -PI * 0.5 + side * (0.35 + 0.7 * _h(burst + k, 73.0))
		_arc(ci, p0, ang0, (11.0 + 17.0 * _h(burst * 3 + k, 74.0)) * sc, burst * 13 + k, lime, wa * env, 0)
	for i in 12:
		var life := fposmod(age * (0.35 + 0.4 * _h(i, 75.0)) + _h(i, 76.0), 1.0)
		var sd := -1.0 if i % 2 == 0 else 1.0
		var pp := Vector2(cx + sd * (SB_W * sc * (1.0 + 0.9 * _h(i, 77.0)) + sin(life * 6.0 + float(i)) * 3.0), lerpf(tip - 6.0 * sc, tip - 120.0 * sc, life))
		UD.glow(ci, pp, 4.0, lime, 0.45 * sin(life * PI) * wa)
		ci.draw_rect(Rect2(pp, Vector2(1.4, 1.4)), Color(1.0, 1.0, 0.7, 0.9 * sin(life * PI) * wa))


# Kabut/asap lembut yang memekar dari ujung pedang (gumpalan redup bertumpuk, tanpa garis tepi)
func _wind_ring(ci: CanvasItem, t: float, cx: float, tip: float, a: float) -> void:
	for k in 5:
		var s := t - (Skills.WE_SWORD + 1.0 + float(k) * 2.2)
		if s < 0.0 or s > 2.8 or t > Skills.WE_CONTACT + 0.4:
			continue
		var u := s / 2.8
		var e := 1.0 - pow(1.0 - u, 2.0)
		var rx := 18.0 + 170.0 * e
		var ry := rx * 0.2
		for i in 30:
			var an := TAU * float(i) / 30.0 + float(k) * 0.9 + u * 0.4
			var hh := _h(i + k * 30, 78.0)
			var r := (12.0 + 20.0 * e) * (0.7 + 0.6 * hh)
			var pc := Vector2(cx + cos(an) * rx * (0.9 + 0.2 * hh), tip - 6.0 + sin(an) * ry * (0.9 + 0.2 * hh) - 4.0 * hh * e)
			UD.glow(ci, pc, r, Color(0.58, 0.68, 0.84), 0.075 * (1.0 - u) * a)


# Awan gelap yang berputar pelan di langit sekitar pedang (gumpalan lembut, bukan garis)
func _wind_clouds(ci: CanvasItem, t: float, cx: float, ytop: float, a: float) -> void:
	var vk := smoothstep(Skills.WE_SWORD + 0.3, Skills.WE_SWORD + 4.0, t) * (1.0 - smoothstep(Skills.WE_CONTACT - 0.4, Skills.WE_CONTACT + 0.8, t))
	if vk <= 0.01:
		return
	for b in 3:
		for j in 14:
			var u := float(j) / 13.0
			var ang := age * 0.3 + float(b) * 2.09 + u * 2.6
			var rad := 40.0 + 230.0 * u
			var pc := Vector2(cx + cos(ang) * rad * 1.35, ytop + sin(ang) * rad * 0.2 - u * 20.0)
			UD.glow(ci, pc, 18.0 + 16.0 * u, Color(0.01, 0.02, 0.05), 0.2 * vk * a * (1.0 - 0.4 * u))


# ---------- Jatuh, sinar, dan puing (Act VIII) ----------
func _rock_state(i: int, s: float, p0: Vector2) -> Dictionary:
	var vx := (_h(i, 40.0) - 0.5) * 520.0
	var vy := -90.0 - 300.0 * _h(i, 41.0)
	var pos := p0 + Vector2(vx * s, vy * s + 0.5 * 360.0 * s * s)
	var z := 1.0 + s * (1.5 + 2.0 * _h(i, 42.0))
	return {"pos": pos, "z": z}


func _rocks(ci: CanvasItem, t: float, hy: float, a: float, cx: float) -> void:
	if t < Skills.WE_CONTACT:
		return
	var p0 := Vector2(cx, hy - 6.0)
	for i in 44:
		var delay := _h(i, 43.0) * 1.6
		var s := t - Skills.WE_CONTACT - delay
		if s <= 0.0 or s > 3.4:
			continue
		var st := _rock_state(i, s, p0)
		var pos: Vector2 = st["pos"]
		var z: float = st["z"]
		var sz := (2.5 + 4.5 * _h(i, 44.0)) * z
		var rot := age * (_h(i, 45.0) - 0.5) * 8.0 + float(i)
		var pts := PackedVector2Array()
		for k in 5:
			var an := rot + float(k) * TAU / 5.0
			pts.append(pos + Vector2(cos(an), sin(an)) * sz * (0.6 + 0.4 * _h(i * 5 + k, 46.0)))
		var fa := a * (1.0 - smoothstep(2.6, 3.4, s))
		UD.poly(ci, pts, Color(0.04, 0.03, 0.04, fa), "rock")
		var closed := pts.duplicate()
		closed.append(pts[0])
		ci.draw_polyline(closed, Color(1.0, 0.78, 0.25, 0.9 * fa), 1.0)


func _fall_fx(ci: CanvasItem, t: float) -> void:
	if t < Skills.WE_FALL - 0.5 or t > Skills.WE_IMPACT:
		return
	var a := _sky_alpha(t)
	var vr := view()
	var cx := _cx()
	var hy := _skyline_y(t)
	if t >= Skills.WE_CONTACT:
		var u := clampf((t - Skills.WE_CONTACT) / (Skills.WE_IMPACT - 0.5 - Skills.WE_CONTACT), 0.0, 1.0)
		var e := 1.0 - pow(1.0 - u, 2.5)
		var p0 := Vector2(cx, hy - 6.0)
		UD.glow(ci, p0, 90.0 + 260.0 * e, Color(1.0, 0.85, 0.4), 0.9 * a)
		UD.glow(ci, p0, 40.0 + 90.0 * e, Color(1.0, 1.0, 0.95), 0.9 * a)
		var ru := clampf((t - Skills.WE_CONTACT) / 1.6, 0.0, 1.0)
		UD.ellipse(ci, Vector2(cx, hy), 40.0 + 800.0 * ru, 0.1, Color(1.0, 0.9, 0.6, 0.9 * (1.0 - ru)), 6.0 * (1.0 - ru) + 1.0)
		for k in 15:
			var ang := -PI * 0.5 + (float(k) - 7.0) * 0.17 + sin(age * 2.0 + float(k)) * 0.03
			var ln := (130.0 + 330.0 * _h(k, 55.0)) * (0.3 + 0.7 * e)
			var wd := (0.05 + 0.04 * _h(k, 56.0)) * (0.5 + e)
			var d0 := Vector2(cos(ang - wd), sin(ang - wd))
			var d1 := Vector2(cos(ang + wd), sin(ang + wd))
			var c0 := Color(1.0, 0.88, 0.45, 0.65 * a)
			var tc := Color(1.0, 0.7, 0.2, 0.0)
			ci.draw_polygon(PackedVector2Array([p0 + d0 * 8.0, p0 + d1 * 8.0, p0 + d1 * ln, p0 + d0 * ln]), PackedColorArray([c0, c0, tc, tc]))
		var side := 1.0 - smoothstep(0.2, 0.6, u)
		for k in 6:
			var sg := -1.0 if k % 2 == 0 else 1.0
			var yy := hy - 4.0 - float(k) * 3.0
			ci.draw_line(Vector2(cx, yy), Vector2(cx + sg * (60.0 + 560.0 * e), yy - 6.0 * float(k)), Color(1.0, 0.85, 0.4, 0.5 * a * side), 2.0)
		var wo := smoothstep(Skills.WE_IMPACT - 2.2, Skills.WE_IMPACT - 0.5, t)
		ci.draw_rect(vr, Color(1.0, 0.9, 0.6, 0.55 * wo * a))
