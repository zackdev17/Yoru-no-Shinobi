class_name Shuriken
extends Area2D

var world: Node
var speed := 540.0
var spin := 0.0
var trail := PackedVector2Array()
var line: Line2D
var life := 1.2


func _ready() -> void:
	collision_layer = 16
	collision_mask = 4
	z_index = 6
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 6.0
	cs.shape = c
	add_child(cs)
	area_entered.connect(_on_area)
	var l := PointLight2D.new()
	l.texture = TexGen.light_tex(1.4)
	l.texture_scale = 1.2
	l.color = Color("#7ad8ff")
	l.energy = 0.9
	l.range_item_cull_mask = 1
	add_child(l)
	line = Line2D.new()
	line.top_level = true
	line.width = 2.0
	line.default_color = Color(0.5, 0.85, 1.0, 0.7)
	line.material = Fx.add_mat()
	add_child(line)
	var m := CanvasItemMaterial.new()
	m.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	material = m


func _physics_process(delta: float) -> void:
	position.x += speed * delta
	spin += delta * 28.0
	life -= delta
	trail.append(global_position)
	if trail.size() > 7:
		trail.remove_at(0)
	line.points = trail
	queue_redraw()
	if life <= 0.0 or (world and global_position.x > world.cam_x + 380.0):
		queue_free()


func _on_area(a: Area2D) -> void:
	if a is Hazard:
		var h := a as Hazard
		if h.shurikenable and not h.dying:
			h.on_shuriken()
			Sfx.play("shuriken_impact", 1.0, -5.0)
			Fx.burst(world.fx_root, global_position, Color(0.6, 0.9, 1.0), 8, 90.0, 0.3, 100.0)
			queue_free()
		elif not h.shurikenable and h is Barrel:
			Fx.burst(world.fx_root, global_position, Color(1, 0.9, 0.5), 5, 60.0, 0.2, 80.0)
			Sfx.play("shuriken_ricochet", 1.0, -5.0)
			queue_free()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, spin, Vector2.ONE)
	var pts := PackedVector2Array()
	for i in 8:
		var r := 6.5 if i % 2 == 0 else 2.2
		var a := i * PI / 4.0
		pts.append(Vector2(cos(a), sin(a)) * r)
	SafeDraw.poly(self, pts, Color("#c8d4ee"))
	draw_circle(Vector2.ZERO, 1.4, Color("#2a3050"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
