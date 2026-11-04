class_name CharPreview
extends Control

var char_id := "kage"
var locked := false
var t := randf() * 10.0


func _ready() -> void:
	if custom_minimum_size == Vector2.ZERO:
		custom_minimum_size = Vector2(260, 100)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	if is_visible_in_tree():
		t += delta
		queue_redraw()


func _limb(o: Vector2, a1: float, a2: float, l1: float = 6.0, l2: float = 6.0) -> PackedVector2Array:
	var mid := o + Vector2(sin(a1), cos(a1)) * l1
	var end := mid + Vector2(sin(a1 + a2), cos(a1 + a2)) * l2
	return PackedVector2Array([o, mid, end])


func _draw() -> void:
	var def := Characters.get_def(char_id)
	var pal: Dictionary = def["pal"]
	var dim := 0.55 if locked else 0.0
	var navy: Color = (pal["navy"] as Color).darkened(dim)
	var navy_l: Color = (pal["navy_l"] as Color).darkened(dim)
	var red: Color = (pal["red"] as Color).darkened(dim)
	var skin: Color = (pal["skin"] as Color).darkened(dim)
	var ec: Color = pal["eye"]
	var eye := Color(minf(ec.r, 1.0), minf(ec.g, 1.0), minf(ec.b, 1.0)).darkened(dim)
	var gc: Color = pal["glow"]
	var style := String(def["run_style"])

	var sc := 2.1
	var cx := size.x * 0.5
	var gy := size.y - 12.0
	draw_line(Vector2(24, gy), Vector2(size.x - 24, gy), Color(1, 1, 1, 0.14), 2.0)
	if not locked:
		draw_circle(Vector2(cx, gy - 38), 46.0, Color(gc.r, gc.g, gc.b, 0.08))
		draw_circle(Vector2(cx, gy - 38), 30.0, Color(gc.r, gc.g, gc.b, 0.10))

	var cadence := 1.0
	match style:
		"sprint": cadence = 1.25
		"stomp": cadence = 0.85
		"skate": cadence = 0.7
		"titan": cadence = 0.8
	var ph := t * 9.0 * cadence
	var s := sin(ph)
	var c := cos(ph)
	var lean := 0.16
	var bob := absf(s) * -1.4
	var a_arm := Vector2(-1.95 + s * 0.12, -0.15)
	var b_arm := Vector2(-1.75 - s * 0.12, -0.15)
	var a_leg := Vector2(s * 0.95, -0.35 - maxf(0.0, c) * 0.95)
	var b_leg := Vector2(-s * 0.95, -0.35 - maxf(0.0, -c) * 0.95)
	match style:
		"sprint":
			lean = 0.36
			bob = absf(s) * -1.8
			a_arm = Vector2(-0.2 + s * 0.9, 1.4)
			b_arm = Vector2(-0.2 - s * 0.9, 1.4)
			a_leg = Vector2(s * 1.15, -0.4 - maxf(0.0, c) * 1.15)
			b_leg = Vector2(-s * 1.15, -0.4 - maxf(0.0, -c) * 1.15)
		"stomp":
			lean = 0.08
			bob = absf(s) * -2.6
			a_arm = Vector2(-0.2 + s * 1.0, 0.5)
			b_arm = Vector2(-0.2 - s * 1.0, 0.5)
			a_leg = Vector2(s * 0.85, -0.2 - maxf(0.0, c) * 1.2)
			b_leg = Vector2(-s * 0.85, -0.2 - maxf(0.0, -c) * 1.2)
		"titan":
			lean = 0.12
			bob = absf(s) * -3.0
			a_arm = Vector2(-0.4 + s * 0.9, 0.35)
			b_arm = Vector2(-0.4 - s * 0.9, 0.35)
			a_leg = Vector2(s * 1.0, -0.25 - maxf(0.0, c) * 1.3)
			b_leg = Vector2(-s * 1.0, -0.25 - maxf(0.0, -c) * 1.3)
		"skate":
			lean = 0.22
			bob = sin(ph * 0.5) * -0.8
			a_arm = Vector2(1.25 + s * 0.15, -0.05)
			b_arm = Vector2(-1.35 - s * 0.15, -0.05)
			a_leg = Vector2(0.55 + s * 0.25, -0.2)
			b_leg = Vector2(-0.5 - s * 0.25, -0.1)

	var hip_world := Vector2(cx, gy - 12.5 * sc + bob * sc)
	var tf := func(v: Vector2) -> Vector2: return hip_world + v.rotated(lean) * sc
	var poly := func(pts: Array, col: Color) -> void:
		var out := PackedVector2Array()
		for q in pts:
			out.append(tf.call(q))
		SafeDraw.poly(self, out, col)
	var line := func(pts: PackedVector2Array, col: Color, w: float) -> void:
		var out := PackedVector2Array()
		for q in pts:
			out.append(tf.call(q))
		draw_polyline(out, col, w * sc)

	var overlord := String(def.get("extras", "")) == "overlord"
	var demon := String(def.get("extras", "")) == "demonlord"
	if demon and not locked:
		var dc: Vector2 = tf.call(Vector2(-0.5, -5.5))
		draw_circle(dc, 17.0 * sc, Color(0.55, 0.25, 1.0, 0.13))
		draw_circle(dc, 11.0 * sc, Color(1.0, 0.8, 0.3, 0.12))
		draw_arc(dc, 11.0 * sc, t * 2.0, t * 2.0 + TAU * 0.7, 24, Color(0.75, 0.45, 1.0, 0.8), 2.0)
		draw_arc(dc, 14.5 * sc, -t * 1.4, -t * 1.4 + TAU * 0.55, 24, Color(1.0, 0.84, 0.35, 0.8), 1.5)
	if overlord and not locked:
		var hc: Vector2 = tf.call(Vector2(-0.5, -5.5))
		draw_circle(hc, 15.0 * sc, Color(0.55, 1.0, 0.2, 0.10))
		draw_circle(hc, 10.0 * sc, Color(0.7, 1.0, 0.3, 0.10))
		draw_arc(hc, 11.0 * sc, t * 2.0, t * 2.0 + TAU * 0.75, 24, Color(0.7, 1.0, 0.3, 0.7), 2.0)
		draw_arc(hc, 14.0 * sc, -t * 1.5, -t * 1.5 + TAU * 0.6, 24, Color(1.0, 0.35, 0.15, 0.6), 1.5)
		for i in 8:
			var ra := t * 0.8 + float(i) * TAU / 8.0
			var rd := Vector2(cos(ra), sin(ra))
			draw_line(hc + rd * 9.0 * sc, hc + rd * (15.0 + 2.0 * sin(t * 6.0 + float(i))) * sc, Color(0.8, 1.0, 0.3, 0.5), 1.5)
	var shoulder := Vector2(-0.5, -9.0)
	line.call(_limb(shoulder, b_arm.x, b_arm.y), navy.darkened(0.25), 3.0)
	line.call(_limb(Vector2.ZERO, b_leg.x, b_leg.y), navy.darkened(0.3), 3.4)
	line.call(PackedVector2Array([Vector2(-1, -8.5), Vector2(-9, -22.5)]), Color("#aab4d0").darkened(dim), 1.6)
	poly.call([Vector2(-4, -10.5), Vector2(3.5, -10.5), Vector2(3, 0.5), Vector2(-3.5, 0.5)], navy)
	poly.call([Vector2(-4, -10.5), Vector2(-1, -10.5), Vector2(-1, 0.5), Vector2(-3.5, 0.5)], navy.darkened(0.25))
	poly.call([Vector2(-3.6, -1.0), Vector2(3.1, -1.0), Vector2(3.1, 1.0), Vector2(-3.6, 1.0)], red)
	poly.call([Vector2(0.5, -9.5), Vector2(3, -9.5), Vector2(3, -2.5), Vector2(1.5, -2.5)], navy_l)
	line.call(_limb(Vector2.ZERO, a_leg.x, a_leg.y), navy, 3.4)
	poly.call([Vector2(-4.5, -15.5), Vector2(-2, -18.5), Vector2(2, -18.5), Vector2(4.5, -15.5),
		Vector2(4.5, -11.5), Vector2(2, -9.5), Vector2(-2, -9.5), Vector2(-4.5, -11.5)], navy)
	poly.call([Vector2(0.5, -15), Vector2(4.5, -15), Vector2(4.5, -12.5), Vector2(0.5, -12.5)], skin)
	poly.call([Vector2(-4.5, -17), Vector2(4.5, -17), Vector2(4.5, -15.5), Vector2(-4.5, -15.5)], red)
	poly.call([Vector2(1.4, -14.7), Vector2(2.5, -14.7), Vector2(2.5, -13.5), Vector2(1.4, -13.5)], eye)
	poly.call([Vector2(3.2, -14.7), Vector2(4.3, -14.7), Vector2(4.3, -13.5), Vector2(3.2, -13.5)], eye)
	line.call(_limb(shoulder, a_arm.x, a_arm.y), navy, 3.0)
	if demon:
		var dk := Color("#0b0614").darkened(dim)
		poly.call([Vector2(-3.4, -17.0), Vector2(-7.6, -20.6), Vector2(-9.6, -28.2), Vector2(-5.2, -21.8), Vector2(-1.6, -17.8)], dk)
		poly.call([Vector2(2.4, -17.0), Vector2(5.2, -22.2), Vector2(9.8, -29.2), Vector2(7.2, -21.0), Vector2(4.6, -17.4)], dk)
		poly.call([Vector2(-8.4, -23.4), Vector2(-9.6, -28.2), Vector2(-6.6, -24.4)], red)
		poly.call([Vector2(8.0, -23.8), Vector2(9.8, -29.2), Vector2(6.8, -24.6)], red)
		poly.call([Vector2(-5.0, -10.0), Vector2(-11.0, -16.5), Vector2(-2.5, -11.0)], dk)
		poly.call([Vector2(0, -8.0), Vector2(2.8, -5.0), Vector2(0, -2.0), Vector2(-2.8, -5.0)], Color(1.0, 0.82, 0.3).darkened(dim))
	if overlord:
		var dark := navy.darkened(0.15)
		poly.call([Vector2(-3.2, -17.0), Vector2(-6.5, -25.5), Vector2(-1.2, -18.0)], dark)
		poly.call([Vector2(-5.4, -22.7), Vector2(-6.5, -25.5), Vector2(-4.3, -23.9)], red)
		poly.call([Vector2(2.0, -17.0), Vector2(7.0, -26.0), Vector2(4.5, -17.0)], dark)
		poly.call([Vector2(5.6, -22.9), Vector2(7.0, -26.0), Vector2(6.3, -21.7)], red)
		poly.call([Vector2(-5.0, -10.0), Vector2(-10.0, -15.5), Vector2(-2.5, -11.0)], dark)
		poly.call([Vector2(-6.5, -8.5), Vector2(-12.0, -10.0), Vector2(-3.0, -7.0)], dark)
		poly.call([Vector2(0.5, -13.0), Vector2(4.5, -13.0), Vector2(4.5, -10.3), Vector2(0.5, -10.3)], Color("#c9c4b8").darkened(dim))
		var cc: Vector2 = tf.call(Vector2(0, -5.0))
		if not locked:
			draw_circle(cc, 7.0 * sc * (0.8 + 0.2 * sin(t * 7.0)), Color(0.75, 1.0, 0.25, 0.30))
		poly.call([Vector2(0, -8.0), Vector2(2.6, -5.0), Vector2(0, -2.0), Vector2(-2.6, -5.0)], Color(0.8, 1.0, 0.3).darkened(dim))
	var sp := PackedVector2Array()
	for i in 9:
		var u := float(i) / 8.0
		sp.append(Vector2(-3.0 - float(i) * 3.2, -14.0 + sin(t * 11.0 - float(i) * 0.9) * 3.0 * u + u * 3.0))
	line.call(sp, red, 3.0)

	if locked:
		var lc := Vector2(size.x - 34, 30)
		draw_arc(lc + Vector2(0, -6), 8.0, PI, TAU, 14, Color(0.85, 0.85, 0.95, 0.9), 3.0)
		draw_rect(Rect2(lc.x - 11, lc.y - 6, 22, 17), Color(0.85, 0.85, 0.95, 0.95))
		draw_rect(Rect2(lc.x - 2, lc.y, 4, 7), Color(0.15, 0.15, 0.3))
