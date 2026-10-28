extends "res://scripts/fx/ult_dir.gd"

const RAD := Color(0.72, 1.0, 0.25)
const WARN := Color(1.0, 0.30, 0.12)
const GOLD := Color(1.0, 0.90, 0.30)

var _acc := 0.0
var _boom_t := 1.5


func _pal() -> Array:
	return [RAD, GOLD, WARN]


func _light_energy(t: float) -> float:
	var e := 0.4 + 0.8 * smoothstep(0.1, 1.5, t)
	for ev in [1.5, 4.2]:
		if t >= float(ev):
			e += 3.2 * exp(-(t - float(ev)) * 2.6)
	return e


func _impact_pt() -> Vector2:
	return Vector2(float(p._cine.get("x0", p.global_position.x)) + Skills.NUKE_STEP, GY)


func _tick(t: float, bc: Vector2) -> void:
	_acc += rd
	while _acc >= 0.035:
		_acc -= 0.035
		var vr := view()
		if t >= 1.5 and t < 4.3:
			emit(Vector2(randf_range(vr.position.x, vr.end.x), vr.position.y - 4.0), Vector2(randf_range(-10.0, 10.0), randf_range(60.0, 140.0)), randf_range(1.2, 2.0), 2.0, Color(0.75, 1.0, 0.3, 0.9), 0.0, 0.0, 1)
		elif t < 1.5 and t > 0.3:
			var a := randf() * TAU
			emit(bc + Vector2(cos(a), sin(a) * 0.6) * randf_range(60.0, 110.0), Vector2(cos(a), sin(a) * 0.6) * -90.0, 0.5, 2.0, Color(0.8, 1.0, 0.35, 0.9), 0.0, 0.0, 0)


func _orbit_pts(c: Vector2, rx: float, ry: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var cr := cos(rot)
	var sr := sin(rot)
	for i in 33:
		var a := float(i) / 32.0 * TAU
		var q := Vector2(cos(a) * rx, sin(a) * ry)
		pts.append(c + Vector2(q.x * cr - q.y * sr, q.x * sr + q.y * cr))
	return pts


func _back(ci: CanvasItem, t: float, bc: Vector2, fade: float) -> void:
	var vr := view()
	var ip := _impact_pt()
	var pre := smoothstep(0.05, 0.4, t) * (1.0 - smoothstep(1.45, 1.6, t))
	if pre > 0.01:
		var ch := clampf(t / 1.5, 0.0, 1.0)
		var R := lerpf(125.0, 38.0, ch)
		var pulse := 0.6 + 0.4 * sin(t * 20.0)
		var col := Color(WARN.r, WARN.g, WARN.b, 0.85 * pre)
		UD.ellipse(ci, ip, R, 0.24, col, 2.0)
		UD.ellipse(ci, ip, R * 0.6, 0.24, Color(GOLD.r, GOLD.g, GOLD.b, 0.7 * pre), 1.2)
		UD.dashed_ellipse(ci, ip, R * 1.25, 0.24, t * 2.0, Color(WARN.r, WARN.g, WARN.b, 0.55 * pre), 1.6, 20, 0.5)
		ci.draw_line(ip + Vector2(-R * 1.3, 0.0), ip + Vector2(R * 1.3, 0.0), Color(WARN.r, WARN.g, WARN.b, 0.5 * pre), 1.0)
		ci.draw_line(ip + Vector2(0.0, -R * 0.4), ip + Vector2(0.0, R * 0.4), Color(WARN.r, WARN.g, WARN.b, 0.5 * pre), 1.0)
		UD.glow(ci, ip, R * 1.1, Color(1.0, 0.2, 0.05, 1.0), 0.28 * pre * pulse)
		ci.draw_line(Vector2(ip.x, vr.position.y), ip, Color(WARN.r, WARN.g, WARN.b, 0.12 + 0.2 * ch * pulse), 1.0)
	var post := smoothstep(1.55, 2.2, t) * (1.0 - smoothstep(4.3, 4.8, t))
	if post > 0.01:
		ci.draw_texture_rect(TexGen.glow_tex(128), Rect2(vr.position.x - 20.0, GY - 46.0, vr.size.x + 40.0, 80.0), false, Color(0.55, 1.0, 0.2, 0.30 * post))
	var sh := smoothstep(1.2, 1.55, t) * (1.0 - smoothstep(4.2, 4.5, t))
	if sh > 0.01:
		var hit := exp(-maxf(0.0, t - 1.5) * 2.5) if t >= 1.5 else 0.0
		var r := 34.0
		var al := (0.35 + 0.55 * hit) * sh
		UD.glow(ci, bc, r * 1.9, Color(0.5, 1.0, 0.3, 1.0), 0.28 * al)
		ci.draw_arc(bc, r, 0.0, TAU, 40, Color(RAD.r, RAD.g, RAD.b, 0.8 * al), 1.6)
		UD.hex(ci, bc, r * 0.82, t * 0.7, Color(RAD.r, RAD.g, RAD.b, 0.6 * al), 1.0)
		UD.hex(ci, bc, r * 0.82, -t * 0.7 + PI / 6.0, Color(0.9, 1.0, 0.6, 0.5 * al), 1.0)


func _shade(ci: CanvasItem, t: float, _bc: Vector2, _fade: float) -> void:
	var vr := view().grow(8.0)
	var ch := clampf(t / 1.5, 0.0, 1.0)
	var pre := smoothstep(0.0, 0.5, t) * (1.0 - smoothstep(1.45, 1.55, t))
	ci.draw_rect(vr, Color(0.14, 0.0, 0.0, 0.30 * pre))
	var pulse := 0.5 + 0.5 * sin(t * 16.0)
	var o := Color(1.0, 0.12, 0.06, 0.45 * pulse * ch * pre)
	var z := Color(1.0, 0.12, 0.06, 0.0)
	var dep := 46.0
	ci.draw_polygon(PackedVector2Array([vr.position, Vector2(vr.end.x, vr.position.y), Vector2(vr.end.x, vr.position.y + dep), Vector2(vr.position.x, vr.position.y + dep)]), PackedColorArray([o, o, z, z]))
	ci.draw_polygon(PackedVector2Array([Vector2(vr.position.x, vr.end.y - dep), Vector2(vr.end.x, vr.end.y - dep), vr.end, Vector2(vr.position.x, vr.end.y)]), PackedColorArray([z, z, o, o]))
	ci.draw_polygon(PackedVector2Array([vr.position, Vector2(vr.position.x + dep, vr.position.y), Vector2(vr.position.x + dep, vr.end.y), Vector2(vr.position.x, vr.end.y)]), PackedColorArray([o, z, z, o]))
	ci.draw_polygon(PackedVector2Array([Vector2(vr.end.x - dep, vr.position.y), Vector2(vr.end.x, vr.position.y), vr.end, Vector2(vr.end.x - dep, vr.end.y)]), PackedColorArray([z, o, o, z]))
	var post := smoothstep(1.6, 2.4, t) * (1.0 - smoothstep(4.3, 5.0, t))
	ci.draw_rect(vr, Color(0.08, 0.10, 0.0, 0.34 * post))


func _front(ci: CanvasItem, t: float, bc: Vector2, fade: float) -> void:
	var vr := view()
	var ip := _impact_pt()
	var at := smoothstep(0.1, 0.5, t) * (1.0 - smoothstep(1.3, 1.55, t))
	if at > 0.01:
		var ch := clampf(t / 1.5, 0.0, 1.0)
		for k in 3:
			var rot := float(k) * PI / 3.0 + t * (0.6 + 1.6 * ch)
			var rx := lerpf(46.0, 30.0, ch)
			ci.draw_polyline(_orbit_pts(bc, rx, rx * 0.32, rot), Color(RAD.r, RAD.g, RAD.b, 0.6 * at), 1.2)
			var ea := t * (5.0 + 5.0 * ch) + float(k) * 2.1
			var q := Vector2(cos(ea) * rx, sin(ea) * rx * 0.32)
			var e := bc + Vector2(q.x * cos(rot) - q.y * sin(rot), q.x * sin(rot) + q.y * cos(rot))
			UD.glow(ci, e, 7.0, Color(1.0, 0.95, 0.5, 1.0), 0.9 * at)
		UD.glow(ci, bc, 12.0 + 12.0 * ch, Color(0.8, 1.0, 0.3, 1.0), 0.45 * at)
	for entry in [[0.2, 0.65, 3], [0.65, 1.1, 2], [1.1, 1.5, 1]]:
		var s: float = entry[0]
		var e2: float = entry[1]
		if t >= s and t < e2:
			var k := 1.0 + 0.6 * exp(-(t - s) * 9.0)
			var al := clampf((e2 - t) / 0.08, 0.0, 1.0)
			var cpos := Vector2(vr.position.x + vr.size.x * 0.5, vr.position.y + 36.0)
			UD.seg7(ci, cpos, int(entry[2]), 30.0 * k, Color(1.0, 0.35, 0.15, al), 3.0)
	if t >= 0.75 and t < 1.5:
		var u := clampf((t - 0.75) / 0.75, 0.0, 1.0)
		var start := Vector2(ip.x - 60.0, vr.position.y - 36.0)
		var target := Vector2(ip.x, bc.y)
		var pos := start.lerp(target, pow(u, 1.5))
		var dir := (target - start).normalized()
		var prev := start.lerp(target, pow(maxf(0.0, u - 0.18), 1.5))
		UD.taper(ci, PackedVector2Array([prev, prev.lerp(pos, 0.5), pos]), 6.0, Color(1.0, 0.55, 0.15, 0.5), 0)
		ci.draw_set_transform(pos, dir.angle(), Vector2.ONE)
		var body := PackedVector2Array([Vector2(-26, -5), Vector2(10, -5), Vector2(22, 0), Vector2(10, 5), Vector2(-26, 5)])
		UD.poly(ci, body, Color(0.75, 0.82, 0.78, 0.9), "bomb")
		UD.poly(ci, PackedVector2Array([Vector2(-26, -5), Vector2(-34, -12), Vector2(-14, -5)]), Color(0.9, 0.3, 0.15, 0.9), "fin")
		UD.poly(ci, PackedVector2Array([Vector2(-26, 5), Vector2(-34, 12), Vector2(-14, 5)]), Color(0.9, 0.3, 0.15, 0.9), "fin")
		ci.draw_line(Vector2(-6, -5), Vector2(-6, 5), Color(1.0, 0.85, 0.2, 0.9), 3.0)
		ci.draw_line(Vector2(1, -5), Vector2(1, 5), Color(1.0, 0.85, 0.2, 0.9), 3.0)
		ci.draw_polyline(PackedVector2Array([Vector2(-26, -5), Vector2(10, -5), Vector2(22, 0), Vector2(10, 5), Vector2(-26, 5), Vector2(-26, -5)]), Color(1, 1, 1, 0.8), 1.0)
		ci.draw_set_transform(pos, dir.angle() + PI * 1.5, Vector2.ONE)
		UD.flame(ci, Vector2(0.0, -20.0), 36.0, 12.0, age * 12.0, 0.9)
		ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		UD.glow(ci, pos, 30.0, Color(1.0, 0.5, 0.15, 1.0), 0.5)
	if t >= 1.5 and t < 2.1:
		var f := (t - 1.5) / 0.6
		UD.glow(ci, ip + Vector2(0.0, -40.0), 70.0 + 200.0 * f, Color(1.0, 0.9, 0.55, 1.0), 0.9 * (1.0 - f))
	var post := smoothstep(1.7, 2.2, t) * (1.0 - smoothstep(4.3, 4.7, t)) * fade
	if post > 0.01:
		UD.trefoil(ci, bc + Vector2(0.0, -46.0), 11.0, t * 2.0, Color(0.85, 1.0, 0.3, 0.75 * post))
