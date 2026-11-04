class_name Spikes
extends Hazard

var w := 24.0


func _build() -> void:
	top_offset = -12.0
	stompable = false
	shurikenable = false
	score_value = 0
	_rect_shape(Vector2(w - 4.0, 10.0), Vector2(0, -5))
	var occ := LightOccluder2D.new()
	var op := OccluderPolygon2D.new()
	op.polygon = PackedVector2Array([Vector2(-w * 0.5, 0), Vector2(w * 0.5, 0), Vector2(w * 0.5, -10), Vector2(-w * 0.5, -10)])
	occ.occluder = op
	occ.occluder_light_mask = 3
	add_child(occ)


func _draw() -> void:
	var n := int(w / 6.0)
	for i in n:
		var x := -w * 0.5 + i * 6.0 + 3.0
		var h := 12.0 - (i % 2) * 3.0
		SafeDraw.poly(self, PackedVector2Array([Vector2(x - 3, 0), Vector2(x, -h), Vector2(x + 3, 0)]), Color("#ff354f"))
		SafeDraw.poly(self, PackedVector2Array([Vector2(x, 0), Vector2(x, -h), Vector2(x + 3, 0)]), Color("#ff8a35"))
		SafeDraw.poly(self, PackedVector2Array([Vector2(x - 1, -h + 4), Vector2(x, -h), Vector2(x + 1, -h + 4)]), Color("#fff0a0"))
	draw_rect(Rect2(-w * 0.5 - 1, -2, w + 2, 2), Color("#ff4d3d"))
