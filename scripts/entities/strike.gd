class_name Strike
extends Hazard

var t := 0.0
var warn_time := 1.0
var struck := false
var light: PointLight2D
var bolt_pts := PackedVector2Array()
var armed := false


func _build() -> void:
	top_offset = -230.0
	stompable = false
	shurikenable = false
	score_value = 0
	contact_enabled = false
	_rect_shape(Vector2(14, 240), Vector2(0, -120))
	light = PointLight2D.new()
	light.texture = TexGen.light_tex(1.2)
	light.texture_scale = 3.5
	light.color = Color(0.75, 0.8, 1.0)
	light.energy = 0.0
	light.position = Vector2(0, -20)
	light.range_item_cull_mask = 1
	light.shadow_enabled = false
	add_child(light)


func _update(delta: float) -> void:
	if not armed:
		if global_position.x - world.player.global_position.x < 340.0:
			armed = true
			Sfx.play("warn", 1.0, -10.0)
		else:
			return
	t += delta
	if not struck and t >= warn_time:
		struck = true
		contact_enabled = true
		var pts := PackedVector2Array()
		var y := -240.0
		var x := 0.0
		while y < 0.0:
			pts.append(Vector2(x, y))
			y += 12.0 + randf() * 10.0
			x += randf_range(-9.0, 9.0)
		pts.append(Vector2(0, 0))
		bolt_pts = pts
		world.big_flash(0.8)
		world.shake(5.0, 0.3)
		Sfx.play("zap", 0.8)
		Sfx.play("thunder", 1.2, -6.0)
		Fx.burst(world.fx_root, global_position, Color(0.8, 0.85, 1.0), 16, 120.0, 0.4, 300.0)
	if struck:
		light.energy = maxf(0.0, 3.0 - (t - warn_time) * 14.0)
		if t - warn_time > 0.22:
			queue_free()
	queue_redraw()


func _draw() -> void:
	if not struck:
		var blink := 0.5 + 0.5 * sin(t * 24.0)
		draw_arc(Vector2(0, 0), 12.0, PI, TAU, 14, Color(1.0, 0.3, 0.3, 0.4 + 0.5 * blink), 2.0)
		draw_line(Vector2(-12, 0), Vector2(12, 0), Color(1.0, 0.3, 0.3, 0.4 + 0.5 * blink), 1.0)
		draw_line(Vector2(0, -40), Vector2(0, 0), Color(1.0, 0.4, 0.4, 0.12 * blink), 1.0)
	else:
		var a := clampf(1.0 - (t - warn_time) * 4.0, 0.0, 1.0)
		if bolt_pts.size() > 1:
			draw_polyline(bolt_pts, Color(0.7, 0.8, 1.0, a), 6.0)
			draw_polyline(bolt_pts, Color(1, 1, 1, a), 2.0)
