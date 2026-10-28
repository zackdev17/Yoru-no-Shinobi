class_name FxShape
extends Node2D

var kind := "ring"
var col := Color.WHITE
var r0 := 4.0
var r1 := 30.0
var life := 0.4
var width := 2.0
var pts := PackedVector2Array()
var angle0 := 0.0
var angle1 := 1.0
var t := 0.0


func _ready() -> void:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = m
	z_index = 12


func _process(delta: float) -> void:
	t += delta / life
	if t >= 1.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var a := (1.0 - t)
	var c := Color(col.r, col.g, col.b, col.a * a)
	match kind:
		"ring":
			var r := lerpf(r0, r1, 1.0 - pow(1.0 - t, 2.0))
			draw_arc(Vector2.ZERO, r, 0, TAU, 28, c, maxf(1.0, width * a))
		"slash":
			var r2 := lerpf(r0, r1, t * 0.5)
			draw_arc(Vector2.ZERO, r2, angle0, angle1, 14, c, maxf(1.0, width * (1.0 - t * 0.6)))
			draw_arc(Vector2.ZERO, r2 - 3.0, angle0 + 0.2, angle1 - 0.2, 12, Color(1, 1, 1, a * 0.8), 1.0)
		"bolt":
			if pts.size() >= 2:
				draw_polyline(pts, c, width * (0.5 + a))
				draw_polyline(pts, Color(1, 1, 1, a), 1.0)
