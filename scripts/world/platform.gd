class_name Platform
extends StaticBody2D

var w := 64.0
var theme: Dictionary = {}


func setup(x: float, y: float, width: float, th: Dictionary) -> void:
	w = width
	theme = th
	position = Vector2(x, y)
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(w, 6.0)
	cs.shape = r
	cs.position = Vector2(w * 0.5, 3.0)
	cs.one_way_collision = true
	add_child(cs)
	var occ := LightOccluder2D.new()
	var op := OccluderPolygon2D.new()
	op.polygon = PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, 9), Vector2(0, 9)])
	occ.occluder = op
	occ.occluder_light_mask = 3
	add_child(occ)
	queue_redraw()


func _draw() -> void:
	var wood := Color("#7a4a34")
	var wood_d := Color("#4a2a22")
	var red := Color("#b0242c")
	var red_d := Color("#6e1220")
	var gold := Color("#e8b84a")
	draw_rect(Rect2(0, 6, w, 3), wood_d)
	draw_rect(Rect2(0, 0, w, 7), wood)
	draw_rect(Rect2(0, 0, w, 2), wood.lightened(0.25))
	var x := 12.0
	while x < w - 12.0:
		draw_rect(Rect2(x, 2, 1, 5), wood_d)
		x += 10.0
	for side in 2:
		var ex := 0.0 if side == 0 else w - 11.0
		draw_rect(Rect2(ex, -1, 11, 10), red)
		draw_rect(Rect2(ex, -1, 11, 2), red.lightened(0.3))
		draw_rect(Rect2(ex, 7, 11, 2), red_d)
		draw_rect(Rect2(ex + (8 if side == 0 else 1), -1, 2, 10), gold)
		draw_rect(Rect2(ex + 4, 2, 3, 3), gold)
	draw_line(Vector2(w * 0.5, 7), Vector2(w * 0.5, 12), gold.darkened(0.3), 1.0)
	draw_rect(Rect2(w * 0.5 - 1, 12, 3, 3), gold)
