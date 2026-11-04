class_name Hazard
extends Area2D

var world: Node
var hp := 2
var max_hp := 2
var health_bar_root: Node2D
var health_fill: Polygon2D
var stompable := true
var bouncy := false
var shurikenable := true
var score_value := 50
var dying := false
var top_offset := -22.0
var hurt_flash := 0.0
var tint := 0
var contact_enabled := true
var frozen_t := 0.0
var _ice: Polygon2D


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	z_index = 2
	_build()
	max_hp = maxi(1, hp)
	if shurikenable:
		health_bar_root = Node2D.new()
		health_bar_root.position = Vector2(0, top_offset - 8.0)
		health_bar_root.z_index = 8
		add_child(health_bar_root)
		var back := Polygon2D.new()
		back.polygon = PackedVector2Array([Vector2(-9, -1), Vector2(9, -1), Vector2(9, 2), Vector2(-9, 2)])
		back.color = Color("#241a2a")
		health_bar_root.add_child(back)
		health_fill = Polygon2D.new()
		health_fill.color = Color("#ff365f")
		health_bar_root.add_child(health_fill)
		_update_health_bar()


func _build() -> void:
	pass


func _update(_delta: float) -> void:
	pass


func freeze(secs: float) -> void:
	if dying or not shurikenable or secs <= 0.0:
		return
	var was := frozen_t > 0.0
	frozen_t = maxf(frozen_t, secs)
	if not was:
		_show_ice(true)
		Fx.burst(world.fx_root, global_position + Vector2(0, -12), Color(0.7, 0.92, 1.0), 10, 70.0, 0.4, 60.0, "spark", true, 360.0, Vector2.UP, 1.8)
		Sfx.play("freeze_snap", 0.85, -7.0)


func _show_ice(on: bool) -> void:
	if on:
		if _ice == null:
			_ice = Polygon2D.new()
			var t := top_offset
			_ice.polygon = PackedVector2Array([
				Vector2(-9, 1), Vector2(-11, t * 0.45), Vector2(-6, t - 2.0), Vector2(0, t - 5.0),
				Vector2(6, t - 2.0), Vector2(11, t * 0.45), Vector2(9, 1)])
			_ice.color = Color(0.55, 0.9, 1.0, 0.42)
			_ice.material = Fx.add_mat()
			_ice.z_index = 3
			add_child(_ice)
		modulate = Color(0.7, 0.9, 1.3)
	else:
		if _ice != null:
			_ice.queue_free()
			_ice = null
		modulate = Color.WHITE


func _physics_process(delta: float) -> void:
	if dying or world == null:
		return
	hurt_flash = maxf(0.0, hurt_flash - delta)
	if frozen_t > 0.0:
		frozen_t = maxf(0.0, frozen_t - delta)
		if frozen_t <= 0.0:
			_show_ice(false)
		else:
			for b in get_overlapping_bodies():
				if b is Ninja:
					Fx.burst(world.fx_root, global_position + Vector2(0, -12), Color(0.75, 0.95, 1.0), 16, 150.0, 0.5, 260.0, "spark", true, 360.0, Vector2.UP, 2.2)
					Fx.ring(world.fx_root, global_position + Vector2(0, -12), Color(0.8, 0.95, 1.0, 0.9), 3.0, 26.0, 0.3, 2.0)
					Sfx.play("freeze_snap", 1.0, -5.0)
					kill("freeze")
					return
			if global_position.x < world.cam_x - 380.0:
				queue_free()
			return
	_update(delta)
	if contact_enabled:
		for b in get_overlapping_bodies():
			if b is Ninja:
				(b as Ninja).hazard_contact(self)
	if global_position.x < world.cam_x - 380.0:
		queue_free()


func top_y() -> float:
	return global_position.y + top_offset


func on_shuriken() -> void:
	take_damage(1, "shuriken")

func take_damage(amount: int = 1, source: String = "skill") -> void:
	if dying:
		return
	hp -= amount
	_update_health_bar()
	hurt_flash = 0.22
	Fx.burst(world.fx_root, global_position + Vector2(0, -12), Color("#ff4f70"), 7, 85.0, 0.22, 120.0)
	if hp <= 0:
		kill(source)
	else:
		var hurt_key := "enemy_hurt_skill"
		match source:
			"shuriken": hurt_key = "enemy_hurt_shuriken"
			"fire": hurt_key = "enemy_hurt_fire"
			"ice", "shatter", "freeze": hurt_key = "enemy_hurt_ice"
			"plasma", "radiation", "nuke", "eclipse": hurt_key = "enemy_hurt_plasma"
		Sfx.play(hurt_key, randf_range(0.96, 1.04), -7.0)


func _update_health_bar() -> void:
	if not is_instance_valid(health_fill):
		return
	var ratio := clampf(float(hp) / float(maxi(1, max_hp)), 0.0, 1.0)
	var w := 18.0 * ratio
	health_fill.polygon = PackedVector2Array([Vector2(-9, -1), Vector2(-9 + w, -1), Vector2(-9 + w, 2), Vector2(-9, 2)])
	health_fill.color = Color("#ff365f") if ratio > 0.34 else Color("#ff9d35")

func kill(by: String) -> void:
	if dying:
		return
	dying = true
	world.on_hazard_killed(self, by)
	queue_free()


func _rect_shape(size: Vector2, pos: Vector2) -> void:
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = size
	cs.shape = r
	cs.position = pos
	add_child(cs)


func _circle_shape(radius: float, pos: Vector2) -> void:
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	cs.shape = c
	cs.position = pos
	add_child(cs)


func _glow_eye(pos: Vector2, col: Color, size: Vector2 = Vector2(2, 2)) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), size, Vector2(0, size.y)])
	p.color = Color(col.r * 1.6, col.g * 1.6, col.b * 1.6)
	p.position = pos
	p.material = Fx.unshaded_mat()
	p.z_index = 1
	add_child(p)
	return p
