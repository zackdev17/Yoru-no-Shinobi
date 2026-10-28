class_name Ground
extends StaticBody2D

const GROUND_Y := 216.0

var x0 := 0.0
var x1 := 0.0
var stage := 0


func setup(a: float, b: float, stg: int) -> void:
	x0 = a
	x1 = b
	stage = stg
	collision_layer = 1
	collision_mask = 0
	position = Vector2(a, GROUND_Y)
	var w := b - a
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(w, 90.0)
	cs.shape = r
	cs.position = Vector2(w * 0.5, 45.0)
	add_child(cs)

	var spr := Sprite2D.new()
	spr.texture = TexGen.ground_tex(stg)
	spr.centered = false
	spr.region_enabled = true
	spr.region_rect = Rect2(0, 0, w, TexGen.GH)
	spr.position = Vector2(0, -3)
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(spr)
