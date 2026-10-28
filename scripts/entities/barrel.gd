class_name Barrel
extends Hazard

var speed := 150.0
var spin := 0.0


func _build() -> void:
	top_offset = -18.0
	bouncy = true
	stompable = false
	shurikenable = false
	_circle_shape(8.5, Vector2(0, -9))


func _update(delta: float) -> void:
	global_position.x -= speed * delta
	spin -= speed * delta / 9.0
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(0, -9), spin, Vector2.ONE)
	draw_circle(Vector2.ZERO, 9.0, Color("#3a2018"))
	draw_circle(Vector2.ZERO, 7.5, Color("#b8302a"))
	draw_arc(Vector2.ZERO, 8.2, 0, TAU, 20, Color("#e8b84a"), 1.2)
	for i in 3:
		var a := i * TAU / 3.0
		var p := Vector2(cos(a), sin(a)) * 3.2
		draw_circle(p, 1.7, Color("#f4ecd8"))
		draw_arc(Vector2.ZERO, 3.2, a, a + 1.4, 6, Color("#f4ecd8"), 1.0)
	for i in 8:
		var a2 := i * TAU / 8.0
		draw_circle(Vector2(cos(a2), sin(a2)) * 8.6, 0.7, Color("#e8c050"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
