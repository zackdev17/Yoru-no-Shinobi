class_name Crow
extends Hazard

var t := randf() * 10.0
var speed := 80.0
var base_y := 0.0
var amp := 5.0


func _build() -> void:
	top_offset = -7.0
	score_value = 60
	base_y = position.y
	_circle_shape(5.5, Vector2.ZERO)
	_glow_eye(Vector2(3, -3), Color("#ff3a3a"), Vector2(1.5, 1.5))


func _update(delta: float) -> void:
	t += delta
	global_position.x -= speed * delta
	position.y = base_y + sin(t * 3.0) * amp
	queue_redraw()


func _draw() -> void:
	var body := Color("#1a1a2c") if hurt_flash <= 0.0 else Color.WHITE
	var sheen := Color("#4a3a7a")
	var flap := sin(t * 20.0)
	SafeDraw.poly(self, PackedVector2Array([Vector2(-2, -1), Vector2(-13, -6 - flap * 5), Vector2(-3, 2)]), body.lightened(0.1))
	draw_circle(Vector2(0, 0), 5.0, body)
	draw_circle(Vector2(-1, -1.5), 2.2, sheen)
	draw_circle(Vector2(4, -2), 3.2, body)
	SafeDraw.poly(self, PackedVector2Array([Vector2(6, -3), Vector2(11, -1.5), Vector2(6, -0.5)]), Color("#e8a030"))
	SafeDraw.poly(self, PackedVector2Array([Vector2(-4, 0), Vector2(-12, 2), Vector2(-12, 4), Vector2(-4, 3)]), body)
	SafeDraw.poly(self, PackedVector2Array([Vector2(2, 0), Vector2(-8, -8 + flap * 6), Vector2(-3, 2)]), body)
