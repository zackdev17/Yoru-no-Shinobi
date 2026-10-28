class_name Coin
extends Node2D

var world: Node
var value := 1
var t := randf() * TAU
var attracted := false
var _last_w := -1.0
var glow: Sprite2D
var base_y := 0.0


func _ready() -> void:
	z_index = 3
	base_y = position.y
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = m
	glow = Sprite2D.new()
	glow.texture = TexGen.glow_tex(64)
	glow.scale = Vector2(0.38, 0.38)
	glow.modulate = Color(1.0, 0.8, 0.3, 0.55)
	var am := CanvasItemMaterial.new()
	am.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	am.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	glow.material = am
	add_child(glow)


func _process(delta: float) -> void:
	t += delta * 5.0
	var w := snappedf(absf(cos(t)), 0.25)
	if w != _last_w:
		_last_w = w
		queue_redraw()
	if not attracted:
		position.y = base_y + sin(t * 0.5) * 1.2


func _physics_process(delta: float) -> void:
	if world == null or world.player == null or world.player.dead:
		return
	var pc: Vector2 = world.player.global_position + Vector2(0, -13)
	var d := pc - global_position
	var dist := d.length()
	if dist < 14.0:
		world.collect_coin(self)
		queue_free()
		return
	if world.player.magnet_t > 0.0 and dist < 120.0:
		attracted = true
	if attracted:
		global_position += d.normalized() * (260.0 + (120.0 - minf(dist, 120.0)) * 3.0) * delta
	if global_position.x < world.cam_x - 380.0:
		queue_free()


func _draw() -> void:
	var w := maxf(0.2, _last_w)
	var pts := PackedVector2Array()
	for i in 12:
		var a := i * TAU / 12.0
		pts.append(Vector2(cos(a) * 5.0 * w, sin(a) * 5.0))
	SafeDraw.poly(self, pts, Color(1.0, 0.82, 0.25))
	var inner := PackedVector2Array()
	for i in 12:
		var a := i * TAU / 12.0
		inner.append(Vector2(cos(a) * 3.6 * w, sin(a) * 3.6))
	SafeDraw.poly(self, inner, Color(1.0, 0.92, 0.5))
	if w > 0.4:
		draw_rect(Rect2(-1.5 * w, -1.5, 3.0 * w, 3.0), Color(0.55, 0.32, 0.08))
	draw_arc(Vector2.ZERO, 5.0, -2.4, -0.7, 8, Color(1, 1, 0.85), 1.0)
