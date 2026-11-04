class_name TouchControls
extends CanvasLayer

var buttons: Array = []
var world: World
var _enabled := false
var _ult_hidden := false


func _ready() -> void:
	layer = 20
	_add("slide", Vector2(120, 468), 58.0, "SLIDE", Color("#5a9aff"))
	_add("jump", Vector2(1170, 485), 76.0, "JUMP", Color("#ffd84a"))
	_add("throw", Vector2(1030, 500), 50.0, "SHURIKEN", Color("#7ad8ff"))
	_add("dash", Vector2(1042, 392), 46.0, "DASH", Color("#b48aff"), "dash")
	_add("shadow_attack", Vector2(1120, 300), 48.0, "SHADOW X", Color("#b66bff"), "special")
	_add("ultimate", Vector2(1210, 360), 42.0, "ULTI", Color("#ff4cba"), "ultimate")
	refresh()
	GameState.settings_changed.connect(refresh)


func _add(action: String, pos: Vector2, r: float, label: String, col: Color, slot: String = "") -> void:
	var b := TouchScreenButton.new()
	b.position = pos
	var cs := CircleShape2D.new()
	cs.radius = r
	b.shape = cs
	b.shape_visible = false
	b.action = action
	add_child(b)
	var v := TouchVisual.new()
	v.btn = b
	v.r = r
	v.label = label
	v.col = col
	v.slot = slot
	v.tc = self
	b.add_child(v)
	buttons.append(b)


func bind(w: World) -> void:
	world = w
	apply_character()


func apply_character() -> void:
	var sk: Dictionary = GameState.char_def()["skills"]
	for b in buttons:
		var v := (b as TouchScreenButton).get_child(0) as TouchVisual
		if v != null and v.slot != "":
			v.label = String(sk[v.slot]["touch"])
			v.queue_redraw()


func refresh() -> void:
	var mode := int(GameState.settings["touch"])
	var show := mode == 1 or (mode == 0 and DisplayServer.is_touchscreen_available())
	for b in buttons:
		(b as TouchScreenButton).visible = show and not _ult_hidden


func set_active(on: bool) -> void:
	_enabled = on
	if not on:
		for b in buttons:
			(b as TouchScreenButton).visible = false
	else:
		refresh()


func _process(_delta: float) -> void:
	if not _enabled or world == null or not is_instance_valid(world.player):
		return
	var pl := world.player
	var hide := pl.ultimate_active or (pl.ult_kind == "worldend" and pl.dead and not world.demo)
	if hide != _ult_hidden:
		_ult_hidden = hide
		refresh()


class TouchVisual extends Node2D:
	var btn: TouchScreenButton
	var tc: TouchControls
	var slot := ""
	var r := 50.0
	var label := ""
	var col := Color.WHITE
	var _pressed := false
	var _left := 0.0
	var _frac := 0.0
	var _act := 0.0

	func _process(_d: float) -> void:
		var redraw := false
		var p := btn.is_pressed()
		if p != _pressed:
			_pressed = p
			redraw = true
		if slot != "" and tc != null and tc.world != null and is_instance_valid(tc.world.player):
			var pl := tc.world.player
			var left := pl.cd_left(slot)
			if left < 0.15:
				left = 0.0
			var act := pl.ult_active_left() if slot == "ultimate" else 0.0
			if act < 0.05:
				act = 0.0
			var frac := left / maxf(0.1, pl.cd_total(slot))
			if absf(left - _left) > 0.04 or absf(act - _act) > 0.04 or absf(frac - _frac) > 0.004:
				_left = left
				_act = act
				_frac = frac
				redraw = true
		if redraw:
			queue_redraw()

	func _draw() -> void:
		var a := 0.55 if _pressed else 0.28
		draw_circle(Vector2.ZERO, r, Color(col.r, col.g, col.b, a * 0.6))
		draw_arc(Vector2.ZERO, r, 0, TAU, 40, Color(col.r, col.g, col.b, 0.85), 3.0)
		var f := ThemeDB.fallback_font
		var fs := 15 if r < 60.0 else 20
		var txt := label
		var tcol := Color(1, 1, 1, 0.95)
		if slot != "" and _act > 0.0:
			draw_arc(Vector2.ZERO, r - 4.0, 0, TAU, 40, Color(1, 1, 1, 0.9), 4.0)
			txt = "%.1f" % _act
			fs = 24
			tcol = Color("#ffe9a8")
		elif slot != "" and _left > 0.0:
			draw_circle(Vector2.ZERO, r, Color(0, 0, 0, 0.5))
			draw_arc(Vector2.ZERO, r - 4.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(1.0 - _frac, 0.0, 1.0), 40, Color(col.r, col.g, col.b, 1.0), 4.0)
			txt = "%.1f" % _left if _left < 10.0 else str(int(ceil(_left)))
			fs = 26 if r >= 45.0 else 22
		elif slot != "":
			draw_arc(Vector2.ZERO, r + 4.0, 0, TAU, 40, Color(col.r, col.g, col.b, 0.5), 2.0)
		var sz := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fs)
		draw_string(f, Vector2(-sz.x * 0.5, fs * 0.35), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tcol)
