class_name Firefly
extends Node2D

var vel := Vector2.ZERO
var target := Vector2.ZERO
var t := randf() * 10.0
var light: PointLight2D
var glow: Sprite2D
var col := Color("#fff3a0")
var cam_ref := 0.0


func setup(c: Color, with_light: bool) -> void:
	col = c
	glow = Sprite2D.new()
	glow.texture = TexGen.glow_tex(64)
	glow.scale = Vector2(0.28, 0.28)
	glow.material = Fx.add_mat()
	glow.modulate = Color(c.r, c.g, c.b, 0.9)
	add_child(glow)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)])
	core.color = Color(1.8, 1.8, 1.6)
	core.material = Fx.unshaded_mat()
	add_child(core)
	if with_light:
		light = PointLight2D.new()
		light.texture = TexGen.light_tex(1.4)
		light.texture_scale = 1.1
		light.color = c
		light.energy = 0.8
		light.range_item_cull_mask = 1
		add_child(light)
	z_index = 7


func recolor(c: Color) -> void:
	col = c
	glow.modulate = Color(c.r, c.g, c.b, 0.9)
	if light:
		light.color = c


func step(delta: float, cam_x: float) -> void:
	t += delta
	if position.distance_to(target) < 8.0 or randf() < delta * 0.4:
		target = Vector2(position.x + randf_range(-50, 50), clampf(position.y + randf_range(-40, 40), 90.0, 205.0))
	vel = vel.lerp((target - position).normalized() * 18.0, delta * 1.5)
	position += vel * delta
	if position.x < cam_x - 350.0:
		position.x += 700.0
	elif position.x > cam_x + 350.0:
		position.x -= 700.0
	var f := 0.5 + 0.5 * sin(t * 3.0 + position.x * 0.1)
	glow.modulate.a = 0.35 + 0.65 * f
	if light:
		light.energy = 0.3 + 0.7 * f
