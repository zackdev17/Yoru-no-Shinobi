extends "res://scripts/fx/ult_dir.gd"

const JADE := Color(0.45, 1.0, 0.75)
const MINT := Color(0.80, 1.0, 0.93)
const TEAL := Color(0.15, 0.78, 0.68)

var trail := PackedVector2Array()
var _final_t := -1.0
var _final_c := Vector2.ZERO
var _acc := 0.0


func _pal() -> Array:
	return [JADE, MINT, TEAL]


func _light_energy(t: float) -> float:
	var e := 0.35 + 0.6 * smoothstep(0.1, 0.9, t)
	for ev in [1.7, 3.7]:
		if t >= ev:
			e += 2.4 * exp(-(t - ev) * 3.5)
	return e


func _tick(t: float, bc: Vector2) -> void:
	var ox := p.ultimate_origin.x
	if t >= 1.7 and t < 3.7:
		trail.append(bc)
		if trail.size() > 40:
			trail.remove_at(0)
	elif trail.size() > 0:
		trail.remove_at(0)
	if _final_t < 0.0 and p._cine.has("final"):
		_final_t = t
		_final_c = Vector2(p.global_position.x + 40.0, GY)
		for k in 36:
			emit(_final_c + Vector2(randf_range(-30.0, 30.0), -2.0), Vector2(randf_range(-260.0, 260.0), randf_range(-330.0, -60.0)), randf_range(0.5, 1.0), randf_range(2.0, 3.5), Color(0.6, 1.0, 0.8, 1.0), 380.0, 0.4, 2, randf_range(-12.0, 12.0))
	_acc += rd
	if t < 0.9:
		while _acc >= 0.025:
			_acc -= 0.025
			var a := randf() * TAU
			var r := randf_range(70.0, 150.0)
			var pos := Vector2(ox, GY - 3.0) + Vector2(cos(a) * r, sin(a) * r * 0.25)
			emit(pos, Vector2(-sin(a), cos(a) * 0.25) * 120.0 + Vector2(0.0, -60.0), randf_range(0.4, 0.8), 2.2, Color(0.7, 1.0, 0.85, 0.9), -40.0, 0.5, 1)
	elif t < 1.7:
		while _acc >= 0.03:
			_acc -= 0.03
			var a2 := randf() * TAU
			var pos2 := Vector2(ox + cos(a2) * 40.0, GY - 3.0)
			emit(pos2, Vector2(cos(a2 + 1.57) * 140.0, randf_range(-220.0, -80.0)), randf_range(0.5, 0.9), 2.4, Color(0.7, 1.0, 0.85, 0.9), 0.0, 0.3, 2, 8.0)
	elif t < 3.7:
		while _acc >= 0.02:
			_acc -= 0.02
			emit(bc + Vector2(-14.0, randf_range(-20.0, 16.0)), Vector2(randf_range(-420.0, -240.0), randf_range(-20.0, 20.0)), randf_range(0.25, 0.5), 2.0, Color(0.75, 1.0, 0.9, 0.9), 0.0, 0.0, 1)
	else:
		_acc = 0.0


func _back(ci: CanvasItem, t: float, bc: Vector2, fade: float) -> void:
	var ox := p.ultimate_origin.x
	var gc := Vector2(ox, GY - 1.0)
	var ring_a := smoothstep(0.0, 0.3, t) * (1.0 - smoothstep(1.7, 2.1, t))
	if ring_a > 0.01:
		var r := lerpf(135.0, 48.0, clampf(t / 0.9, 0.0, 1.0)) if t < 0.9 else lerpf(48.0, 100.0, clampf((t - 0.9) / 0.8, 0.0, 1.0))
		UD.dashed_ellipse(ci, gc, r, 0.22, t * 3.2, Color(JADE.r, JADE.g, JADE.b, 0.75 * ring_a), 2.0, 14, 0.55)
		UD.dashed_ellipse(ci, gc, r * 0.62, 0.22, -t * 4.4, Color(MINT.r, MINT.g, MINT.b, 0.6 * ring_a), 1.3, 9, 0.5)
		UD.dashed_ellipse(ci, gc, r * 1.28, 0.22, t * 2.0, Color(TEAL.r, TEAL.g, TEAL.b, 0.4 * ring_a), 1.0, 18, 0.4)
		UD.glow(ci, gc, r * 0.9, Color(TEAL.r, TEAL.g, TEAL.b, 0.5), 0.35 * ring_a)
	var inflow := smoothstep(0.05, 0.35, t) * (1.0 - smoothstep(1.2, 1.8, t))
	if inflow > 0.01:
		var target := Vector2(bc.x, bc.y + 6.0)
		for k in 16:
			var s := fposmod(t * 1.25 + float(k) / 16.0, 1.0)
			var pts := PackedVector2Array()
			for i in 9:
				var u := maxf(0.0, s - 0.24 + 0.24 * float(i) / 8.0)
				var rr := lerpf(160.0, 14.0, u * u)
				var ang := float(k) * 0.83 + u * 2.6
				pts.append(target + Vector2(cos(ang) * rr, sin(ang) * rr * 0.5 + (1.0 - u) * 30.0))
			UD.taper(ci, pts, 1.8, Color(0.7, 1.0, 0.88, 0.7 * inflow * sin(s * PI)), 0)
	var grow := smoothstep(0.9, 1.6, t)
	var tfade := 1.0 - smoothstep(3.55, 3.75, t)
	if grow > 0.01 and tfade > 0.01:
		var follow := smoothstep(1.7, 1.95, t)
		var bx := lerpf(ox, bc.x, follow)
		var lean := -34.0 * follow
		_funnel(ci, Vector2(bx, GY), 175.0 * grow, 62.0, t, 0.75 * grow * tfade, false, lean)
	var rush := smoothstep(1.7, 1.85, t) * (1.0 - smoothstep(3.55, 3.75, t))
	if rush > 0.01:
		if trail.size() > 3:
			UD.taper(ci, trail, 7.0, Color(TEAL.r, TEAL.g, TEAL.b, 0.16 * rush), 0)
			var n := trail.size()
			for k in 4:
				var pts := PackedVector2Array()
				for i in n:
					var u := float(i) / float(n - 1)
					var off := sin(age * 7.0 + float(i) * 0.45 + float(k) * 1.7) * (1.0 - u) * 9.0 + (float(k) - 1.5) * 5.0 * (0.4 + 0.6 * u)
					pts.append(trail[i] + Vector2(0.0, off))
				UD.taper(ci, pts, 1.6, Color(0.8, 1.0, 0.92, 0.5 * rush), 0)
		_drill(ci, bc + Vector2(6.0, -2.0), t, rush, false)
	if _final_t >= 0.0:
		var sa := t - _final_t
		if sa < 0.8:
			var u := clampf(sa / 0.45, 0.0, 1.0)
			var h := 230.0 * (1.0 - pow(1.0 - u, 2.5))
			var al := (1.0 - smoothstep(0.35, 0.8, sa))
			_funnel(ci, _final_c, h, 76.0, t * 1.4, 0.9 * al, true)
			for k in 3:
				var ts := sa - float(k) * 0.07
				if ts > 0.0 and ts < 0.7:
					var g := ts / 0.7
					UD.ellipse(ci, _final_c, (1.0 - pow(1.0 - g, 2.2)) * (330.0 + 70.0 * float(k)), 0.18, Color(0.8, 1.0, 0.92, (1.0 - g) * 0.85), maxf(1.0, 5.0 * (1.0 - g)))


func _shade(ci: CanvasItem, t: float, _bc: Vector2, _fade: float) -> void:
	var ph := smoothstep(0.1, 0.9, t) * 0.5 + smoothstep(1.4, 1.9, t) * 0.5
	ph *= 1.0 - smoothstep(4.0, 4.4, t)
	ci.draw_rect(view().grow(8.0), Color(0.0, 0.08, 0.10, 0.34 * ph))


func _front(ci: CanvasItem, t: float, bc: Vector2, fade: float) -> void:
	var wrap := smoothstep(0.15, 0.7, t) * (1.0 - smoothstep(3.55, 3.85, t)) * fade
	if wrap > 0.01:
		for k in 3:
			var prev := Vector2.ZERO
			for i in 11:
				var u := float(i) / 10.0
				var a := t * 15.0 + float(k) * TAU / 3.0 + u * 5.0
				var pt := bc + Vector2(sin(a) * (9.0 + 6.0 * sin(u * PI)), lerpf(20.0, -26.0, u))
				if i > 0 and cos(a) > -0.2:
					ci.draw_line(prev, pt, Color(0.8, 1.0, 0.92, (0.35 + 0.4 * cos(a)) * wrap), 1.6)
				prev = pt
	var rush := smoothstep(1.7, 1.85, t) * (1.0 - smoothstep(3.55, 3.75, t))
	if rush > 0.01:
		_drill(ci, bc + Vector2(6.0, -2.0), t, rush, true)
		_speed_lines(ci, rush)
	if _final_t >= 0.0:
		var sa := t - _final_t
		if sa < 0.75:
			var al := 1.0 - smoothstep(0.4, 0.75, sa)
			var e := 1.0 - pow(1.0 - clampf(sa / 0.6, 0.0, 1.0), 2.0)
			for k in 12:
				var side := 1.0 if k % 2 == 0 else -1.0
				var hgt := -12.0 - float(k / 2) * 17.0
				var dist := e * (170.0 + float(k) * 22.0)
				var c := _final_c + Vector2(side * (24.0 + dist), hgt)
				var amid := 0.0 if side > 0.0 else PI
				UD.crescent(ci, c - Vector2(side * 14.0, 0.0), amid, 24.0 + float(k % 3) * 5.0, 1.5, 3.5, Color(0.75, 1.0, 0.9, 0.85 * al))
				UD.crescent(ci, c - Vector2(side * 14.0, 0.0), amid, 24.0 + float(k % 3) * 5.0, 1.2, 1.2, Color(1, 1, 1, 0.9 * al))


func _drill(ci: CanvasItem, c: Vector2, t: float, a: float, front: bool) -> void:
	var L := 96.0
	var x0 := -42.0
	if not front:
		UD.poly(ci, PackedVector2Array([c + Vector2(x0, -26.0), c + Vector2(x0 + L, 0.0), c + Vector2(x0, 26.0)]), Color(TEAL.r, TEAL.g, TEAL.b, 0.13 * a), "cone")
	for k in 4:
		var prev := Vector2.ZERO
		var has := false
		for i in 13:
			var u := float(i) / 12.0
			var r := 25.0 * pow(1.0 - u, 0.85) + 1.5
			var ang := t * 26.0 + float(k) * TAU / 4.0 + u * 5.5
			var pt := c + Vector2(x0 + u * L, sin(ang) * r * 0.95)
			var depth := cos(ang)
			if has and ((depth >= 0.0) == front):
				var al := a * (0.22 + 0.5 * (1.0 - u * 0.55)) * (0.5 + 0.5 * absf(depth))
				ci.draw_line(prev, pt, Color(0.75, 1.0, 0.9, al), 2.0 if front else 1.3)
			prev = pt
			has = true
	if not front:
		for j in 4:
			var xr := fposmod(-t * 110.0 + float(j) * 30.0, 120.0)
			var u2 := xr / 120.0
			var r2 := 25.0 * pow(1.0 - u2, 0.85) + 2.0
			var pts := PackedVector2Array()
			for s in 17:
				var an := float(s) / 16.0 * TAU
				pts.append(c + Vector2(x0 + xr + cos(an) * 3.0, sin(an) * r2))
			ci.draw_polyline(pts, Color(0.7, 1.0, 0.88, 0.5 * a * (1.0 - u2)), 1.2)
		UD.glow(ci, c + Vector2(48.0, 0.0), 22.0, Color(0.8, 1.0, 0.95, 1.0), 0.55 * a)


func _speed_lines(ci: CanvasItem, a: float) -> void:
	var vr := view()
	for i in 16:
		var y := vr.position.y + vr.size.y * (float(i) + 0.5) / 16.0 + sin(float(i) * 12.9) * 6.0
		var spd := 1500.0 + float(i % 5) * 260.0
		var ln := 60.0 + float(i % 4) * 45.0
		var x := vr.end.x + ln - fposmod(age * spd + float(i) * 131.0, vr.size.x + ln * 2.0)
		ci.draw_line(Vector2(x, y), Vector2(x + ln, y), Color(0.75, 1.0, 0.9, 0.4 * a), 1.2 if i % 3 != 0 else 2.0)
	for i in 3:
		var yb := vr.position.y + vr.size.y * (0.2 + 0.3 * float(i)) + sin(age * 3.0 + float(i)) * 8.0
		var xb := vr.end.x + 160.0 - fposmod(age * 2100.0 + float(i) * 400.0, vr.size.x + 320.0)
		var pts := PackedVector2Array()
		for s in 9:
			pts.append(Vector2(xb + float(s) * 22.0, yb + sin(float(s) * 0.7 + age * 9.0) * 4.0))
		UD.taper(ci, pts, 2.6, Color(0.8, 1.0, 0.92, 0.22 * a), 0)


func _funnel(ci: CanvasItem, base: Vector2, h: float, rmax: float, t: float, a: float, solid: bool, lean: float = 0.0) -> void:
	if h < 4.0 or a <= 0.01:
		return
	var n := 15
	for k in n:
		var u := float(k) / float(n - 1)
		var y := base.y - u * h
		var r := lerpf(7.0, rmax, pow(u, 1.15)) * (1.0 + 0.05 * sin(t * 9.0 + float(k)))
		var cx := base.x + sin(t * 3.0 + u * 5.0) * 6.0 * u + lean * u * u
		var a0 := t * (10.0 + 6.0 * (1.0 - u)) + float(k) * 0.62
		var al := a * (0.45 + 0.4 * (1.0 - u))
		UD.ellipse(ci, Vector2(cx, y), r, 0.2, Color(JADE.r, JADE.g, JADE.b, 0.6 * al), 1.8, a0, a0 + 3.1, 12)
		UD.ellipse(ci, Vector2(cx, y), r * 0.82, 0.17, Color(1, 1, 1, 0.3 * al), 1.0, a0 + 2.4, a0 + 4.8, 10)
	for s in 3:
		var pts := PackedVector2Array()
		for i in 16:
			var u2 := float(i) / 15.0
			var rr := lerpf(7.0, rmax, pow(u2, 1.15))
			var ang := t * 7.0 + float(s) * TAU / 3.0 + u2 * 8.0
			pts.append(Vector2(base.x + sin(t * 3.0 + u2 * 5.0) * 6.0 * u2 + lean * u2 * u2 + cos(ang) * rr, base.y - u2 * h + sin(ang) * rr * 0.2))
		ci.draw_polyline(pts, Color(JADE.r, JADE.g, JADE.b, 0.35 * a), 3.0)
		ci.draw_polyline(pts, Color(0.85, 1.0, 0.95, 0.6 * a), 1.2)
	UD.glow(ci, Vector2(base.x + lean * 0.2, base.y - h * 0.45), rmax * 1.1, Color(TEAL.r, TEAL.g, TEAL.b, 1.0), 0.30 * a)
	UD.ellipse(ci, base, rmax * 0.9, 0.16, Color(0.8, 1.0, 0.92, 0.5 * a), 2.0)
