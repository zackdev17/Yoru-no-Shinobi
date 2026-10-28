class_name MaouPillar
extends Node2D

const GY := 216.0
const WARN := 0.26
const LIFE := 0.7
const KILL_HALF := 40.0
const TOP := -620.0

var world: World
var delay := 0.0
var flip := false
var loud := false
var age := 0.0
var struck := false
var dark: Node2D


func _ready() -> void:
	z_index = 11
	material = Fx.add_mat()
	dark = Node2D.new()
	dark.material = Fx.unshaded_mat()
	dark.z_index = -1
	dark.show_behind_parent = true
	dark.draw.connect(_draw_dark)
	add_child(dark)


func _process(delta: float) -> void:
	age += delta
	var a := age - delay
	if a < 0.0:
		return
	if not struck and a >= WARN:
		_strike()
	if a >= WARN + LIFE:
		queue_free()
		return
	queue_redraw()
	dark.queue_redraw()


func _strike() -> void:
	struck = true
	if world == null:
		return
	Skills._sweep(world, Vector2(global_position.x, GY - 90.0), KILL_HALF, 320.0, "eclipse")
	Fx.ring(world.fx_root, Vector2(global_position.x, GY - 3.0), Color(1.0, 0.85, 0.36, 0.95), 4.0, 64.0, 0.4, 4.0)
	Fx.ring(world.fx_root, Vector2(global_position.x, GY - 3.0), Color(0.6, 0.28, 1.0, 0.9), 3.0, 46.0, 0.35, 3.0)
	Fx.burst(world.fx_root, Vector2(global_position.x, GY - 3.0), Color(1.0, 0.85, 0.36), 16, 200.0, 0.6, 220.0, "spark", true, 40.0, Vector2.UP, 2.6)
	Fx.burst(world.fx_root, Vector2(global_position.x, GY - 3.0), Color(0.65, 0.35, 1.0), 16, 200.0, 0.6, 220.0, "spark", true, 40.0, Vector2.UP, 2.6)
	world.shake(5.0, 0.18)
	if loud:
		Sfx.play("skill_impact_judgement", randf_range(0.9, 1.1), -4.0)


func _width_k() -> float:
	var a := age - delay - WARN
	if a < 0.0:
		return 0.0
	var pop := smoothstep(0.0, 0.07, a)
	var fade := 1.0 - smoothstep(0.15, LIFE, a)
	return pop * (0.35 + 0.65 * fade)


func _draw() -> void:
	var a := age - delay
	if a < 0.0:
		return
	var base := Vector2(0.0, GY - position.y)
	if a < WARN:
		var k := a / WARN
		var pulse := 0.5 + 0.5 * sin(a * 40.0)
		UD.ellipse(self, base + Vector2(0, -2), 26.0 * (1.3 - 0.3 * k), 0.24, Color(1.0, 0.85, 0.36, 0.8 * k), 1.6)
		UD.ellipse(self, base + Vector2(0, -2), 17.0, 0.24, Color(0.65, 0.35, 1.0, 0.8 * k), 1.2)
		draw_line(Vector2(0, TOP), base, Color(0.8, 0.6, 1.0, 0.10 + 0.25 * k * pulse), 1.0)
		UD.glow(self, base + Vector2(0, -3), 30.0, Color(0.7, 0.4, 1.0, 1.0), 0.35 * k)
		return
	var wk := _width_k()
	var hw := 26.0 * wk
	if hw <= 0.4:
		return
	var tt := age * 9.0
	draw_rect(Rect2(-hw * 1.9, TOP, hw * 3.8, -TOP + base.y), Color(0.62, 0.32, 1.0, 0.16))
	draw_rect(Rect2(-hw * 1.15, TOP, hw * 2.3, -TOP + base.y), Color(1.0, 0.82, 0.3, 0.42))
	draw_rect(Rect2(-hw * 0.45, TOP, hw * 0.9, -TOP + base.y), Color(1.0, 0.97, 0.8, 0.9))
	var pts := PackedVector2Array()
	var sgn := -1.0 if flip else 1.0
	for i in 30:
		var y := base.y - float(i) * 12.0
		pts.append(Vector2(sin(y * 0.05 + tt * sgn) * hw * 1.05, y))
	draw_polyline(pts, Color(1.0, 0.95, 0.7, 0.8), 2.0)
	UD.glow(self, base + Vector2(0, -4), 52.0 * wk + 10.0, Color(1.0, 0.85, 0.4, 1.0), 0.6 * wk)
	UD.glow(self, base + Vector2(0, -4), 34.0 * wk + 6.0, Color(0.7, 0.4, 1.0, 1.0), 0.5 * wk)
	UD.ellipse(self, base + Vector2(0, -2), 40.0 * wk, 0.24, Color(1.0, 0.9, 0.5, 0.8 * wk), 2.0)


func _draw_dark() -> void:
	var a := age - delay - WARN
	if a < 0.0:
		return
	var wk := _width_k()
	var hw := 26.0 * wk
	if hw <= 0.4:
		return
	var base := Vector2(0.0, GY - position.y)
	var tt := age * 9.0
	var sgn := 1.0 if flip else -1.0
	for strand in 2:
		var ph := float(strand) * PI
		var left := PackedVector2Array()
		var right := PackedVector2Array()
		for i in 28:
			var y := base.y - float(i) * 13.0
			var cx := sin(y * 0.05 + tt * sgn + ph) * hw * 1.25
			var wd := hw * 0.34 * (0.6 + 0.4 * sin(y * 0.11 + tt))
			left.append(Vector2(cx - wd, y))
			right.append(Vector2(cx + wd, y))
		right.reverse()
		left.append_array(right)
		UD.poly(dark, left, Color(0.05, 0.0, 0.11, 0.9), "mpillar")
