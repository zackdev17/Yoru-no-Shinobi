class_name Fx
extends RefCounted

static var _add_mat: CanvasItemMaterial
static var _unshaded_mat: CanvasItemMaterial


static func add_mat() -> CanvasItemMaterial:
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		_add_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return _add_mat


static func unshaded_mat() -> CanvasItemMaterial:
	if _unshaded_mat == null:
		_unshaded_mat = CanvasItemMaterial.new()
		_unshaded_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	return _unshaded_mat


static func burst(parent: Node, pos: Vector2, color: Color, amount: int = 12, speed: float = 80.0,
		life: float = 0.5, gravity: float = 200.0, tex_kind: String = "spark", glow: bool = true,
		spread: float = 180.0, dir: Vector2 = Vector2.UP, scale_max: float = 2.0) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.amount = amount
	p.lifetime = life
	p.explosiveness = 0.95
	p.local_coords = false
	p.direction = dir
	p.spread = spread
	p.gravity = Vector2(0, gravity)
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.scale_amount_min = scale_max * 0.5
	p.scale_amount_max = scale_max
	p.texture = TexGen.shape_tex(tex_kind)
	var ramp := Gradient.new()
	ramp.set_color(0, color)
	ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
	p.color_ramp = ramp
	p.material = add_mat() if glow else unshaded_mat()
	p.z_index = 10
	p.position = pos
	parent.add_child(p)
	p.emitting = true
	parent.get_tree().create_timer(life + 0.3).timeout.connect(p.queue_free)
	return p


static func smoke(parent: Node, pos: Vector2, color: Color = Color(0.75, 0.72, 0.9, 0.9)) -> void:
	burst(parent, pos, color, 14, 55.0, 0.6, -20.0, "orb", false, 180.0, Vector2.UP, 2.4)
	burst(parent, pos, Color(1, 1, 1, 0.8), 6, 80.0, 0.35, 60.0, "spark", true, 180.0, Vector2.UP, 2.0)


static func ring(parent: Node, pos: Vector2, color: Color, r0: float = 4.0, r1: float = 28.0, life: float = 0.4, width: float = 2.0) -> void:
	var s := FxShape.new()
	s.kind = "ring"
	s.col = color
	s.r0 = r0
	s.r1 = r1
	s.life = life
	s.width = width
	s.position = pos
	parent.add_child(s)


static func slash(parent: Node, pos: Vector2, color: Color, radius: float = 26.0) -> void:
	var s := FxShape.new()
	s.kind = "slash"
	s.col = color
	s.r0 = radius * 0.7
	s.r1 = radius
	s.life = 0.22
	s.width = 5.0
	s.angle0 = -1.3
	s.angle1 = 1.3
	s.position = pos
	parent.add_child(s)


static func bolt(parent: Node, from: Vector2, to: Vector2, color: Color = Color(0.7, 0.8, 1.0), life: float = 0.25) -> void:
	var s := FxShape.new()
	s.kind = "bolt"
	s.col = color
	s.life = life
	s.width = 2.5
	var pts := PackedVector2Array()
	var n := 9
	for i in n + 1:
		var u := float(i) / n
		var p := from.lerp(to, u)
		if i > 0 and i < n:
			p += Vector2(randf_range(-8.0, 8.0), randf_range(-8.0, 8.0))
		pts.append(p)
	s.pts = pts
	parent.add_child(s)
