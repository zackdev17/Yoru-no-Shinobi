class_name Prop
extends Node2D

var kind := ""
var theme: Dictionary = {}
var light: PointLight2D
var base_energy := 1.0
var flame: Sprite2D
var phase := randf() * 100.0
var cloth: Polygon2D
var cloth_pts := PackedVector2Array()
var sc := 1.0
var lamp_f := 1.0


func setup(k: String, x: float, th: Dictionary, scale_v: float = 1.0) -> void:
	kind = k
	theme = th
	sc = scale_v
	position = Vector2(x, Ground.GROUND_Y)
	z_index = -8
	lamp_f = float(theme.get("lamp", 1.0))
	var lantern: Color = theme["lantern"]
	match kind:
		"stone_lantern":
			_make_light(Vector2(0, -22), lantern, 1.25, 2.6, true)
			_make_flame(Vector2(0, -22), lantern, 0.7)
		"paper_pole":
			_make_light(Vector2(0, -50), lantern, 1.35, 3.0, true)
			_make_flame(Vector2(0, -50), lantern, 1.0)
		"torii":
			z_index = -9
			_make_light(Vector2(0, -50 * sc), lantern.lerp(Color("#ff6a3a"), 0.5), 1.1, 3.4 * sc, false)
			_make_rays()
		"shrine":
			_make_light(Vector2(0, -18), lantern, 1.2, 2.4, true)
			_make_flame(Vector2(0, -16), lantern, 0.8)
		"banner":
			cloth = Polygon2D.new()
			cloth.color = Color("#a8222e")
			add_child(cloth)
			_update_cloth(0.0)
	queue_redraw()


func _make_light(pos: Vector2, col: Color, energy: float, tex_scale: float, shadows: bool) -> void:
	light = PointLight2D.new()
	light.texture = TexGen.light_tex(1.5)
	light.texture_scale = tex_scale
	light.color = col
	energy *= lamp_f
	light.energy = energy
	light.position = pos
	light.height = 24.0
	light.range_item_cull_mask = 1
	if shadows and GameState.settings["shadows"]:
		light.shadow_enabled = true
		light.shadow_filter = Light2D.SHADOW_FILTER_PCF5
		light.shadow_filter_smooth = 1.5
		light.shadow_item_cull_mask = 3
	base_energy = energy
	add_child(light)


func _make_flame(pos: Vector2, col: Color, s: float) -> void:
	flame = Sprite2D.new()
	flame.texture = TexGen.glow_tex(64)
	flame.position = pos
	flame.scale = Vector2(s, s) * 0.55
	flame.modulate = Color(col.r * 1.4, col.g * 1.3, col.b * 1.2, 0.95 * lamp_f)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	flame.material = m
	flame.z_index = 1
	add_child(flame)


func _make_rays() -> void:
	for i in 2:
		var s := Sprite2D.new()
		s.texture = TexGen.cone_tex()
		s.position = Vector2((i - 0.5) * 30.0 * sc, -62.0 * sc)
		s.scale = Vector2(0.7 * sc, 0.9 * sc)
		s.centered = true
		s.offset = Vector2(0, 64)
		var lantern: Color = theme["lantern"]
		s.modulate = Color(lantern.r, lantern.g, lantern.b, 0.22 * lerpf(0.35, 1.0, lamp_f))
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		s.material = m
		add_child(s)


func _process(delta: float) -> void:
	phase += delta
	if light:
		var f := 0.88 + 0.08 * sin(phase * 9.0) + 0.05 * sin(phase * 23.0 + 1.0) + 0.04 * sin(phase * 3.1)
		light.energy = base_energy * f
		if flame:
			flame.modulate.a = (0.75 + 0.2 * f) * lamp_f
	if cloth:
		_update_cloth(phase)


func _update_cloth(t: float) -> void:
	var pts := PackedVector2Array()
	var w := 15.0
	var h := 40.0
	var segs := 6
	for i in segs + 1:
		var u := float(i) / segs
		pts.append(Vector2(2.0 + u * w + sin(t * 3.0 + u * 3.0) * u * 2.0, -62.0 + sin(t * 4.0 + u * 5.0) * u * 1.5))
	for i in range(segs, -1, -1):
		var u := float(i) / segs
		pts.append(Vector2(2.0 + u * w + sin(t * 3.0 + u * 3.0 + 0.5) * u * 2.0, -62.0 + h + sin(t * 4.0 + u * 5.0 + 1.0) * u * 2.5))
	cloth.polygon = pts


func _draw() -> void:
	var wood := Color("#4a2d28")
	var stone := Color("#7d8199")
	var stone_d := Color("#4d5068")
	var red := Color("#b3262e")
	var red_d := Color("#6a1220")
	var lantern: Color = theme["lantern"]
	match kind:
		"stone_lantern":
			draw_rect(Rect2(-6, -4, 12, 4), stone_d)
			draw_rect(Rect2(-3, -14, 6, 10), stone)
			draw_rect(Rect2(-7, -17, 14, 3), stone)
			draw_rect(Rect2(-4, -26, 8, 9), stone_d)
			draw_rect(Rect2(-3, -25, 6, 7), Color(lantern.r, lantern.g, lantern.b, 0.5))
			SafeDraw.poly(self, PackedVector2Array([Vector2(-9, -26), Vector2(0, -33), Vector2(9, -26)]), stone)
			draw_rect(Rect2(-1, -35, 2, 3), stone)
			draw_rect(Rect2(-9, -27, 18, 2), stone.lightened(0.15))
		"paper_pole":
			draw_rect(Rect2(-2, -62, 4, 62), wood)
			draw_rect(Rect2(-1, -62, 1, 62), wood.lightened(0.3))
			draw_rect(Rect2(-8, -64, 16, 3), wood)
			draw_rect(Rect2(-6, -58, 12, 16), red.darkened(0.2))
			draw_rect(Rect2(-5, -57, 10, 14), Color(lantern.r, lantern.g * 0.8, lantern.b * 0.5, 1.0).lightened(0.15))
			draw_rect(Rect2(-6, -58, 12, 2), Color("#2a1418"))
			draw_rect(Rect2(-6, -44, 12, 2), Color("#2a1418"))
			draw_line(Vector2(0, -42), Vector2(0, -38), Color("#e8b84a"), 1.0)
			draw_rect(Rect2(-1, -38, 2, 3), Color("#e8b84a"))
		"banner":
			draw_rect(Rect2(0, -66, 2, 66), wood)
			draw_rect(Rect2(-2, -67, 20, 2), wood)
			draw_circle(Vector2(10, -42), 5.0, Color("#f4e8e8"))
			draw_circle(Vector2(10, -42), 2.0, Color("#a8222e"))
			for i in 5:
				var a := i * TAU / 5.0
				draw_circle(Vector2(10, -42) + Vector2(cos(a), sin(a)) * 3.6, 1.3, Color("#f4e8e8"))
		"torii":
			var s := sc
			var pw := 5.0 * s
			var hgt := 74.0 * s
			var span := 44.0 * s
			draw_rect(Rect2(-span - pw * 0.5, -hgt, pw, hgt), red)
			draw_rect(Rect2(span - pw * 0.5, -hgt, pw, hgt), red)
			draw_rect(Rect2(-span - pw * 0.5, -hgt, pw * 0.35, hgt), red.lightened(0.25))
			draw_rect(Rect2(span - pw * 0.5, -hgt, pw * 0.35, hgt), red.lightened(0.25))
			draw_rect(Rect2(-span - pw, -6 * s, pw * 2, 6 * s), Color("#1c1418"))
			draw_rect(Rect2(span - pw, -6 * s, pw * 2, 6 * s), Color("#1c1418"))
			draw_rect(Rect2(-span - 8 * s, -hgt + 12 * s, span * 2 + 16 * s, 4 * s), red)
			draw_rect(Rect2(-span - 8 * s, -hgt + 12 * s, span * 2 + 16 * s, 1 * s), red.lightened(0.3))
			var kas := PackedVector2Array([
				Vector2(-span - 16 * s, -hgt - 8 * s), Vector2(span + 16 * s, -hgt - 8 * s),
				Vector2(span + 8 * s, -hgt + 1 * s), Vector2(-span - 8 * s, -hgt + 1 * s)])
			SafeDraw.poly(self, kas, Color("#1c1418"))
			draw_rect(Rect2(-span - 10 * s, -hgt + 2 * s, span * 2 + 20 * s, 2 * s), red_d)
			draw_rect(Rect2(-14 * s, -hgt + 4 * s, 28 * s, 2 * s), Color("#d8c8a0"))
			for i in 4:
				draw_rect(Rect2((-10 + i * 7) * s, -hgt + 6 * s, 1.5 * s, 5 * s), Color("#f4ecd8"))
		"fence":
			for i in 5:
				draw_rect(Rect2(i * 7 - 18, -16, 3, 16), Color("#7a9a5a").darkened(0.35))
				draw_rect(Rect2(i * 7 - 18, -16, 1, 16), Color("#7a9a5a").darkened(0.1))
			draw_rect(Rect2(-19, -12, 34, 2), wood)
			draw_rect(Rect2(-19, -6, 34, 2), wood)
		"bush":
			var tc: Dictionary = theme["tree"]
			var a: Color = tc["b"]
			var b: Color = tc["a"]
			if tc["kind"] == "bamboo" or tc["kind"] == "pine":
				a = (tc["b"] as Color)
				b = (tc["a"] as Color)
			draw_circle(Vector2(-6, -6), 7.0, a)
			draw_circle(Vector2(5, -7), 8.0, a)
			draw_circle(Vector2(0, -10), 7.0, a)
			draw_circle(Vector2(-5, -8), 4.5, b)
			draw_circle(Vector2(5, -10), 4.5, b)
			if tc["kind"] == "pine":
				draw_circle(Vector2(0, -14), 4.0, tc["c"])
		"rock":
			SafeDraw.poly(self, PackedVector2Array([Vector2(-9, 0), Vector2(-6, -8), Vector2(2, -11), Vector2(9, -5), Vector2(10, 0)]), stone_d)
			SafeDraw.poly(self, PackedVector2Array([Vector2(-6, -8), Vector2(2, -11), Vector2(9, -5), Vector2(1, -6)]), stone)
		"shrine":
			draw_rect(Rect2(-10, -4, 20, 4), stone_d)
			draw_rect(Rect2(-8, -18, 16, 14), Color("#5a2e2a"))
			draw_rect(Rect2(-5, -16, 10, 11), Color(lantern.r, lantern.g, lantern.b, 0.45))
			SafeDraw.poly(self, PackedVector2Array([Vector2(-13, -17), Vector2(0, -27), Vector2(13, -17), Vector2(10, -16), Vector2(-10, -16)]), Color("#2c1c26"))
			draw_rect(Rect2(-8, -18, 16, 2), red)
