class_name UD
extends RefCounted

static var DEBUG := false


static func poly(ci: CanvasItem, pts: PackedVector2Array, col: Color, tag: String = "") -> void:
	if pts.size() < 3 or col.a <= 0.004:
		return
	if Geometry2D.triangulate_polygon(pts).is_empty():
		if DEBUG:
			print("UD.poly invalid: ", tag, " n=", pts.size())
		return
	ci.draw_colored_polygon(pts, col)


static func glow(ci: CanvasItem, c: Vector2, r: float, col: Color, a: float = 1.0) -> void:
	if a <= 0.004 or r <= 0.5:
		return
	ci.draw_texture_rect(TexGen.glow_tex(128), Rect2(c - Vector2(r, r), Vector2(r * 2.0, r * 2.0)), false, Color(col.r, col.g, col.b, col.a * a))


static func ellipse(ci: CanvasItem, c: Vector2, r: float, sq: float, col: Color, wd: float = 1.0, a0: float = 0.0, a1: float = TAU, seg: int = 40) -> void:
	if col.a <= 0.004 or r <= 0.5:
		return
	var pts := PackedVector2Array()
	for i in seg + 1:
		var a := a0 + (a1 - a0) * float(i) / float(seg)
		pts.append(c + Vector2(cos(a) * r, sin(a) * r * sq))
	ci.draw_polyline(pts, col, wd)


static func dashed_ellipse(ci: CanvasItem, c: Vector2, r: float, sq: float, rot: float, col: Color, wd: float = 1.5, dashes: int = 12, frac: float = 0.55) -> void:
	if col.a <= 0.004 or r <= 0.5:
		return
	var step := TAU / float(dashes)
	for i in dashes:
		var a0 := rot + float(i) * step
		ellipse(ci, c, r, sq, col, wd, a0, a0 + step * frac, 6)


static func jag(a: Vector2, b: Vector2, jit: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var q := a.lerp(b, float(i) / float(n))
		if i > 0 and i < n:
			q += Vector2(randf_range(-jit, jit), randf_range(-jit, jit))
		pts.append(q)
	return pts


static func bolt(ci: CanvasItem, a: Vector2, b: Vector2, col: Color, am: float = 1.0, jit: float = 6.0, n: int = 7, wd: float = 1.6) -> void:
	var pts := jag(a, b, jit, n)
	ci.draw_polyline(pts, Color(col.r, col.g, col.b, col.a * 0.55 * am), wd * 2.4)
	ci.draw_polyline(pts, Color(col.r, col.g, col.b, col.a * 0.95 * am), wd)
	ci.draw_polyline(pts, Color(1, 1, 1, 0.9 * am), maxf(1.0, wd * 0.45))


static func taper(ci: CanvasItem, pts: PackedVector2Array, hw_max: float, col: Color, profile: int = 0) -> void:
	var n := pts.size()
	if n < 2 or col.a <= 0.004 or hw_max <= 0.05:
		return
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for i in n:
		var u := float(i) / float(n - 1)
		var d: Vector2
		if i == 0:
			d = pts[1] - pts[0]
		elif i == n - 1:
			d = pts[i] - pts[i - 1]
		else:
			d = pts[i + 1] - pts[i - 1]
		if d.length_squared() < 0.0001:
			d = Vector2.RIGHT
		var nm := Vector2(-d.y, d.x).normalized()
		var k := 0.0
		match profile:
			0: k = pow(u, 0.8)
			1: k = sin(u * PI)
			_: k = 1.0 - pow(u, 1.5)
		var hw := maxf(0.35, hw_max * k)
		left.append(pts[i] + nm * hw)
		right.append(pts[i] - nm * hw)
	right.reverse()
	left.append_array(right)
	poly(ci, left, col, "taper")


static func crescent(ci: CanvasItem, c: Vector2, amid: float, r: float, span: float, thick: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 11:
		var a := amid - span * 0.5 + span * float(i) / 10.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	taper(ci, pts, thick, col, 1)


static func flame(ci: CanvasItem, base: Vector2, h: float, wd: float, ph: float, a: float = 1.0) -> void:
	if h < 3.0 or a <= 0.01:
		return
	var layers := [
		[1.0, Color(1.0, 0.26, 0.05, 0.50)],
		[0.70, Color(1.0, 0.55, 0.12, 0.72)],
		[0.40, Color(1.0, 0.93, 0.60, 0.92)],
	]
	for L in layers:
		var k: float = L[0]
		var col: Color = L[1]
		var hh := h * (0.62 + 0.38 * k)
		var ww := wd * k
		var n := 6
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for i in n:
			var u := float(i) / float(n)
			var sway := sin(ph * 2.0 + u * 4.5) * wd * 0.45 * u
			var half := ww * 0.5 * (1.0 - pow(u, 1.6)) * (0.55 + 0.45 * sin(minf(1.0, u * 2.2) * PI * 0.5))
			left.append(base + Vector2(sway - half, -u * hh))
			right.append(base + Vector2(sway + half, -u * hh))
		var tip := base + Vector2(sin(ph * 2.0 + 4.5) * wd * 0.45, -hh)
		right.reverse()
		left.append(tip)
		left.append_array(right)
		poly(ci, left, Color(col.r, col.g, col.b, col.a * a), "flame")


static func crystal(ci: CanvasItem, base: Vector2, h: float, wd: float, col: Color, a: float = 1.0, tilt: float = 0.0) -> void:
	if h < 2.0 or a <= 0.01:
		return
	var tip := base + Vector2(tilt * h, -h)
	var l := base + Vector2(-wd, 0.0)
	var r := base + Vector2(wd, 0.0)
	var ml := base + Vector2(-wd * 0.85 + tilt * h * 0.5, -h * 0.58)
	var mr := base + Vector2(wd * 0.85 + tilt * h * 0.5, -h * 0.66)
	poly(ci, PackedVector2Array([l, ml, tip, base]), Color(col.r * 0.55, col.g * 0.8, col.b, 0.34 * a), "crystalL")
	poly(ci, PackedVector2Array([base, tip, mr, r]), Color(col.r, col.g, col.b, 0.50 * a), "crystalR")
	ci.draw_polyline(PackedVector2Array([l, ml, tip, mr, r]), Color(0.92, 0.99, 1.0, 0.9 * a), 1.2)
	ci.draw_line(base, tip, Color(1, 1, 1, 0.55 * a), 1.0)
	ci.draw_line(ml, mr, Color(1, 1, 1, 0.25 * a), 1.0)


static func feather(ci: CanvasItem, base: Vector2, ang: float, ln: float, wd: float, col: Color, a: float = 1.0) -> void:
	var d := Vector2(cos(ang), sin(ang))
	var nm := Vector2(-d.y, d.x)
	var tip := base + d * ln
	var mid := base + d * ln * 0.55
	var pts := PackedVector2Array([base + nm * wd * 0.35, mid + nm * wd, tip, mid - nm * wd, base - nm * wd * 0.35])
	poly(ci, pts, Color(col.r, col.g, col.b, col.a * 0.30 * a), "feather")
	ci.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[4]]), Color(0.95, 1.0, 1.0, 0.85 * a), 1.1)
	ci.draw_line(base, tip, Color(1, 1, 1, 0.45 * a), 1.0)


static func hex(ci: CanvasItem, c: Vector2, r: float, rot: float, col: Color, wd: float = 1.0, sq: float = 1.0) -> void:
	var pts := PackedVector2Array()
	for i in 7:
		var a := rot + float(i) * TAU / 6.0
		pts.append(c + Vector2(cos(a) * r, sin(a) * r * sq))
	ci.draw_polyline(pts, col, wd)


static func trefoil(ci: CanvasItem, c: Vector2, r: float, rot: float, col: Color) -> void:
	for k in 3:
		var a := rot + float(k) * TAU / 3.0
		ci.draw_arc(c, r, a - 0.5, a + 0.5, 8, col, maxf(2.0, r * 0.45))
	ci.draw_circle(c, maxf(1.5, r * 0.22), col)


const _SEG := {
	0: "abcdef", 1: "bc", 2: "abged", 3: "abgcd", 4: "fgbc",
	5: "afgcd", 6: "afgedc", 7: "abc", 8: "abcdefg", 9: "abcdfg",
}


static func seg7(ci: CanvasItem, c: Vector2, digit: int, sz: float, col: Color, wd: float = 3.0) -> void:
	var hw := sz * 0.30
	var hh := sz * 0.5
	var p := {
		"a": [Vector2(-hw, -hh), Vector2(hw, -hh)],
		"b": [Vector2(hw, -hh), Vector2(hw, 0.0)],
		"c": [Vector2(hw, 0.0), Vector2(hw, hh)],
		"d": [Vector2(-hw, hh), Vector2(hw, hh)],
		"e": [Vector2(-hw, 0.0), Vector2(-hw, hh)],
		"f": [Vector2(-hw, -hh), Vector2(-hw, 0.0)],
		"g": [Vector2(-hw, 0.0), Vector2(hw, 0.0)],
	}
	var on: String = _SEG.get(digit, "")
	for s in on:
		var seg: Array = p[s]
		ci.draw_line(c + seg[0], c + seg[1], Color(col.r, col.g, col.b, col.a * 0.35), wd * 2.6)
		ci.draw_line(c + seg[0], c + seg[1], col, wd)
		ci.draw_line(c + seg[0], c + seg[1], Color(1, 1, 1, col.a * 0.8), maxf(1.0, wd * 0.35))
