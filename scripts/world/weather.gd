class_name Weather
extends Node2D

var ps: CPUParticles2D
var kind := ""


func _ready() -> void:
	z_index = 20


func set_kind(k: String, theme: Dictionary) -> void:
	kind = k
	if ps:
		ps.queue_free()
	ps = CPUParticles2D.new()
	ps.local_coords = false
	ps.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ps.emission_rect_extents = Vector2(420, 3)
	ps.position = Vector2(0, -8)
	ps.material = Fx.unshaded_mat()
	var tc: Dictionary = theme["tree"]
	match k:
		"petals":
			ps.texture = TexGen.shape_tex("petal")
			ps.amount = 70
			ps.lifetime = 9.0
			ps.direction = Vector2(-1, 0.5)
			ps.spread = 25.0
			ps.initial_velocity_min = 25.0
			ps.initial_velocity_max = 70.0
			ps.gravity = Vector2(-6, 20)
			ps.angular_velocity_min = -180.0
			ps.angular_velocity_max = 180.0
			ps.scale_amount_min = 1.0
			ps.scale_amount_max = 1.8
			ps.color = (tc["c"] as Color).lerp(tc["a"], 0.4)
		"snow":
			ps.texture = TexGen.shape_tex("dust")
			ps.amount = 150
			ps.lifetime = 9.0
			ps.direction = Vector2(-1, 1)
			ps.spread = 30.0
			ps.initial_velocity_min = 8.0
			ps.initial_velocity_max = 30.0
			ps.gravity = Vector2(-4, 22)
			ps.scale_amount_min = 0.6
			ps.scale_amount_max = 1.6
			ps.color = Color(0.92, 0.97, 1.0, 0.95)
		"rain":
			ps.texture = TexGen.shape_tex("drop")
			ps.amount = 220
			ps.lifetime = 0.8
			ps.direction = Vector2(-0.3, 1)
			ps.spread = 3.0
			ps.initial_velocity_min = 320.0
			ps.initial_velocity_max = 420.0
			ps.gravity = Vector2.ZERO
			ps.angle_min = 16.0
			ps.angle_max = 16.0
			ps.scale_amount_min = 0.8
			ps.scale_amount_max = 1.4
			ps.color = Color(0.7, 0.8, 1.0, 0.55)
			ps.emission_rect_extents = Vector2(460, 3)
		"leaves":
			ps.texture = TexGen.shape_tex("leaf")
			ps.amount = 55
			ps.lifetime = 9.0
			ps.direction = Vector2(-1, 0.4)
			ps.spread = 30.0
			ps.initial_velocity_min = 25.0
			ps.initial_velocity_max = 75.0
			ps.gravity = Vector2(-10, 24)
			ps.angular_velocity_min = -220.0
			ps.angular_velocity_max = 220.0
			ps.scale_amount_min = 1.0
			ps.scale_amount_max = 2.0
			ps.color = (tc["a"] as Color).lerp(tc["c"], 0.3)
		"pollen":
			ps.texture = TexGen.shape_tex("dust")
			ps.amount = 55
			ps.lifetime = 10.0
			ps.direction = Vector2(-1, 0.1)
			ps.spread = 60.0
			ps.initial_velocity_min = 6.0
			ps.initial_velocity_max = 20.0
			ps.gravity = Vector2(-3, 1.5)
			ps.scale_amount_min = 0.6
			ps.scale_amount_max = 1.4
			ps.color = theme.get("pollen", Color(1.0, 0.95, 0.6, 0.8))
			ps.emission_rect_extents = Vector2(440, 90)
			ps.position = Vector2(0, 130)
		"embers":
			ps.texture = TexGen.shape_tex("spark")
			ps.amount = 90
			ps.lifetime = 5.0
			ps.direction = Vector2(0, -1)
			ps.spread = 35.0
			ps.initial_velocity_min = 25.0
			ps.initial_velocity_max = 70.0
			ps.gravity = Vector2(-12, -12)
			ps.scale_amount_min = 1.2
			ps.scale_amount_max = 2.6
			ps.color = Color(1.0, 0.55, 0.16, 0.95)
			ps.material = Fx.add_mat()
			ps.emission_rect_extents = Vector2(460, 6)
			ps.position = Vector2(0, 215)
		"spirits":
			ps.texture = TexGen.shape_tex("orb")
			ps.amount = 36
			ps.lifetime = 8.0
			ps.direction = Vector2(0, -1)
			ps.spread = 60.0
			ps.initial_velocity_min = 4.0
			ps.initial_velocity_max = 14.0
			ps.gravity = Vector2(0, -3)
			ps.scale_amount_min = 0.6
			ps.scale_amount_max = 1.4
			ps.color = (theme["moon"]["glow"] as Color)
			ps.material = Fx.add_mat()
			ps.emission_rect_extents = Vector2(380, 70)
			ps.position = Vector2(0, 190)
	ps.preprocess = ps.lifetime
	ps.emitting = true
	add_child(ps)


func follow(cam_x: float) -> void:
	if ps:
		ps.global_position.x = cam_x + (60.0 if kind != "rain" else 90.0)
