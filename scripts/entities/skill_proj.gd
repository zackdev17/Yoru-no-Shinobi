class_name SkillProj
extends Node2D

const GY := 216.0

var kind := "wave"
var world: World
var vel := Vector2.ZERO
var life := 1.0
var age := 0.0
var radius := 46.0
var hit := {}
var light: PointLight2D
var trail := PackedVector2Array()
var mega := false
var blast_mult := 1.0
var _tick := 0.0
var _impact_audio_played := false


func _ready() -> void:
	z_index = 8
	material = Fx.add_mat()
	light = PointLight2D.new()
	light.texture = TexGen.light_tex(1.4)
	light.range_item_cull_mask = 1
	light.shadow_enabled = false
	if kind == "wave":
		if vel == Vector2.ZERO:
			vel = Vector2(540.0, 0.0)
		light.color = Color(0.55, 1.0, 0.75)
		light.texture_scale = 1.6
		light.energy = 1.1
	elif kind == "fireball":
		light.color = Color(1.0, 0.6, 0.2)
		light.texture_scale = 2.4
		light.energy = 1.6
	elif kind == "flame":
		light.color = Color(1.0, 0.5, 0.15)
		light.texture_scale = 2.0
		light.energy = 1.2
	else:
		if vel == Vector2.ZERO:
			vel = Vector2(150.0, 560.0)
		light.color = Color(1.0, 0.6, 0.25)
		light.texture_scale = 1.8
		light.energy = 1.3
	add_child(light)


func _physics_process(delta: float) -> void:
	if world == null:
		queue_free()
		return
	age += delta
	if kind == "flame":
		_flame(delta)
		queue_redraw()
		return
	if kind == "fireball":
		vel.y += 240.0 * delta
	position += vel * delta
	trail.append(global_position)
	if trail.size() > 9:
		trail.remove_at(0)
	if kind == "wave":
		_wave()
	elif kind == "fireball":
		_fireball()
	else:
		_meteor()
	queue_redraw()


func _wave() -> void:
	for n in world.ent_root.get_children():
		if n is Hazard:
			var h := n as Hazard
			if h.dying or not h.shurikenable or hit.has(h.get_instance_id()):
				continue
			if absf(h.global_position.x - global_position.x) < 24.0 and absf(h.global_position.y - global_position.y) < 64.0:
				hit[h.get_instance_id()] = true
				if not _impact_audio_played:
					_impact_audio_played = true
					Sfx.play("skill_impact_gale", 1.0, -4.0)
				Fx.burst(world.fx_root, h.global_position + Vector2(0, -10), Color(0.6, 1.0, 0.8), 12, 150.0, 0.35, 60.0, "spark", true, 360.0, Vector2.UP, 2.0)
				Fx.ring(world.fx_root, h.global_position + Vector2(0, -10), Color(0.8, 1.0, 0.9, 0.9), 3.0, 24.0, 0.25, 2.0)
				h.take_damage(2, "wave")
	if age >= life or global_position.x > world.cam_x + 380.0:
		queue_free()


func _fireball() -> void:
	var boom := false
	for n in world.ent_root.get_children():
		if n is Hazard:
			var h := n as Hazard
			if h.dying or not h.shurikenable:
				continue
			if absf(h.global_position.x - global_position.x) < 20.0 and absf(h.global_position.y - 10.0 - global_position.y) < 34.0:
				boom = true
				break
	if boom or global_position.y >= GY - 6.0 or age >= life:
		_fire_explode()
		queue_free()


func _fire_explode() -> void:
	var c := Vector2(global_position.x, minf(global_position.y, GY - 6.0))
	var r := radius * blast_mult
	for n in world.ent_root.get_children():
		if n is Hazard:
			var h := n as Hazard
			if h.dying or not h.shurikenable:
				continue
			if h.global_position.distance_to(c + Vector2(0, 8)) <= r:
				Fx.burst(world.fx_root, h.global_position + Vector2(0, -10), Color(1.0, 0.6, 0.2), 12, 150.0, 0.4, 100.0, "spark", true, 360.0, Vector2.UP, 2.0)
				h.kill("fire")
	Fx.ring(world.fx_root, c, Color(1.0, 0.55, 0.15, 0.95), 6.0, r, 0.4, 4.0)
	Fx.ring(world.fx_root, c, Color(1.0, 0.95, 0.6, 0.9), 3.0, r * 0.6, 0.28, 2.5)
	Fx.burst(world.fx_root, c, Color(1.0, 0.55, 0.15), 34, 240.0, 0.6, 260.0, "spark", true, 360.0, Vector2.UP, 2.6)
	Fx.burst(world.fx_root, c, Color(1.0, 0.9, 0.5), 12, 150.0, 0.35, 0.0, "orb", true, 360.0, Vector2.UP, 2.2)
	Fx.smoke(world.fx_root, c + Vector2(0, -4), Color(0.4, 0.28, 0.25, 0.8))
	world.shake(4.0, 0.15)
	Sfx.play("skill_impact_fireball", 0.95, -2.5)
	var f := SkillProj.new()
	f.kind = "flame"
	f.world = world
	f.life = 1.8
	f.radius = maxf(30.0, r * 0.55)
	f.position = Vector2(c.x, GY)
	world.ent_root.add_child(f)


func _flame(delta: float) -> void:
	_tick -= delta
	if _tick <= 0.0:
		_tick = 0.15
		for n in world.ent_root.get_children():
			if n is Hazard:
				var h := n as Hazard
				if h.dying or not h.shurikenable:
					continue
				if absf(h.global_position.x - global_position.x) < radius and absf(h.global_position.y - GY) < 60.0:
					Fx.burst(world.fx_root, h.global_position + Vector2(0, -10), Color(1.0, 0.55, 0.2), 6, 90.0, 0.3, 80.0, "spark", true, 360.0, Vector2.UP, 1.8)
					h.take_damage(1, "fire")
	if age >= life:
		queue_free()


func _meteor() -> void:
	if global_position.y >= GY - 4.0:
		_impact()
		queue_free()
		return
	if age > 2.0:
		queue_free()


func _impact() -> void:
	var c := Vector2(global_position.x, GY - 4.0)
	if mega:
		Skills.inferno_mega(world, c.x)
		return
	var sc := scale.x
	for n in world.ent_root.get_children():
		if n is Hazard:
			var h := n as Hazard
			if h.dying or not h.shurikenable:
				continue
			if absf(h.global_position.x - c.x) <= radius * sc and absf(h.global_position.y - c.y) <= 80.0:
				Fx.burst(world.fx_root, h.global_position + Vector2(0, -10), Color(1.0, 0.6, 0.2), 12, 150.0, 0.4, 100.0, "spark", true, 360.0, Vector2.UP, 2.0)
				h.kill("meteor")
	Fx.ring(world.fx_root, c, Color(1.0, 0.55, 0.15, 0.95), 4.0, radius * 1.3 * sc, 0.35, 3.0)
	Fx.ring(world.fx_root, c, Color(1.0, 0.9, 0.5, 0.8), 2.0, radius * 0.8 * sc, 0.25, 2.0)
	Fx.burst(world.fx_root, c, Color(1.0, 0.55, 0.15), int(22.0 * sc), 190.0 * sc, 0.5, 340.0, "spark", true, 120.0, Vector2.UP, 2.2)
	Fx.burst(world.fx_root, c, Color(0.35, 0.28, 0.3, 0.9), 8, 110.0, 0.7, 360.0, "orb", false, 100.0, Vector2.UP, 1.8)
	var col := FxShape.new()
	col.kind = "slash"
	col.col = Color(1.0, 0.6, 0.2, 0.9)
	col.r0 = 8.0 * sc
	col.r1 = 70.0 * sc
	col.life = 0.35
	col.width = 6.0 * sc
	col.angle0 = -0.5
	col.angle1 = 0.5
	col.position = c
	col.rotation = -PI * 0.5
	world.fx_root.add_child(col)
	world.shake(2.2 * sc, 0.1 + 0.04 * sc)
	Sfx.play("meteor_impact_small", randf_range(0.94, 1.04), -4.0)


func _draw() -> void:
	if kind == "fireball":
		_draw_fireball()
		return
	if kind == "flame":
		_draw_flame()
		return
	if kind == "wave":
		var fade := clampf((life - age) / 0.25, 0.0, 1.0)
		var n := trail.size()
		for j in range(1, n):
			var f := float(j) / float(n)
			var a := to_local(trail[j - 1])
			var b := to_local(trail[j])
			draw_line(a, b, Color(0.5, 1.0, 0.75, f * 0.45 * fade), 1.0 + 8.0 * f)
		for i in 3:
			var off := -float(i) * 7.0
			var r := 30.0 - float(i) * 4.0
			var a2 := (0.85 - float(i) * 0.22) * fade
			draw_arc(Vector2(off - 12.0, 0.0), r, -1.05, 1.05, 18, Color(0.55, 1.0, 0.8, a2), 5.0 - float(i))
			draw_arc(Vector2(off - 12.0, 0.0), r, -0.95, 0.95, 18, Color(1, 1, 1, a2 * 0.9), 1.5)
		draw_circle(Vector2(8.0, 0.0), 6.0, Color(0.8, 1.0, 0.9, 0.5 * fade))
	else:
		var n2 := trail.size()
		for j in range(1, n2):
			var f2 := float(j) / float(n2)
			draw_line(to_local(trail[j - 1]), to_local(trail[j]), Color(1.0, 0.5, 0.15, f2 * 0.6), 2.0 + 7.0 * f2)
		draw_set_transform(Vector2.ZERO, (-vel).angle() + PI * 0.5, Vector2.ONE)
		UD.flame(self, Vector2.ZERO, 62.0, 20.0, age * 9.0, 0.95)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_circle(Vector2.ZERO, 10.0, Color(1.0, 0.45, 0.1, 0.25))
		draw_circle(Vector2.ZERO, 6.5, Color(1.0, 0.6, 0.15, 0.7))
		draw_circle(Vector2.ZERO, 3.8, Color(1.0, 0.9, 0.5, 0.95))
		draw_circle(Vector2.ZERO, 1.8, Color(1, 1, 1, 1))


func _draw_fireball() -> void:
	var n := trail.size()
	for j in range(1, n):
		var f := float(j) / float(n)
		draw_line(to_local(trail[j - 1]), to_local(trail[j]), Color(1.0, 0.45, 0.1, f * 0.55), 3.0 + 12.0 * f)
		draw_line(to_local(trail[j - 1]), to_local(trail[j]), Color(1.0, 0.85, 0.4, f * 0.7), 1.5 + 5.0 * f)
	var back := -vel.normalized()
	for i in 7:
		var off := Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0))
		var ln := 16.0 + randf() * 26.0
		draw_line(off, off + back * ln, Color(1.0, 0.5 + randf() * 0.4, 0.12, 0.7), 2.5)
	draw_circle(Vector2.ZERO, 17.0, Color(1.0, 0.4, 0.08, 0.18))
	draw_circle(Vector2.ZERO, 12.0, Color(1.0, 0.55, 0.12, 0.55))
	draw_circle(Vector2.ZERO, 8.0, Color(1.0, 0.8, 0.3, 0.9))
	draw_circle(Vector2.ZERO, 4.0, Color(1, 1, 0.9, 1.0))
	for k in 5:
		var a := age * 14.0 + float(k) * TAU / 5.0
		draw_circle(Vector2(cos(a), sin(a)) * 11.0, 1.8, Color(1.0, 0.9, 0.4, 0.9))


func _draw_flame() -> void:
	var fade := clampf((life - age) / 0.5, 0.0, 1.0) * clampf(age / 0.1, 0.0, 1.0)
	draw_circle(Vector2(0, -10), radius * 0.9, Color(1.0, 0.45, 0.1, 0.10 * fade))
	var n := 9
	for i in n:
		var u := float(i) / float(n - 1)
		var x := (u - 0.5) * 2.0 * radius * 0.85
		var h := (14.0 + 24.0 * absf(sin(age * 8.0 + float(i) * 1.9))) * (1.0 - absf(u - 0.5) * 0.7)
		var sway := sin(age * 11.0 + float(i)) * 3.5
		draw_line(Vector2(x, 2.0), Vector2(x + sway, 2.0 - h), Color(1.0, 0.4, 0.1, 0.6 * fade), 5.0)
		draw_line(Vector2(x, 2.0), Vector2(x + sway, 2.0 - h * 0.7), Color(1.0, 0.65, 0.2, 0.8 * fade), 3.0)
		draw_line(Vector2(x, 2.0), Vector2(x + sway, 2.0 - h * 0.4), Color(1.0, 0.95, 0.6, 0.9 * fade), 1.5)
