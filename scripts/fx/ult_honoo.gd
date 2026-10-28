extends "res://scripts/fx/ult_dir.gd"

const EMBER := Color(1.0, 0.45, 0.10)
const GOLD := Color(1.0, 0.82, 0.30)
const CORE := Color(1.0, 0.95, 0.70)

var cracks: Array = []
var _cracks_made := false
var _impact := Vector2.ZERO
var _impact_t := 0.0
var _acc := 0.0
var _magma: Array = []


func _pal() -> Array:
	return [EMBER, GOLD, Color(1.0, 0.3, 0.1)]


func _init_fx() -> void:
	for i in 9:
		var ang := PI * (float(i) + 0.5) / 9.0 + randf_range(-0.12, 0.12)
		var side := 1.0 if cos(ang) >= 0.0 else -1.0
		var reach := randf_range(70.0, 125.0)
		var pts := PackedVector2Array()
		var x := 0.0
		var y := 0.0
		for j in 9:
			pts.append(Vector2(x, y))
			x += side * reach / 8.0 * randf_range(0.6, 1.3) * absf(cos(ang)) * 1.2
			y = clampf(y + randf_range(-1.5, 3.0), -1.0, 9.0)
		_magma.append(pts)


func _light_energy(t: float) -> float:
	var e := 0.5 + 0.9 * smoothstep(0.1, 1.2, t)
	for ev in [1.1, 1.7, float(p._cine.get("mega_t", 99.0))]:
		if t >= float(ev):
			e += 2.4 * exp(-(t - float(ev)) * 3.0)
	return e


func _sky_top() -> float:
	return view().position.y


func _tick(t: float, bc: Vector2) -> void:
	var ox := p.ultimate_origin.x
	if not _cracks_made and p._cine.has("mega_x"):
		_cracks_made = true
		_impact = Vector2(float(p._cine["mega_x"]), GY)
		_impact_t = float(p._cine.get("mega_t", t))
		_make_cracks()
	_acc += rd
	var rate := 0.045 if (t < 3.6) else 0.03
	while _acc >= rate:
		_acc -= rate
		if t < 1.7:
			emit(Vector2(ox + randf_range(-90.0, 90.0), GY - 2.0), Vector2(randf_range(-20.0, 20.0), randf_range(-150.0, -60.0)), randf_range(0.6, 1.1), 2.0, Color(1.0, randf_range(0.5, 0.8), 0.2, 1.0), -30.0, 0.2, 0)
		else:
			var vr := view()
			emit(Vector2(randf_range(vr.position.x, vr.end.x), vr.position.y + randf_range(0.0, 20.0)), Vector2(randf_range(-30.0, 10.0), randf_range(60.0, 130.0)), randf_range(0.9, 1.6), 2.0, Color(1.0, randf_range(0.4, 0.75), 0.15, 0.9), 0.0, 0.0, 0)


func _make_cracks() -> void:
	cracks.clear()
	for i in 18:
		var dir := -1.0 if i % 2 == 0 else 1.0
		var reach := randf_range(100.0, 340.0)
		var pts := PackedVector2Array()
		var x := 0.0
		var y := 0.0
		for j in 13:
			pts.append(_impact + Vector2(x, y))
			x += dir * reach / 12.0 * randf_range(0.6, 1.4)
			y = clampf(y + randf_range(-3.0, 4.0), -1.0, 15.0)
		cracks.append({"pts": pts, "delay": randf_range(0.0, 0.18), "seed": float(i) * 3.7})


func _back(ci: CanvasItem, t: float, bc: Vector2, fade: float) -> void:
	var ox := p.ultimate_origin.x
	var gc := Vector2(ox, GY - 1.0)
	var vr := view()
	var base_a := smoothstep(0.0, 0.35, t) * (1.0 - smoothstep(4.3, 4.8, t))
	var mg := smoothstep(0.05, 1.0, t) * base_a
	if mg > 0.01:
		for i in _magma.size():
			var pts: PackedVector2Array = _magma[i]
			var cnt := maxi(2, int(float(pts.size()) * mg))
			var sub := PackedVector2Array()
			for j in cnt:
				sub.append(gc + pts[j])
			ci.draw_polyline(sub, Color(1.0, 0.35, 0.08, 0.55 * mg), 3.0)
			ci.draw_polyline(sub, Color(1.0, 0.85, 0.4, 0.9 * mg), 1.0)
		UD.glow(ci, gc, 80.0, Color(1.0, 0.4, 0.1, 1.0), 0.35 * mg)
	var ring := smoothstep(0.1, 0.9, t) * (1.0 - smoothstep(3.3, 3.9, t))
	if ring > 0.01:
		var r := lerpf(120.0, 62.0, clampf(t / 1.1, 0.0, 1.0))
		var tall := 22.0 + 36.0 * smoothstep(0.2, 1.1, t) + 26.0 * smoothstep(1.1, 1.5, t) * (1.0 - smoothstep(1.7, 2.4, t))
		for k in 16:
			var a := float(k) * TAU / 16.0 + t * 0.6
			var pos := gc + Vector2(cos(a) * r, sin(a) * r * 0.24)
			var hh := tall * (0.7 + 0.3 * sin(t * 9.0 + float(k) * 1.9)) * ring
			if sin(a) < 0.0:
				hh *= 0.8
			UD.flame(ci, pos, hh, 15.0, t * 1.5 + float(k) * 0.7, 0.8 * ring)
	var sun := smoothstep(1.2, 1.8, t) * (1.0 - smoothstep(3.7, 4.3, t))
	if sun > 0.01:
		var sc := Vector2(bc.x, vr.position.y - 6.0)
		var big := 1.0 + 0.5 * smoothstep(3.4, 3.9, t)
		var sr := 62.0 * big * (0.92 + 0.08 * sin(t * 11.0))
		UD.glow(ci, sc, sr * 3.0, Color(1.0, 0.45, 0.1, 1.0), 0.55 * sun)
		UD.glow(ci, sc, sr * 1.6, Color(1.0, 0.7, 0.2, 1.0), 0.75 * sun)
		ci.draw_circle(sc, sr, Color(1.0, 0.72, 0.22, 0.85 * sun))
		ci.draw_circle(sc, sr * 0.72, Color(1.0, 0.92, 0.55, 0.9 * sun))
		for k in 22:
			var a2 := t * 0.5 + float(k) * TAU / 22.0
			var d := Vector2(cos(a2), sin(a2))
			var ln := sr * (0.35 + 0.35 * absf(sin(t * 5.0 + float(k) * 1.9)))
			ci.draw_line(sc + d * sr, sc + d * (sr + ln), Color(1.0, 0.6, 0.2, 0.6 * sun), 2.0)
		for k in 7:
			var gx := bc.x + (float(k) - 3.0) * 70.0 + sin(t * 1.3 + float(k)) * 14.0
			var pts := PackedVector2Array([sc + Vector2((float(k) - 3.0) * 8.0, 0.0), Vector2(gx, GY)])
			UD.taper(ci, pts, 12.0, Color(1.0, 0.6, 0.2, 0.07 * sun), 2)
		var col := smoothstep(1.1, 1.5, t) * (1.0 - smoothstep(1.9, 2.6, t))
		if col > 0.01:
			var top := vr.position.y + 10.0
			for k in 5:
				var x := bc.x + (float(k) - 2.0) * 7.0
				UD.flame(ci, Vector2(x, bc.y - 34.0), (bc.y - 34.0 - top) * (0.6 + 0.1 * float(k % 3)), 9.0, t * 3.0 + float(k), 0.4 * col)
	var marks: Array = p._cine.get("marks", [])
	for m in marks:
		var d: Dictionary = m
		var node = d.get("node")
		if node == null or not is_instance_valid(node):
			continue
		var n := node as Node2D
		var u := clampf((n.global_position.y - (vr.position.y - 20.0)) / (GY - (vr.position.y - 20.0)), 0.0, 1.0)
		var big_m := bool(d.get("mega", false))
		var rr := (150.0 if big_m else 24.0 * float(d.get("size", 1.0))) * (1.15 - 0.5 * u)
		var tx := float(d["x"])
		var al := (0.35 + 0.65 * u) * (1.0 if big_m else 0.9)
		UD.ellipse(ci, Vector2(tx, GY), rr, 0.24, Color(1.0, 0.3, 0.1, 0.8 * al), 2.4 if big_m else 1.5)
		UD.ellipse(ci, Vector2(tx, GY), rr * 0.55, 0.24, Color(1.0, 0.8, 0.3, 0.7 * al), 1.0)
		UD.glow(ci, Vector2(tx, GY), rr * 1.1, Color(1.0, 0.3, 0.05, 1.0), 0.28 * al)
		if big_m:
			UD.dashed_ellipse(ci, Vector2(tx, GY), rr * 1.25, 0.24, t * 2.5, Color(1.0, 0.5, 0.15, 0.7 * al), 2.0, 16, 0.5)
			ci.draw_line(Vector2(tx, GY), Vector2(tx, vr.position.y), Color(1.0, 0.4, 0.1, 0.18 * al), 2.0)
	if _cracks_made:
		var sa := t - _impact_t
		if sa >= 0.0 and sa < 1.6:
			var u2 := clampf(sa / 0.5, 0.0, 1.0)
			var h := 210.0 * (1.0 - pow(1.0 - u2, 2.5))
			var al2 := 1.0 - smoothstep(0.7, 1.6, sa)
			for k in 7:
				var xo := (float(k) - 3.0) * 16.0
				UD.flame(ci, _impact + Vector2(xo, 0.0), h * (0.5 + 0.5 * (1.0 - absf(float(k) - 3.0) / 3.5)), 34.0, t * 4.0 + float(k), 0.9 * al2)
			UD.glow(ci, _impact + Vector2(0.0, -60.0), 190.0, Color(1.0, 0.4, 0.1, 1.0), 0.45 * al2)


func _shade(ci: CanvasItem, t: float, _bc: Vector2, _fade: float) -> void:
	var sky := smoothstep(1.2, 1.9, t) * (1.0 - smoothstep(4.2, 4.8, t))
	var pre := smoothstep(0.0, 0.8, t) * 0.4
	var a := maxf(sky, pre)
	var vr := view().grow(8.0)
	var top := Color(0.30, 0.02, 0.0, 0.55 * a)
	var bot := Color(0.20, 0.02, 0.0, 0.20 * a)
	ci.draw_polygon(PackedVector2Array([vr.position, Vector2(vr.end.x, vr.position.y), vr.end, Vector2(vr.position.x, vr.end.y)]), PackedColorArray([top, top, bot, bot]))


func _front(ci: CanvasItem, t: float, bc: Vector2, fade: float) -> void:
	var body := smoothstep(0.2, 0.9, t) * fade
	if body > 0.01:
		for k in 7:
			var x := (float(k) - 3.0) * 4.5
			UD.flame(ci, bc + Vector2(x, 16.0), 14.0 + 10.0 * absf(sin(t * 9.0 + float(k) * 1.7)), 7.0, t * 4.0 + float(k), 0.55 * body)
	_draw_cracks(ci, t)


func _draw_cracks(ci: CanvasItem, t: float) -> void:
	if not _cracks_made:
		return
	var sa := t - _impact_t
	var fd := 1.0 - clampf((sa - 1.0) / 1.6, 0.0, 1.0)
	if fd <= 0.0:
		return
	for i in cracks.size():
		var cr: Dictionary = cracks[i]
		var pts: PackedVector2Array = cr["pts"]
		var gr := clampf((sa - float(cr["delay"])) / 0.35, 0.0, 1.0)
		if gr <= 0.0:
			continue
		var cnt := maxi(2, int(float(pts.size()) * gr))
		var sub := pts.slice(0, cnt)
		ci.draw_polyline(sub, Color(1.0, 0.4, 0.1, 0.55 * fd), 3.5)
		ci.draw_polyline(sub, Color(1.0, 0.85, 0.4, 0.95 * fd), 1.2)
	for k in 3:
		var ts := sa - float(k) * 0.08
		if ts > 0.0 and ts < 0.9:
			var g := ts / 0.9
			UD.ellipse(ci, _impact, (1.0 - pow(1.0 - g, 2.2)) * (360.0 + 80.0 * float(k)), 0.2, Color(1.0, 0.7, 0.3, (1.0 - g) * 0.8), maxf(1.0, 5.0 * (1.0 - g)))
