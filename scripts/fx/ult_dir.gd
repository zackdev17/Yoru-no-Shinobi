class_name UltDir
extends Node2D

const GY := 216.0
const MAX_PARTS := 280

var w: World
var p: Ninja
var kind := ""
var age := 0.0
var rd := 0.016
var light: PointLight2D
var back: Node2D
var shade: Node2D
var parts: Array = []


func setup(world: World, player: Ninja, k: String) -> void:
	w = world
	p = player
	kind = k
	material = Fx.add_mat()
	z_index = 22
	back = Node2D.new()
	back.material = Fx.add_mat()
	back.z_as_relative = false
	back.z_index = 4
	back.draw.connect(_on_back_draw)
	add_child(back)
	shade = Node2D.new()
	shade.material = Fx.unshaded_mat()
	shade.z_as_relative = false
	shade.z_index = 3
	shade.draw.connect(_on_shade_draw)
	add_child(shade)
	light = PointLight2D.new()
	light.texture = TexGen.glow_tex(128)
	light.texture_scale = 3.0
	light.range_item_cull_mask = 1
	light.energy = 0.0
	light.color = _pal()[0]
	add_child(light)
	_init_fx()


func _pal() -> Array:
	return [Color(1, 1, 1), Color(1, 1, 1), Color(1, 1, 1)]


func _init_fx() -> void:
	pass


func _tick(_t: float, _bc: Vector2) -> void:
	pass


func _light_energy(_t: float) -> float:
	return 0.0


func _back(_ci: CanvasItem, _t: float, _bc: Vector2, _fade: float) -> void:
	pass


func _shade(_ci: CanvasItem, _t: float, _bc: Vector2, _fade: float) -> void:
	pass


func _front(_ci: CanvasItem, _t: float, _bc: Vector2, _fade: float) -> void:
	pass


func view() -> Rect2:
	var z := maxf(w.cam.zoom.x, 0.1)
	var half := Vector2(320.0, 144.0) / z
	return Rect2(w.cam.position - half, half * 2.0)


func _fade_now() -> float:
	return clampf((p.ult_len - p.ultimate_elapsed) / 0.7, 0.0, 1.0)


func emit(pos: Vector2, vel: Vector2, life: float, sz: float, col: Color, grav: float = 0.0, drag: float = 0.0, shape: int = 0, spin: float = 0.0) -> void:
	if parts.size() >= MAX_PARTS:
		return
	parts.append({"p": pos, "v": vel, "g": grav, "d": drag, "life": life, "t": 0.0, "sz": sz, "c": col, "s": shape, "r": randf() * TAU, "w": spin})


func _update_parts() -> void:
	for i in range(parts.size() - 1, -1, -1):
		var q: Dictionary = parts[i]
		q["t"] = float(q["t"]) + rd
		if float(q["t"]) >= float(q["life"]):
			parts.remove_at(i)
			continue
		var v: Vector2 = q["v"]
		v.y += float(q["g"]) * rd
		v *= maxf(0.0, 1.0 - float(q["d"]) * rd)
		q["v"] = v
		q["p"] = (q["p"] as Vector2) + v * rd
		q["r"] = float(q["r"]) + float(q["w"]) * rd


func _draw_parts(ci: CanvasItem, a_mul: float = 1.0) -> void:
	for q in parts:
		var d: Dictionary = q
		var u := float(d["t"]) / float(d["life"])
		var c: Color = d["c"]
		var a := c.a * a_mul * sin(clampf(u, 0.0, 1.0) * PI) * 1.4
		a = minf(a, 1.0)
		var pos: Vector2 = d["p"]
		var sz: float = d["sz"]
		match int(d["s"]):
			1:
				var v: Vector2 = d["v"]
				var dir := v.normalized() if v.length() > 1.0 else Vector2.RIGHT
				ci.draw_line(pos - dir * sz * 3.0, pos, Color(c.r, c.g, c.b, a), maxf(1.0, sz * 0.5))
			2:
				var r: float = d["r"]
				var e1 := Vector2(cos(r), sin(r)) * sz
				var e2 := Vector2(cos(r + 2.4), sin(r + 2.4)) * sz * 0.7
				var e3 := Vector2(cos(r - 2.1), sin(r - 2.1)) * sz * 0.45
				UD.poly(ci, PackedVector2Array([pos + e1, pos + e2, pos + e3]), Color(c.r, c.g, c.b, a * 0.7), "part")
				ci.draw_polyline(PackedVector2Array([pos + e1, pos + e2, pos + e3, pos + e1]), Color(1, 1, 1, a * 0.8), 1.0)
			_:
				ci.draw_rect(Rect2(pos - Vector2(sz * 0.5, sz * 0.5), Vector2(sz, sz)), Color(c.r, c.g, c.b, a))


func _process(delta: float) -> void:
	if w == null or p == null or not is_instance_valid(p):
		queue_free()
		return
	rd = delta / maxf(Engine.time_scale, 0.05)
	age += rd
	if not p.ultimate_active and age > 0.5:
		queue_free()
		return
	var t := p.ultimate_elapsed
	var bc := p.pivot.global_position
	_tick(t, bc)
	_update_parts()
	light.position = bc
	light.energy = _light_energy(t) * _fade_now()
	queue_redraw()
	back.queue_redraw()
	shade.queue_redraw()


func _draw() -> void:
	if w == null or p == null or not is_instance_valid(p):
		return
	var t := p.ultimate_elapsed
	_front(self, t, p.pivot.global_position, _fade_now())
	_draw_parts(self)


func _on_back_draw() -> void:
	if w == null or p == null or not is_instance_valid(p):
		return
	_back(back, p.ultimate_elapsed, p.pivot.global_position, _fade_now())


func _on_shade_draw() -> void:
	if w == null or p == null or not is_instance_valid(p):
		return
	_shade(shade, p.ultimate_elapsed, p.pivot.global_position, _fade_now())
