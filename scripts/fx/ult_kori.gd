extends "res://scripts/fx/ult_dir.gd"

const ICE := Color(0.62, 0.90, 1.0)
const FROST := Color(0.92, 0.99, 1.0)
const DEEP := Color(0.30, 0.55, 1.0)
const VIOLET := Color(0.70, 0.60, 1.0)

var spikes: Array = []
var web: Array = []
var _shatter_t := -1.0
var _shatter_c := Vector2.ZERO
var _acc := 0.0


func _pal() -> Array:
	return [ICE, FROST, DEEP]


func _init_fx() -> void:
	var n := 30
	for i in n:
		var dx := lerpf(-340.0, 340.0, float(i) / float(n - 1)) + randf_range(-6.0, 6.0)
		var near := 1.0 - absf(dx) / 400.0
		spikes.append({
			"dx": dx,
			"h": (26.0 + 62.0 * randf()) * (0.6 + 0.6 * near),
			"wd": randf_range(5.0, 10.0),
			"tilt": randf_range(-0.22, 0.22),
			"delay": 1.8 + absf(dx) / 520.0,
			"y": randf_range(-2.0, 6.0),
		})


func _light_energy(t: float) -> float:
	var e := 0.4 + 0.7 * smoothstep(0.1, 1.2, t)
	for ev in [1.0, 1.8, 3.1]:
		if t >= float(ev):
			e += 1.8 * exp(-(t - float(ev)) * 3.5)
	return e


func _tick(t: float, bc: Vector2) -> void:
	if _shatter_t < 0.0 and p._cine.has("shatter"):
		_shatter_t = t
		_shatter_c = Vector2(p.global_position.x + 40.0, bc.y)
		var ox := p.ultimate_origin.x
		for s in spikes:
			var d: Dictionary = s
			var base := Vector2(ox + float(d["dx"]), GY + float(d["y"]))
			for k in 3:
				emit(base + Vector2(0.0, -float(d["h"]) * randf_range(0.2, 0.9)), Vector2(float(d["dx"]) * 0.35 + randf_range(-90.0, 90.0), randf_range(-260.0, -60.0)), randf_range(0.8, 1.3), randf_range(3.0, 6.0), Color(0.8, 0.96, 1.0, 1.0), 520.0, 0.2, 2, randf_range(-10.0, 10.0))
		web.clear()
		for i in 15:
			var ang := float(i) * TAU / 15.0 + randf_range(-0.1, 0.1)
			var pts := PackedVector2Array()
			var q := _shatter_c
			var dir := Vector2(cos(ang), sin(ang) * 0.8)
			for j in 8:
				pts.append(q)
				q += dir.rotated(randf_range(-0.35, 0.35)) * randf_range(26.0, 52.0)
			web.append(pts)
	_acc += rd
	while _acc >= 0.05:
		_acc -= 0.05
		if t < 1.0 and t > 0.1:
			var a := randf() * TAU
			var pos := bc + Vector2(cos(a) * randf_range(110.0, 170.0), sin(a) * randf_range(60.0, 100.0))
			emit(pos, (bc - pos).normalized() * 230.0, 0.55, randf_range(2.0, 3.5), Color(0.85, 0.97, 1.0, 1.0), 0.0, 0.0, 2, 6.0)
		elif t >= 1.2 and t < 4.2:
			var vr := view()
			emit(Vector2(randf_range(vr.position.x, vr.end.x), vr.position.y - 4.0), Vector2(randf_range(-20.0, 6.0), randf_range(35.0, 80.0)), randf_range(1.6, 2.6), 2.0, Color(1, 1, 1, 0.8), 0.0, 0.0, 0)


func _back(ci: CanvasItem, t: float, bc: Vector2, fade: float) -> void:
	var ox := p.ultimate_origin.x
	var gc := Vector2(ox, GY - 1.0)
	var vr := view()
	var alive := 1.0 - smoothstep(3.9, 4.4, t)
	var sheet := smoothstep(0.0, 0.9, t) * alive
	if sheet > 0.01:
		var R := lerpf(10.0, 150.0, smoothstep(0.0, 1.0, t)) + 230.0 * smoothstep(1.8, 2.6, t)
		var pts := PackedVector2Array()
		for i in 40:
			var a := float(i) / 40.0 * TAU
			pts.append(gc + Vector2(cos(a) * R, sin(a) * R * 0.22))
		UD.poly(ci, pts, Color(0.55, 0.85, 1.0, 0.13 * sheet), "sheet")
		UD.ellipse(ci, gc, R, 0.22, Color(0.9, 0.98, 1.0, 0.55 * sheet), 1.4)
		for k in 10:
			var a2 := float(k) * TAU / 10.0 + 0.2
			var d := Vector2(cos(a2), sin(a2) * 0.22)
			var L := R * (0.7 + 0.3 * sin(float(k) * 2.7))
			ci.draw_line(gc, gc + d * L, Color(0.9, 0.98, 1.0, 0.5 * sheet), 1.0)
			for f in [0.35, 0.6, 0.82]:
				var bp := gc + d * L * float(f)
				for sg in [-1.0, 1.0]:
					var bd := Vector2(cos(a2 + 0.8 * float(sg)), sin(a2 + 0.8 * float(sg)) * 0.22)
					ci.draw_line(bp, bp + bd * L * 0.2 * (1.0 - float(f) * 0.5), Color(0.9, 0.98, 1.0, 0.4 * sheet), 1.0)
	var man := smoothstep(0.6, 1.4, t) * (1.0 - smoothstep(2.6, 3.1, t))
	if man > 0.01:
		var r := 92.0 * (0.8 + 0.2 * smoothstep(0.6, 1.6, t))
		UD.hex(ci, gc, r, t * 0.5, Color(ICE.r, ICE.g, ICE.b, 0.8 * man), 1.6, 0.24)
		UD.hex(ci, gc, r, t * 0.5 + PI / 6.0, Color(FROST.r, FROST.g, FROST.b, 0.7 * man), 1.2, 0.24)
		UD.hex(ci, gc, r * 0.55, -t * 0.8, Color(VIOLET.r, VIOLET.g, VIOLET.b, 0.7 * man), 1.2, 0.24)
		UD.ellipse(ci, gc, r * 1.15, 0.24, Color(ICE.r, ICE.g, ICE.b, 0.45 * man), 1.0)
		for k in 6:
			var a3 := -t * 0.5 + float(k) * TAU / 6.0
			var pp := gc + Vector2(cos(a3) * r * 1.15, sin(a3) * r * 1.15 * 0.24)
			ci.draw_line(pp, pp + Vector2(0.0, -14.0 - 8.0 * sin(t * 4.0 + float(k))), Color(0.9, 0.98, 1.0, 0.5 * man), 1.0)
		UD.glow(ci, gc, r * 1.1, Color(0.4, 0.7, 1.0, 1.0), 0.3 * man)
	var wing := smoothstep(1.0, 1.6, t) * (1.0 - smoothstep(3.1, 3.5, t))
	if wing > 0.01:
		_wings(ci, bc, t, wing)
	var au := smoothstep(1.2, 2.0, t) * (1.0 - smoothstep(3.1, 3.6, t))
	if au > 0.01:
		var cols := [Color(0.4, 1.0, 0.8), Color(0.5, 0.8, 1.0), VIOLET]
		for k in 3:
			var pts2 := PackedVector2Array()
			for i in 14:
				var x := vr.position.x + vr.size.x * float(i) / 13.0
				pts2.append(Vector2(x, vr.position.y + 22.0 + float(k) * 11.0 + sin(x * 0.02 + t * 0.9 + float(k) * 1.7) * 9.0))
			var c: Color = cols[k]
			UD.taper(ci, pts2, 9.0, Color(c.r, c.g, c.b, 0.16 * au), 1)
	if t >= 1.8 and t < 2.9:
		var f := (t - 1.8) / 1.1
		for k in 3:
			var fk := clampf(f - float(k) * 0.07, 0.0, 1.0)
			UD.ellipse(ci, gc, (1.0 - pow(1.0 - fk, 2.0)) * (560.0 + 80.0 * float(k)), 0.22, Color(0.85, 0.97, 1.0, (1.0 - fk) * 0.7), maxf(1.0, 5.0 * (1.0 - fk)))
	if t >= 1.8 and _shatter_t < 0.0:
		for s in spikes:
			var d2: Dictionary = s
			var u := clampf((t - float(d2["delay"])) / 0.35, 0.0, 1.0)
			if u <= 0.0:
				continue
			var e := 1.0 - pow(1.0 - u, 3.0)
			UD.crystal(ci, Vector2(ox + float(d2["dx"]), GY + float(d2["y"])), float(d2["h"]) * e, float(d2["wd"]), Color(0.65, 0.9, 1.0, 1.0), 0.9 * alive, float(d2["tilt"]))


func _wings(ci: CanvasItem, bc: Vector2, t: float, a: float) -> void:
	var open := smoothstep(1.0, 1.7, t)
	var flap := sin(t * 2.6) * 0.07
	for side in [-1.0, 1.0]:
		for tier in 3:
			var anchor := bc + Vector2(-3.0 * float(side) * -1.0, -10.0 + float(tier) * 6.0)
			for i in 5:
				var u := float(i) / 4.0
				var al := PI + 0.02 + u * (0.55 + 0.1 * float(tier)) + flap * (1.0 + float(tier) * 0.3)
				al = lerpf(PI * 1.5 - 0.35, al, open)
				var ang: float = al if side < 0.0 else (PI - al)
				var ln := (58.0 + 40.0 * sin((u * 0.85 + 0.12) * PI)) * (1.0 - 0.2 * float(tier)) * open
				UD.feather(ci, anchor, ang, ln, 6.5 - 1.0 * float(tier), Color(0.7, 0.93, 1.0, 1.0), a * (1.0 - 0.15 * float(tier)))
	UD.glow(ci, bc, 70.0, Color(0.5, 0.8, 1.0, 1.0), 0.25 * a)


func _shade(ci: CanvasItem, t: float, _bc: Vector2, _fade: float) -> void:
	var vr := view().grow(8.0)
	var cold := smoothstep(0.2, 1.4, t) * (1.0 - smoothstep(3.3, 4.2, t))
	ci.draw_rect(vr, Color(0.02, 0.06, 0.22, 0.38 * cold))
	var fr := smoothstep(1.8, 3.0, t) * (1.0 - smoothstep(3.1, 3.4, t))
	if fr > 0.01:
		var dep := 70.0 * fr + 14.0
		var o := Color(0.82, 0.95, 1.0, 0.62 * fr)
		var z := Color(0.82, 0.95, 1.0, 0.0)
		ci.draw_polygon(PackedVector2Array([vr.position, Vector2(vr.end.x, vr.position.y), Vector2(vr.end.x, vr.position.y + dep), Vector2(vr.position.x, vr.position.y + dep)]), PackedColorArray([o, o, z, z]))
		ci.draw_polygon(PackedVector2Array([Vector2(vr.position.x, vr.end.y - dep), Vector2(vr.end.x, vr.end.y - dep), vr.end, Vector2(vr.position.x, vr.end.y)]), PackedColorArray([z, z, o, o]))
		ci.draw_polygon(PackedVector2Array([vr.position, Vector2(vr.position.x + dep * 1.4, vr.position.y), Vector2(vr.position.x + dep * 1.4, vr.end.y), Vector2(vr.position.x, vr.end.y)]), PackedColorArray([o, z, z, o]))
		ci.draw_polygon(PackedVector2Array([Vector2(vr.end.x - dep * 1.4, vr.position.y), Vector2(vr.end.x, vr.position.y), vr.end, Vector2(vr.end.x - dep * 1.4, vr.end.y)]), PackedColorArray([z, o, o, z]))


func _front(ci: CanvasItem, t: float, bc: Vector2, fade: float) -> void:
	var body := smoothstep(0.2, 0.8, t) * fade
	if body > 0.01:
		UD.hex(ci, bc + Vector2(0.0, 2.0), 27.0, t * 1.2, Color(0.85, 0.97, 1.0, 0.55 * body), 1.2, 1.15)
		for k in 6:
			var a := -t * 1.6 + float(k) * TAU / 6.0
			var c := bc + Vector2(cos(a) * 30.0, sin(a) * 18.0 + 2.0)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(0, -4), c + Vector2(2.5, 0), c + Vector2(0, 4), c + Vector2(-2.5, 0)]), Color(0.9, 0.98, 1.0, 0.85 * body))
	if _shatter_t >= 0.0:
		var sa := t - _shatter_t
		if sa < 0.9:
			var gr := clampf(sa / 0.14, 0.0, 1.0)
			var al := 1.0 - smoothstep(0.35, 0.9, sa)
			for pts in web:
				var cnt := maxi(2, int(float((pts as PackedVector2Array).size()) * gr))
				var sub := (pts as PackedVector2Array).slice(0, cnt)
				ci.draw_polyline(sub, Color(0.7, 0.92, 1.0, 0.55 * al), 3.0)
				ci.draw_polyline(sub, Color(1, 1, 1, 0.95 * al), 1.0)
			if sa < 0.4:
				var lf := 1.0 - sa / 0.4
				UD.glow(ci, _shatter_c, 90.0 * lf + 20.0, Color(0.85, 0.97, 1.0, 1.0), 0.8 * lf)
