class_name BGLayer
extends Node2D

var kind := ""
var W := 1280.0
var k := 0.0
var tile := true
var glow_pass := false
var theme: Dictionary = {}
var seed_val := 1
var rng := RandomNumberGenerator.new()

const HORIZON := 206.0


func rebuild(t: Dictionary) -> void:
	theme = t
	queue_redraw()


func _draw() -> void:
	if theme.is_empty():
		return
	if tile:
		for off in [-W, 0.0, W]:
			draw_set_transform(Vector2(off, 0.0), 0.0, Vector2.ONE)
			rng.seed = seed_val
			_draw_kind()
	else:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		rng.seed = seed_val
		_draw_kind()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _cpoly(pts: PackedVector2Array, col: Color) -> void:
	if pts.size() >= 3 and not Geometry2D.triangulate_polygon(pts).is_empty():
		draw_colored_polygon(pts, col)


func _draw_kind() -> void:
	match kind:
		"sky": _sky()
		"stars": _stars()
		"moon": _moon()
		"rays": _rays()
		"aurora": _aurora()
		"clouds": _clouds()
		"fuji": _fuji()
		"ridge": _ridge()
		"village": _village()
		"trees": _trees()
		"lanterns": _lantern_strings()


func _sky() -> void:
	var s: Array = theme["sky"]
	var bands := 44
	var h := 232.0 / bands
	for i in bands:
		var t := float(i) / (bands - 1)
		var col: Color
		if t < 0.55:
			col = (s[0] as Color).lerp(s[1], t / 0.55)
		else:
			col = (s[1] as Color).lerp(s[2], pow((t - 0.55) / 0.45, 1.3))
		draw_rect(Rect2(-340, i * h, 680, h + 1.0), col)
	var w: Array = theme["water"]
	draw_rect(Rect2(-340, 230, 680, 80), (w[0] as Color))


func _stars() -> void:
	var dens: float = theme["stars"]
	var n := int(95 * dens)
	for i in n:
		var x := rng.randf() * W
		var y := rng.randf() * 170.0
		var b := rng.randf()
		var col := Color(0.85 + b * 0.15, 0.88 + b * 0.1, 1.0, 0.45 + b * 0.55)
		var sz := 1.0 if b < 0.88 else 2.0
		draw_rect(Rect2(floorf(x), floorf(y), sz, sz), col)
		if b > 0.96:
			draw_rect(Rect2(floorf(x) - 1, floorf(y), 4, 1), Color(col.r, col.g, col.b, 0.5))
			draw_rect(Rect2(floorf(x), floorf(y) - 1, 1, 4), Color(col.r, col.g, col.b, 0.5))


func _moon() -> void:
	var m: Dictionary = theme["moon"]
	var p: Vector2 = (m["pos"] as Vector2) - Vector2(320, 0)
	var r: float = m["r"]
	var col: Color = m["col"]
	var glow: Color = m["glow"]
	var is_sun: bool = theme.get("sun", false)
	if glow_pass:
		for i in 14:
			var rr := maxf(r, 18.0) * (1.15 + i * 0.42)
			draw_circle(p, rr, Color(glow.r, glow.g, glow.b, 0.045 if is_sun else 0.028))
		return
	if r <= 0.5:
		return
	if is_sun:
		draw_circle(p, r * 1.18, Color(glow.r, glow.g, glow.b, 0.35))
		draw_circle(p, r, col)
		draw_circle(p, r * 0.7, col.lightened(0.5))
		return
	draw_circle(p, r, col)
	var shade := col.darkened(0.14)
	for i in 8:
		var a := rng.randf() * TAU
		var d := rng.randf() * r * 0.65
		draw_circle(p + Vector2(cos(a), sin(a)) * d, 1.5 + rng.randf() * r * 0.17, Color(shade.r, shade.g, shade.b, 0.55))
	draw_arc(p, r - 1.0, -2.2, -0.2, 20, col.lightened(0.5), 2.0)


func _rays() -> void:
	if not glow_pass:
		return
	var m: Dictionary = theme["moon"]
	if (m["r"] as float) <= 0.5:
		return
	var p: Vector2 = (m["pos"] as Vector2) - Vector2(320, 0)
	var glow: Color = m["glow"]
	for i in 6:
		var a := deg_to_rad(80.0 + i * 16.0 + rng.randf() * 6.0)
		var wdt := 0.05 + rng.randf() * 0.05
		var dir1 := Vector2(cos(a - wdt), sin(a - wdt))
		var dir2 := Vector2(cos(a + wdt), sin(a + wdt))
		var ray_len := 420.0
		var pts := PackedVector2Array([p, p + dir1 * ray_len, p + dir2 * ray_len])
		var cols := PackedColorArray([
			Color(glow.r, glow.g, glow.b, 0.10),
			Color(glow.r, glow.g, glow.b, 0.0),
			Color(glow.r, glow.g, glow.b, 0.0),
		])
		draw_polygon(pts, cols)


func _aurora() -> void:
	if not glow_pass:
		return
	var m: Dictionary = theme["moon"]
	var g: Color = m["glow"]
	var cols := [g, g.lerp(Color(0.6, 0.3, 1.0), 0.5), g.lerp(Color(0.2, 1.0, 0.6), 0.5)]
	for band in 3:
		var c: Color = cols[band]
		var base := 38.0 + band * 22.0
		var ph := rng.randf() * TAU
		var step := 10.0
		var x := -340.0
		while x < 340.0:
			var y0 := base + sin(x * 0.012 + ph) * 18.0 + sin(x * 0.031 + ph * 2.0) * 6.0
			var y1 := y0 + 46.0 + sin(x * 0.02 + ph) * 12.0
			var yn0 := base + sin((x + step) * 0.012 + ph) * 18.0 + sin((x + step) * 0.031 + ph * 2.0) * 6.0
			var yn1 := yn0 + 46.0 + sin((x + step) * 0.02 + ph) * 12.0
			var pts := PackedVector2Array([Vector2(x, y0), Vector2(x + step, yn0), Vector2(x + step, yn1), Vector2(x, y1)])
			var top := Color(c.r, c.g, c.b, 0.0)
			var mid := Color(c.r, c.g, c.b, 0.16)
			draw_polygon(pts, PackedColorArray([mid, mid, top, top]))
			x += step


func _clouds() -> void:
	var n: int = theme["cloud_n"]
	var a: Color = theme["cloud_a"]
	var b: Color = theme["cloud_b"]
	for i in n:
		var cx := (float(i) + rng.randf() * 0.7) / n * W
		var cy := 28.0 + rng.randf() * 105.0
		var cw := 70.0 + rng.randf() * 110.0
		var puffs := 5 + rng.randi() % 4
		var circles: Array = []
		for j in puffs:
			var px := cx + (float(j) / (puffs - 1) - 0.5) * cw
			var rad := 9.0 + rng.randf() * 13.0 - absf(float(j) / (puffs - 1) - 0.5) * 8.0
			circles.append([Vector2(px, cy - rad * 0.3 * sin(float(j))), rad])
		for cc in circles:
			draw_circle((cc[0] as Vector2) + Vector2(1.5, -2.0), cc[1], b)
		for cc in circles:
			draw_circle(cc[0], cc[1], a)
		draw_rect(Rect2(cx - cw * 0.5, cy + 2.0, cw, 6.0), a)


func _fuji() -> void:
	var f: Array = theme["fuji"]
	var body: Color = f[0]
	var lit: Color = f[1]
	var snow: Color = f[2]
	var snow_sh: Color = f[3]
	var moon_x: float = (theme["moon"]["pos"] as Vector2).x - 320.0
	var lit_right := moon_x > 0.0
	var cx := W * 0.5
	var hw := 330.0
	var peak := 64.0
	var base := HORIZON + 2.0
	var steps := 34
	var left: Array = []
	var right: Array = []
	for i in steps + 1:
		var t := float(i) / steps
		var x := lerpf(hw, 14.0, t)
		var y := lerpf(base, peak, pow(t, 0.72))
		var jag := (rng.randf() - 0.5) * 2.4 * t
		left.append(Vector2(cx - x + jag, snappedf(y, 1.0)))
		right.append(Vector2(cx + x - jag, snappedf(y, 1.0)))
	var pts := PackedVector2Array()
	for p in left:
		pts.append(p)
	for i in range(right.size() - 1, -1, -1):
		pts.append(right[i])
	_cpoly(pts, body)
	var side: Array = right if lit_right else left
	var lp := PackedVector2Array()
	lp.append(Vector2(cx, peak - 1.0))
	for i in range(steps, -1, -1):
		lp.append(side[i])
	lp.append(Vector2(cx, base))
	_cpoly(lp, lit)
	var cap_y := peak + 52.0
	var ic := 0
	for i in steps + 1:
		if (left[i] as Vector2).y <= cap_y:
			ic = i
			break
	var xl: float = (left[ic] as Vector2).x
	var xr: float = (right[ic] as Vector2).x
	var zig := PackedVector2Array()
	var nz := 10
	for z in nz + 1:
		var u := float(z) / nz
		var jy := cap_y + (11.0 if z % 2 == 0 else -3.0) * (0.6 + rng.randf() * 0.8) + sin(u * PI) * 6.0
		zig.append(Vector2(lerpf(xl, xr, u), jy))
	var cap := PackedVector2Array()
	for i in range(ic, steps + 1):
		cap.append(left[i])
	for i in range(steps, ic - 1, -1):
		cap.append(right[i])
	for z in range(nz, -1, -1):
		cap.append(zig[z])
	_cpoly(cap, snow_sh)
	var cl := PackedVector2Array()
	cl.append(Vector2(cx, peak - 1.0))
	for i in range(steps, ic - 1, -1):
		cl.append(side[i])
	for z in nz + 1:
		var zz := z if lit_right else nz - z
		var q: Vector2 = zig[nz - zz] if lit_right else zig[zz]
		if (lit_right and q.x >= cx) or ((not lit_right) and q.x <= cx):
			cl.append(q)
	if cl.size() >= 3:
		_cpoly(cl, snow)
	var fog: Color = theme["fog"]
	for i in 7:
		draw_rect(Rect2(cx - hw - 10, base - 6.0 - i * 5.0, hw * 2.0 + 20.0, 5.0), Color(fog.r, fog.g, fog.b, 0.05 + (6 - i) * 0.02))


func _ridge() -> void:
	var far := seed_val % 2 == 0
	var col: Color = theme["mtn_far"] if far else theme["mtn_mid"]
	var base := HORIZON - (22.0 if far else 4.0)
	var amp := 40.0 if far else 26.0
	var c1 := 3 if far else 5
	var c2 := 7 if far else 11
	var c3 := 17 if far else 23
	var ph := float(seed_val) * 1.7
	var pts := PackedVector2Array()
	var step := 8.0
	var x := 0.0
	while x <= W + 0.1:
		var u := x / W * TAU
		var y := base - amp * (0.5 + 0.5 * sin(u * c1 + ph)) \
			- amp * 0.45 * (0.5 + 0.5 * sin(u * c2 + ph * 2.0)) \
			- amp * 0.12 * sin(u * c3 + ph * 3.0)
		pts.append(Vector2(x, snappedf(y, 2.0)))
		x += step
	pts.append(Vector2(W, HORIZON + 14.0))
	pts.append(Vector2(0, HORIZON + 14.0))
	_cpoly(pts, col)
	var fog: Color = theme["fog"]
	for i in 5:
		draw_rect(Rect2(0, HORIZON - 4.0 - i * 5.0, W, 5.0), Color(fog.r, fog.g, fog.b, 0.04 + (4 - i) * 0.012))


func _village() -> void:
	var col: Color = theme["village"]
	var win: Color = theme["window"]
	var base := HORIZON + 4.0
	var castle: bool = theme["castle"]
	var n := 9
	for i in n:
		var x := (float(i) + 0.15 + rng.randf() * 0.6) / n * W
		var kind_r := rng.randf()
		var s := 0.8 + rng.randf() * 0.5
		if castle and i == 4:
			_castle(x + 40.0, base, col, win)
			continue
		if kind_r < 0.28:
			_pagoda(x, base, s, col, win)
		elif kind_r < 0.7:
			_house(x, base, s, col, win)
		else:
			_pine_sil(x, base, s, col)
	if not glow_pass:
		var tc := Color(0.42, 0.1, 0.16)
		var tx := W * 0.18
		var ty := base + 8.0
		draw_rect(Rect2(tx - 14, ty - 34, 3, 36), tc)
		draw_rect(Rect2(tx + 11, ty - 34, 3, 36), tc)
		draw_rect(Rect2(tx - 20, ty - 38, 40, 4), tc)
		draw_rect(Rect2(tx - 16, ty - 28, 32, 3), tc)
		draw_rect(Rect2(tx - 22, ty - 40, 44, 2), tc.darkened(0.3))


func _house(x: float, base: float, s: float, col: Color, win: Color) -> void:
	var w := 26.0 * s
	var h := 14.0 * s
	var wall: Color = theme.get("wall", col)
	var roofc: Color = theme.get("roof", col)
	if not glow_pass:
		draw_rect(Rect2(x, base - h, w, h), wall)
		var roof := PackedVector2Array([
			Vector2(x - 5, base - h + 1), Vector2(x + w * 0.5, base - h - 11 * s), Vector2(x + w + 5, base - h + 1),
			Vector2(x + w + 2, base - h + 3), Vector2(x - 2, base - h + 3)])
		_cpoly(roof, roofc)
		draw_line(Vector2(x - 5, base - h + 1), Vector2(x + w * 0.5, base - h - 11 * s), roofc.lightened(0.18), 1.0)
	var lit := rng.randf() < 0.75
	var wx := x + w * 0.5 - 2.0
	var wy := base - h * 0.7
	if lit:
		if glow_pass:
			draw_circle(Vector2(wx + 2, wy + 2), 10.0, Color(win.r, win.g, win.b, 0.10))
			draw_circle(Vector2(wx + 2, wy + 2), 5.0, Color(win.r, win.g, win.b, 0.16))
		else:
			draw_rect(Rect2(wx, wy, 4, 5), win)


func _pagoda(x: float, base: float, s: float, col: Color, win: Color) -> void:
	var tiers := 4 + rng.randi() % 2
	var w := 22.0 * s
	var y := base
	var wall: Color = theme.get("wall", col)
	var roofc: Color = theme.get("roof", col)
	for t in tiers:
		var tw := w * (1.0 - t * 0.15)
		var th := 7.0 * s
		if not glow_pass:
			draw_rect(Rect2(x + (w - tw) * 0.5 + 2, y - th, tw - 4, th), wall)
			var roof := PackedVector2Array([
				Vector2(x + (w - tw) * 0.5 - 4, y - th + 1), Vector2(x + (w - tw) * 0.5 + 3, y - th - 3),
				Vector2(x + (w + tw) * 0.5 - 3, y - th - 3), Vector2(x + (w + tw) * 0.5 + 4, y - th + 1),
				Vector2(x + (w + tw) * 0.5, y - th + 3), Vector2(x + (w - tw) * 0.5, y - th + 3)])
			_cpoly(roof, roofc)
		elif t < 3 and rng.randf() < 0.8:
			var wx := x + w * 0.5 - 1.5
			draw_circle(Vector2(wx + 1.5, y - th * 0.55), 7.0, Color(win.r, win.g, win.b, 0.12))
		y -= th + 3.0
	if not glow_pass:
		draw_line(Vector2(x + w * 0.5, y + 2), Vector2(x + w * 0.5, y - 12), col, 1.0)


func _pine_sil(x: float, base: float, s: float, col: Color) -> void:
	if glow_pass:
		return
	for i in 4:
		var w := (18.0 - i * 3.5) * s
		var y := base - 8.0 * s - i * 8.0 * s
		_cpoly(PackedVector2Array([Vector2(x - w, y + 9 * s), Vector2(x, y - 4 * s), Vector2(x + w, y + 9 * s)]), col)
	draw_rect(Rect2(x - 1.5, base - 8, 3, 8), col)


func _castle(x: float, base: float, col: Color, win: Color) -> void:
	if glow_pass:
		draw_circle(Vector2(x + 50, base - 70), 14.0, Color(win.r, win.g, win.b, 0.10))
		draw_circle(Vector2(x + 50, base - 52), 14.0, Color(win.r, win.g, win.b, 0.10))
		return
	_cpoly(PackedVector2Array([Vector2(x - 6, base), Vector2(x + 106, base), Vector2(x + 92, base - 24), Vector2(x + 8, base - 24)]), col)
	var tiers := [[86.0, 22.0], [66.0, 20.0], [48.0, 18.0], [30.0, 16.0]]
	var y := base - 24.0
	for i in tiers.size():
		var tw: float = tiers[i][0]
		var th: float = tiers[i][1]
		var tx := x + 50.0 - tw * 0.5
		draw_rect(Rect2(tx + 4, y - th, tw - 8, th), col)
		var roof := PackedVector2Array([
			Vector2(tx - 9, y - th + 3), Vector2(tx + 6, y - th - 5), Vector2(tx + tw - 6, y - th - 5),
			Vector2(tx + tw + 9, y - th + 3), Vector2(tx + tw - 2, y - th + 6), Vector2(tx + 2, y - th + 6)])
		_cpoly(roof, col)
		draw_line(Vector2(tx - 9, y - th + 3), Vector2(tx + 6, y - th - 5), col.lightened(0.2), 1.0)
		draw_line(Vector2(tx + tw + 9, y - th + 3), Vector2(tx + tw - 6, y - th - 5), col.lightened(0.2), 1.0)
		if i > 0:
			draw_rect(Rect2(x + 50 - 3, y - th * 0.7, 6, 6), win)
		y -= th + 4.0
	draw_line(Vector2(x + 50, y + 2), Vector2(x + 50, y - 10), col, 1.5)
	draw_rect(Rect2(x + 45, y - 12, 4, 3), col)
	draw_rect(Rect2(x + 51, y - 12, 4, 3), col)


func _trees() -> void:
	var t: Dictionary = theme["tree"]
	var kind_s: String = t["kind"]
	var n := 6 if kind_s != "bamboo" else 5
	for i in n:
		var x := (float(i) + 0.2 + rng.randf() * 0.6) / n * W
		var s := 0.85 + rng.randf() * 0.5
		match kind_s:
			"sakura": _tree_blossom(x, s, t, false)
			"maple": _tree_blossom(x, s, t, true)
			"pine": _tree_pine(x, s, t)
			"bamboo": _tree_bamboo(x, s, t)


func _tree_blossom(x: float, s: float, t: Dictionary, sharp: bool) -> void:
	var base := 216.0
	var trunk: Color = t["trunk"]
	var a: Color = t["a"]
	var b: Color = t["b"]
	var c: Color = t["c"]
	var h := 70.0 * s
	var lean := (rng.randf() - 0.5) * 22.0
	var pts := PackedVector2Array([Vector2(x, base), Vector2(x + lean * 0.4, base - h * 0.5), Vector2(x + lean, base - h)])
	draw_polyline(pts, trunk, 7.0 * s)
	draw_line(Vector2(x + lean * 0.5, base - h * 0.55), Vector2(x + lean - 26 * s, base - h - 6 * s), trunk, 3.0 * s)
	draw_line(Vector2(x + lean * 0.6, base - h * 0.65), Vector2(x + lean + 28 * s, base - h - 2 * s), trunk, 3.0 * s)
	var cx := x + lean
	var cy := base - h - 8.0 * s
	var count := 14
	var puffs: Array = []
	for i in count:
		var ang := rng.randf() * TAU
		var d := rng.randf() * 30.0 * s
		puffs.append([Vector2(cx + cos(ang) * d * 1.3, cy + sin(ang) * d * 0.7), (11.0 + rng.randf() * 12.0) * s])
	for p in puffs:
		draw_circle(p[0], p[1], b)
	for p in puffs:
		draw_circle((p[0] as Vector2) + Vector2(1.0, -2.0), (p[1] as float) * 0.82, a)
	for p in puffs:
		if rng.randf() < 0.55:
			draw_circle((p[0] as Vector2) + Vector2(3.0, -5.0), (p[1] as float) * 0.38, c)
	if sharp:
		for i in 10:
			var pp := Vector2(cx + (rng.randf() - 0.5) * 60 * s, cy + (rng.randf() - 0.3) * 30 * s)
			_cpoly(PackedVector2Array([pp + Vector2(0, -3), pp + Vector2(3, 0), pp + Vector2(0, 3), pp + Vector2(-3, 0)]), c)


func _tree_pine(x: float, s: float, t: Dictionary) -> void:
	var base := 216.0
	var a: Color = t["a"]
	var b: Color = t["b"]
	var snow: Color = t["c"]
	draw_rect(Rect2(x - 2.5 * s, base - 14 * s, 5 * s, 14 * s), t["trunk"])
	var layers := 6
	for i in layers:
		var w := (26.0 - i * 3.6) * s
		var y := base - 14.0 * s - i * 12.0 * s
		var tri := PackedVector2Array([Vector2(x - w, y), Vector2(x, y - 20 * s), Vector2(x + w, y)])
		_cpoly(tri, b)
		var tri2 := PackedVector2Array([Vector2(x - w + 3, y - 1), Vector2(x + 1, y - 20 * s + 1), Vector2(x + w, y - 1)])
		_cpoly(tri2, a)
		var cap := PackedVector2Array([Vector2(x - w * 0.55, y - 9 * s), Vector2(x, y - 20 * s), Vector2(x + w * 0.55, y - 9 * s),
			Vector2(x + w * 0.2, y - 7 * s), Vector2(x - w * 0.15, y - 9.5 * s)])
		_cpoly(cap, snow)


func _tree_bamboo(x: float, s: float, t: Dictionary) -> void:
	var base := 216.0
	var trunk: Color = t["trunk"]
	var a: Color = t["a"]
	var c: Color = t["c"]
	for i in 5:
		var bx := x + (i - 2) * 9.0 + rng.randf() * 4.0
		var top := 6.0 + rng.randf() * 60.0
		var w := 4.0 * s
		draw_rect(Rect2(bx, top, w, base - top), trunk)
		draw_rect(Rect2(bx + w - 1.5, top, 1.5, base - top), a)
		var y := base - 22.0
		while y > top:
			draw_rect(Rect2(bx - 0.5, y, w + 1.0, 2.0), trunk.darkened(0.3))
			if rng.randf() < 0.5:
				var dir := 1.0 if rng.randf() < 0.5 else -1.0
				draw_line(Vector2(bx + 2, y), Vector2(bx + 2 + dir * 12, y - 6), a, 2.0)
				draw_line(Vector2(bx + 2 + dir * 12, y - 6), Vector2(bx + 2 + dir * 18, y - 3), c.darkened(0.2), 1.0)
			y -= 22.0


func _lantern_strings() -> void:
	var lc: Color = theme["lantern"]
	var segs := 4
	var sw := W / segs
	for sgi in segs:
		var x0 := sgi * sw
		var y0 := 10.0 + (sgi % 2) * 6.0
		var sag := 26.0 + rng.randf() * 10.0
		var pts := PackedVector2Array()
		for i in 13:
			var t := float(i) / 12.0
			pts.append(Vector2(x0 + t * sw, y0 + sag * 4.0 * t * (1.0 - t)))
		if not glow_pass:
			draw_polyline(pts, Color(0.12, 0.05, 0.1), 1.0)
			draw_rect(Rect2(x0 - 2, y0 - 10, 4, 220), Color(0.12, 0.05, 0.1))
		for i in range(1, 12, 2):
			var p: Vector2 = pts[i]
			if glow_pass:
				draw_circle(p + Vector2(0, 7), 16.0, Color(lc.r, lc.g, lc.b, 0.07))
				draw_circle(p + Vector2(0, 7), 8.0, Color(lc.r, lc.g, lc.b, 0.12))
			else:
				draw_rect(Rect2(p.x - 1, p.y, 2, 3), Color(0.1, 0.05, 0.1))
				draw_rect(Rect2(p.x - 4, p.y + 3, 8, 9), lc.darkened(0.25))
				draw_rect(Rect2(p.x - 3, p.y + 4, 6, 7), lc.lightened(0.15))
				draw_rect(Rect2(p.x - 4, p.y + 3, 8, 1), Color(0.1, 0.05, 0.1))
				draw_rect(Rect2(p.x - 4, p.y + 11, 8, 1), Color(0.1, 0.05, 0.1))
