class_name Oni
extends Hazard

var t := randf() * 10.0
var speed := 48.0
var eyes: Array = []


func _build() -> void:
	hp = 3
	top_offset = -24.0
	score_value = 80
	_rect_shape(Vector2(14, 22), Vector2(0, -11))
	var occ := LightOccluder2D.new()
	var op := OccluderPolygon2D.new()
	op.polygon = PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(7, -22), Vector2(-7, -22)])
	occ.occluder = op
	occ.occluder_light_mask = 3
	add_child(occ)
	var eye_col := Color("#ffe14a")
	eyes.append(_glow_eye(Vector2(1, -22), eye_col, Vector2(2, 1.5)))
	eyes.append(_glow_eye(Vector2(4, -22), eye_col, Vector2(2, 1.5)))
	var l := PointLight2D.new()
	l.texture = TexGen.light_tex(1.6)
	l.texture_scale = 0.9
	l.color = Color("#ff7a3a")
	l.energy = 0.5
	l.position = Vector2(2, -20)
	l.range_item_cull_mask = 1
	add_child(l)


func _update(delta: float) -> void:
	t += delta
	global_position.x -= speed * delta
	queue_redraw()


func _draw() -> void:
	var skins := [Color("#ff303f"), Color("#358bff"), Color("#35ff8a")]
	var skin: Color = skins[tint % 3]
	var dark := skin.darkened(0.25)
	if hurt_flash > 0.0:
		skin = Color.WHITE
		dark = Color.WHITE
	var step := sin(t * 9.0)
	draw_rect(Rect2(-5 + step * 2.0, -8, 4, 8), dark)
	draw_rect(Rect2(1 - step * 2.0, -8, 4, 8), dark)
	draw_rect(Rect2(-7, -12, 14, 6), Color("#e8b030"))
	for i in 4:
		draw_rect(Rect2(-6 + i * 4, -12, 2, 6), Color("#201010"))
	draw_rect(Rect2(-6, -19, 12, 8), skin)
	draw_rect(Rect2(-6, -19, 3, 8), skin.lightened(0.2))
	draw_rect(Rect2(-5, -26, 11, 8), skin)
	draw_rect(Rect2(-5, -26, 11, 2), skin.lightened(0.25))
	SafeDraw.poly(self, PackedVector2Array([Vector2(-4, -26), Vector2(-3, -31), Vector2(-1, -26)]), Color("#f2e6c8"))
	SafeDraw.poly(self, PackedVector2Array([Vector2(2, -26), Vector2(4, -31), Vector2(5, -26)]), Color("#f2e6c8"))
	draw_rect(Rect2(1, -19, 1, 2), Color.WHITE)
	draw_rect(Rect2(4, -19, 1, 2), Color.WHITE)
	var ang := -0.9 + sin(t * 4.0) * 0.25
	var base := Vector2(5, -17)
	var tip := base + Vector2(sin(ang), -cos(ang)) * 17.0
	draw_line(base, tip, Color("#5a3a28"), 3.0)
	draw_circle(tip, 3.5, Color("#6a4a38"))
	draw_rect(Rect2(tip.x - 1, tip.y - 1, 2, 2), Color("#c8c8d8"))
