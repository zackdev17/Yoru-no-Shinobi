class_name Wisp
extends Hazard

var t := randf() * 10.0
var speed := 28.0
var base_y := 0.0
var light: PointLight2D
var col := Color("#7aa8ff")


func _build() -> void:
	top_offset = -8.0
	stompable = false
	score_value = 70
	base_y = position.y
	var th := Themes.at(tint)
	col = (th["moon"]["glow"] as Color).lerp(Color("#8a7aff"), 0.45)
	_circle_shape(6.0, Vector2.ZERO)
	light = PointLight2D.new()
	light.texture = TexGen.light_tex(1.3)
	light.texture_scale = 2.0
	light.color = col
	light.energy = 1.2
	light.range_item_cull_mask = 1
	light.shadow_enabled = false
	add_child(light)
	var g := Sprite2D.new()
	g.texture = TexGen.glow_tex(64)
	g.scale = Vector2(0.55, 0.55)
	g.modulate = Color(col.r, col.g, col.b, 0.7)
	g.material = Fx.add_mat()
	add_child(g)


func _update(delta: float) -> void:
	t += delta
	global_position.x -= speed * delta
	position.y = base_y + sin(t * 2.4) * 9.0
	light.energy = 1.0 + 0.3 * sin(t * 13.0) + 0.1 * sin(t * 31.0)
	queue_redraw()


func _draw() -> void:
	var c := col if hurt_flash <= 0.0 else Color.WHITE
	for i in 5:
		var u := float(i) / 5.0
		var p := Vector2(-3 - i * 3.0, sin(t * 8.0 + i) * 1.8 * (1.0 + u))
		draw_circle(p, 4.5 * (1.0 - u * 0.8), Color(c.r, c.g, c.b, 0.65 * (1.0 - u)))
	draw_circle(Vector2(0, 0), 5.0, c)
	draw_circle(Vector2(1, -0.5), 3.0, c.lightened(0.55))
	draw_circle(Vector2(1.5, -0.5), 1.4, Color.WHITE)
	draw_rect(Rect2(0, -2, 1, 1.5), Color(0.05, 0.05, 0.2))
	draw_rect(Rect2(3, -2, 1, 1.5), Color(0.05, 0.05, 0.2))
