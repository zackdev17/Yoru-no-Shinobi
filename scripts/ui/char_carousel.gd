class_name CharCarousel
extends Control

const CARD_W := 218.0
const GAP := 12.0
const STEP := CARD_W + GAP
const DRAG_PX := 10.0

var view_w := 1090.0
var scroll := 0.0
var prev_btn: Button
var next_btn: Button
var dots: Control

var _clip: Control
var _track: HBoxContainer
var _edge: Control
var _target := 0.0
var _pressed := false
var _dragging := false
var _press_x := 0.0
var _last_x := 0.0
var _last_ms := 0
var _vel := 0.0
var _block := 0.0
var _count := 0
var _marker := -1


func _init() -> void:
	custom_minimum_size = Vector2(view_w, 0.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_clip = Control.new()
	_clip.set_anchors_preset(Control.PRESET_FULL_RECT)
	_clip.clip_contents = true
	_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_clip)
	_track = HBoxContainer.new()
	_track.add_theme_constant_override("separation", int(GAP))
	_clip.add_child(_track)
	_edge = EdgeDraw.new()
	(_edge as EdgeDraw).car = self
	_edge.set_anchors_preset(Control.PRESET_FULL_RECT)
	_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_edge)
	prev_btn = UITheme.button("<", 64)
	next_btn = UITheme.button(">", 64)
	prev_btn.pressed.connect(func(): go(-1))
	next_btn.pressed.connect(func(): go(1))
	dots = DotsDraw.new()
	(dots as DotsDraw).car = self
	dots.custom_minimum_size = Vector2(140.0, 40.0)
	dots.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_cards(cards: Array) -> void:
	for ch in _track.get_children():
		_track.remove_child(ch)
		ch.queue_free()
	for c in cards:
		_track.add_child(c as Control)
	_count = cards.size()
	dots.custom_minimum_size = Vector2(maxf(60.0, float(_count) * 22.0), 40.0)
	var mx := _max_scroll()
	_target = clampf(_target, 0.0, mx)
	scroll = clampf(scroll, 0.0, mx)


func set_marker(i: int) -> void:
	_marker = i


func can_click() -> bool:
	return not _dragging and _block <= 0.0


func _max_scroll() -> float:
	return maxf(0.0, _track.get_combined_minimum_size().x - view_w)


func _snaps() -> PackedFloat32Array:
	var mx := _max_scroll()
	var out := PackedFloat32Array()
	for i in _count:
		var v := minf(float(i) * STEP, mx)
		if out.is_empty() or absf(v - out[out.size() - 1]) > 1.0:
			out.append(v)
	return out


func _nearest(x: float) -> int:
	var s := _snaps()
	var best := 0
	var bd := INF
	for i in s.size():
		var d := absf(s[i] - x)
		if d < bd:
			bd = d
			best = i
	return best


func _snap(x: float) -> float:
	var s := _snaps()
	if s.is_empty():
		return 0.0
	return s[_nearest(x)]


func go(dir: int) -> void:
	var s := _snaps()
	if s.is_empty():
		return
	var i := clampi(_nearest(_target) + dir, 0, s.size() - 1)
	_target = s[i]


func ensure_visible(i: int) -> void:
	if _pressed:
		return
	var l := float(i) * STEP
	if l - _target < -1.0 or l + CARD_W - _target > view_w + 1.0:
		_target = clampf(l - (view_w - CARD_W) * 0.5, 0.0, _max_scroll())


func jump_to(i: int) -> void:
	scroll = _snap(clampf(float(i) * STEP - (view_w - CARD_W) * 0.5, 0.0, _max_scroll()))
	_target = scroll
	_vel = 0.0


func card_visibility(i: int) -> float:
	var l := float(i) * STEP - scroll
	var vis := minf(l + CARD_W, view_w) - maxf(l, 0.0)
	return clampf(vis / CARD_W, 0.0, 1.0)


func _inside(e: InputEventMouse) -> bool:
	var l := _clip.make_input_local(e) as InputEventMouse
	return Rect2(Vector2.ZERO, _clip.size).has_point(l.position)


func _input(e: InputEvent) -> void:
	if not is_visible_in_tree():
		_pressed = false
		_dragging = false
		return
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if _inside(mb):
					_pressed = true
					_dragging = false
					_press_x = mb.position.x
					_last_x = mb.position.x
					_last_ms = Time.get_ticks_msec()
					_vel = 0.0
			elif _pressed:
				_pressed = false
				if _dragging:
					_dragging = false
					_block = 0.15
					_target = _snap(scroll - _vel * 0.22)
		elif mb.pressed and _inside(mb):
			match mb.button_index:
				MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_LEFT: go(-1)
				MOUSE_BUTTON_WHEEL_DOWN, MOUSE_BUTTON_WHEEL_RIGHT: go(1)
	elif e is InputEventMouseMotion and _pressed:
		var mm := e as InputEventMouseMotion
		if not _dragging and absf(mm.position.x - _press_x) > DRAG_PX:
			_dragging = true
			_last_x = mm.position.x
			_last_ms = Time.get_ticks_msec()
		if _dragging:
			var now := Time.get_ticks_msec()
			var dx := mm.position.x - _last_x
			var dt := maxf(0.001, float(now - _last_ms) / 1000.0)
			_last_x = mm.position.x
			_last_ms = now
			_vel = lerpf(_vel, -dx / dt, 0.4)
			var s := scroll - dx
			var mx := _max_scroll()
			if s < 0.0 or s > mx:
				s = scroll - dx * 0.35
			scroll = clampf(s, -70.0, mx + 70.0)


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_block = maxf(0.0, _block - delta)
	var mx := _max_scroll()
	if _dragging:
		_target = clampf(scroll, 0.0, mx)
	else:
		_target = clampf(_target, 0.0, mx)
		var d := _target - scroll
		if absf(d) < 0.4:
			scroll = _target
		else:
			scroll += d * (1.0 - exp(-14.0 * delta))
	var ms := _track.get_combined_minimum_size()
	if absf(custom_minimum_size.y - ms.y) > 0.5:
		custom_minimum_size.y = ms.y
	_track.size = Vector2(ms.x, maxf(ms.y, _clip.size.y))
	_track.position = Vector2(-roundf(scroll), 0.0)
	prev_btn.disabled = _target <= 0.5
	next_btn.disabled = _target >= mx - 0.5
	dots.queue_redraw()
	_edge.queue_redraw()


class EdgeDraw extends Control:
	var car: CharCarousel

	func _draw() -> void:
		if car == null or size.x < 100.0 or size.y < 2.0:
			return
		var mx := car._max_scroll()
		var h := size.y
		var w := 46.0
		var dark := Color(0.02, 0.03, 0.09, 0.9)
		var clear := Color(0.02, 0.03, 0.09, 0.0)
		var l := clampf(car.scroll / 40.0, 0.0, 1.0)
		var r := clampf((mx - car.scroll) / 40.0, 0.0, 1.0)
		if l > 0.01:
			draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
				PackedColorArray([Color(dark.r, dark.g, dark.b, dark.a * l), clear, clear, Color(dark.r, dark.g, dark.b, dark.a * l)]))
		if r > 0.01:
			draw_polygon(PackedVector2Array([Vector2(size.x - w, 0), Vector2(size.x, 0), Vector2(size.x, h), Vector2(size.x - w, h)]),
				PackedColorArray([clear, Color(dark.r, dark.g, dark.b, dark.a * r), Color(dark.r, dark.g, dark.b, dark.a * r), clear]))


class DotsDraw extends Control:
	var car: CharCarousel

	func _draw() -> void:
		if car == null or car._count <= 0:
			return
		var n := car._count
		var gap := 22.0
		var x0 := (size.x - gap * float(n - 1)) * 0.5
		var cy := size.y * 0.5
		for i in n:
			var v := car.card_visibility(i)
			var col := Color(0.55, 0.58, 0.85, 0.45).lerp(Color(1.0, 0.95, 0.75, 1.0), v)
			var r := 4.0 + 2.5 * v
			var c := Vector2(x0 + gap * float(i), cy)
			draw_circle(c, r, col)
			if i == car._marker:
				draw_arc(c, r + 3.5, 0.0, TAU, 20, UITheme.GOLD, 2.0)
