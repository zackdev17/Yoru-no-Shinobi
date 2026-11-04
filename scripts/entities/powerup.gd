class_name PowerUp
extends Node2D

const COLORS := {
	"shield": Color("#4ad0ff"), "magnet": Color("#ff5a5a"), "star": Color("#ffd84a"),
	"lightning": Color("#b48aff"), "heart": Color("#ff6aa8"),
}

var kind := "shield"
var world: Node
var t := randf() * TAU
var base_y := 0.0
var light: PointLight2D


func _ready() -> void:
	z_index = 4
	base_y = position.y
	var col: Color = COLORS[kind]
	light = PointLight2D.new()
	light.texture = TexGen.light_tex(1.4)
	light.texture_scale = 1.5
	light.color = col
	light.energy = 1.0
	light.range_item_cull_mask = 1
	add_child(light)
	var g := Sprite2D.new()
	g.texture = TexGen.glow_tex(64)
	g.scale = Vector2(0.7, 0.7)
	g.modulate = Color(col.r, col.g, col.b, 0.6)
	var am := CanvasItemMaterial.new()
	am.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	am.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	g.material = am
	add_child(g)
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = m
	queue_redraw()


func _process(delta: float) -> void:
	t += delta
	position.y = base_y + sin(t * 3.0) * 3.0
	light.energy = 0.9 + 0.25 * sin(t * 6.0)


func _physics_process(_delta: float) -> void:
	if world == null or world.player == null or world.player.dead:
		return
	var d: float = (world.player.global_position + Vector2(0, -13) - global_position).length()
	if d < 18.0:
		world.collect_powerup(kind, global_position)
		queue_free()
	elif global_position.x < world.cam_x - 380.0:
		queue_free()


func _draw() -> void:
	var col: Color = COLORS[kind]
	draw_circle(Vector2.ZERO, 9.0, col.darkened(0.55))
	draw_arc(Vector2.ZERO, 9.0, 0, TAU, 20, col, 1.5)
	draw_circle(Vector2.ZERO, 7.0, col.darkened(0.3))
	var w := Color.WHITE
	match kind:
		"shield":
			SafeDraw.poly(self, PackedVector2Array([Vector2(-4, -4), Vector2(4, -4), Vector2(4, 1), Vector2(0, 5), Vector2(-4, 1)]), w)
		"magnet":
			draw_arc(Vector2(0, -1), 4.0, PI, TAU, 8, w, 2.0)
			draw_rect(Rect2(-5, -1, 2, 5), w)
			draw_rect(Rect2(3, -1, 2, 5), w)
			draw_rect(Rect2(-5, 3, 2, 1), Color("#ff5a5a"))
			draw_rect(Rect2(3, 3, 2, 1), Color("#ff5a5a"))
		"star":
			var p := PackedVector2Array()
			for i in 10:
				var r := 5.5 if i % 2 == 0 else 2.4
				var a := -PI * 0.5 + i * PI / 5.0
				p.append(Vector2(cos(a), sin(a)) * r)
			SafeDraw.poly(self, p, w)
		"lightning":
			SafeDraw.poly(self, PackedVector2Array([Vector2(1, -6), Vector2(-4, 1), Vector2(-0.5, 1), Vector2(-1, 6), Vector2(4, -1.5), Vector2(0.5, -1.5)]), w)
		"heart":
			draw_circle(Vector2(-2, -2), 2.6, w)
			draw_circle(Vector2(2, -2), 2.6, w)
			SafeDraw.poly(self, PackedVector2Array([Vector2(-4.6, -1), Vector2(4.6, -1), Vector2(0, 5)]), w)
