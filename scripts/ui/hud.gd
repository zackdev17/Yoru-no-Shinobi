class_name HUD
extends Control

signal pause_pressed

var world: World
var f: Font
var pause_btn: Button
var banner: Label
var banner_sub: Label
var hint: Label
var _hint_t := 0.0
var show_hud := false
var _combo_scale := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	f = ThemeDB.fallback_font
	pause_btn = Button.new()
	pause_btn.text = "II"
	pause_btn.custom_minimum_size = Vector2(52, 48)
	pause_btn.position = Vector2(1280 - 68, 12)
	pause_btn.focus_mode = Control.FOCUS_NONE
	pause_btn.pressed.connect(func(): pause_pressed.emit())
	add_child(pause_btn)

	banner = UITheme.label("", 54, Color("#ffe9a8"), 1)
	banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	banner.position = Vector2(0, 150)
	banner.size = Vector2(1280, 70)
	banner.modulate.a = 0.0
	banner.add_theme_constant_override("outline_size", 8)
	add_child(banner)
	banner_sub = UITheme.label("", 24, Color("#cfd8ff"), 1)
	banner_sub.position = Vector2(0, 118)
	banner_sub.size = Vector2(1280, 30)
	banner_sub.modulate.a = 0.0
	add_child(banner_sub)

	hint = UITheme.label("", 22, Color("#ffffff"), 1)
	hint.position = Vector2(0, 420)
	hint.size = Vector2(1280, 40)
	hint.modulate.a = 0.0
	add_child(hint)


func bind(w: World) -> void:
	world = w
	w.popup.connect(_on_popup)
	w.stage_changed.connect(_on_stage)
	w.pickup.connect(func(_k): pass)


func set_visible_hud(on: bool) -> void:
	show_hud = on
	pause_btn.visible = on
	queue_redraw()


func show_hint(text: String, secs: float = 7.0) -> void:
	hint.text = text
	_hint_t = secs
	hint.modulate.a = 1.0


func _on_stage(idx: int, title: String) -> void:
	banner_sub.text = "STAGE %d" % (idx + 1)
	banner.text = title
	var tw := create_tween()
	tw.tween_property(banner, "modulate:a", 1.0, 0.4).set_delay(0.5 if idx > 0 else 0.1)
	tw.parallel().tween_property(banner_sub, "modulate:a", 1.0, 0.4).set_delay(0.5 if idx > 0 else 0.1)
	tw.tween_interval(1.8)
	tw.tween_property(banner, "modulate:a", 0.0, 0.7)
	tw.parallel().tween_property(banner_sub, "modulate:a", 0.0, 0.7)


func _on_popup(wp: Vector2, text: String, col: Color) -> void:
	if world == null:
		return
	var cp := world.cam.position
	var sp := (wp - cp + Vector2(320, 144)) * 2.0
	var l := UITheme.label(text, 24, col, 1)
	l.size = Vector2(240, 34)
	l.position = sp - Vector2(120, 20)
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position:y", l.position.y - 46.0, 0.9)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.35)
	tw.tween_callback(l.queue_free)


func _process(delta: float) -> void:
	if _hint_t > 0.0:
		_hint_t -= delta
		if _hint_t < 1.0:
			hint.modulate.a = maxf(0.0, _hint_t)
	if show_hud:
		queue_redraw()


func _pill(rect: Rect2) -> void:
	var sb := UITheme.box(Color(0.05, 0.06, 0.16, 0.78), Color(0.55, 0.5, 0.8, 0.8), 2, 17, 0)
	sb.shadow_size = 3
	draw_style_box(sb, rect)


func _heart(c: Vector2, s: float, col: Color) -> void:
	draw_circle(c + Vector2(-s * 0.5, -s * 0.35), s * 0.55, col)
	draw_circle(c + Vector2(s * 0.5, -s * 0.35), s * 0.55, col)
	SafeDraw.poly(self, PackedVector2Array([c + Vector2(-s * 1.02, -s * 0.15), c + Vector2(s * 1.02, -s * 0.15), c + Vector2(0, s * 1.05)]), col)


func _draw() -> void:
	if not show_hud or world == null:
		return
	var p := world.player
	_pill(Rect2(16, 12, 118, 38))
	draw_circle(Vector2(38, 31), 10.0, Color("#ffd23a"))
	draw_circle(Vector2(38, 31), 6.0, Color("#ffec8a"))
	draw_rect(Rect2(36, 29, 4, 4), Color("#8a5412"))
	draw_string(f, Vector2(58, 40), str(world.coins_run), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color.WHITE)
	_pill(Rect2(144, 12, 112, 38))
	draw_string(f, Vector2(160, 40), "%d m" % int(world.dist_m), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("#d8e4ff"))
	for i in p.max_hearts:
		var full := i < p.hearts
		_heart(Vector2(30 + i * 30, 72), 9.0, Color("#ff5a8c") if full else Color(0.25, 0.15, 0.3, 0.8))
	draw_string(f, Vector2(16, 108), "SCORE %d" % world.compute_score(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.7))
	if world.combo >= 3:
		draw_string(f, Vector2(16, 130), "COMBO x%d" % world.combo, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#ffd84a"))
	var bx := 1280.0 - 44.0
	var by := 84.0
	if p.shield:
		_buff(Vector2(bx, by), Color("#4ad0ff"), 1.0, "shield")
		by += 48.0
	if p.magnet_t > 0.0:
		_buff(Vector2(bx, by), Color("#ff5a5a"), p.magnet_t / GameState.magnet_time(), "magnet")
		by += 48.0
	if p.star_t > 0.0:
		_buff(Vector2(bx, by), Color("#ffd84a"), p.star_t / 7.0, "star")
		by += 48.0
	var ax := 20.0
	var max_ammo := GameState.max_ammo()
	for i in max_ammo:
		var c := Color("#c8d4ee") if i < p.ammo else Color(0.3, 0.32, 0.45, 0.6)
		_mini_star(Vector2(ax + 8 + i * 22, 524), 8.0, c)
	if p.ammo < max_ammo:
		var left := maxf(0.0, Characters.SHURIKEN_RECHARGE - p.ammo_timer)
		draw_string(f, Vector2(ax + 8 + max_ammo * 22, 530), "+1 in %.1fs" % left, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.8, 0.85, 1.0, 0.8))
	if not _touch_visible():
		_skill_icon(Vector2(42, 476), p, "dash", "K", Color("#b48aff"))
		_skill_icon(Vector2(106, 476), p, "special", "L", Color("#7ad8ff"))
		_skill_icon(Vector2(170, 476), p, "ultimate", "U", Color("#ff4cba"))
	var prog := fposmod(p.global_position.x / Themes.STAGE_PX, 1.0)
	var bw := 520.0
	var bx0 := 640.0 - bw * 0.5
	var horde := world.horde_zone()
	var hp_t := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * 8.0)
	var bar_col := Color("#ff7ab0").lerp(Color("#ff2a2a"), 0.55 + 0.45 * hp_t) if horde else Color("#ff7ab0")
	var edge_col := Color(1.0, 0.35, 0.3, 0.9) if horde else Color(0.5, 0.45, 0.75, 0.9)
	draw_style_box(UITheme.box(Color(0.05, 0.05, 0.14, 0.85), edge_col, 2, 9, 0), Rect2(bx0, 538, bw, 18))
	draw_style_box(UITheme.box(bar_col, Color(0, 0, 0, 0), 0, 7, 0), Rect2(bx0 + 3, 541, maxf(10.0, (bw - 6.0) * prog), 12))
	var mx := bx0 + 3 + (bw - 6.0) * prog
	_ninja_head(Vector2(mx, 547))
	var nm := String(Themes.at(world.stage)["name"])
	var nm_col := Color(1, 1, 1, 0.65)
	if horde:
		nm = "! HORDE !"
		nm_col = Color(1.0, 0.35 + 0.2 * hp_t, 0.3, 0.95)
	var sz := f.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	draw_string(f, Vector2(640.0 - sz.x * 0.5, 534), nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, nm_col)


func _skill_icon(c: Vector2, p: Ninja, slot: String, key: String, col: Color) -> void:
	var left := p.cd_left(slot)
	var total := maxf(0.1, p.cd_total(slot))
	var active_left := p.ult_active_left() if slot == "ultimate" else 0.0
	var is_active := active_left > 0.0
	var is_ready := left <= 0.0 and not is_active
	var t := Time.get_ticks_msec() / 1000.0
	draw_circle(c, 23.0, Color(0.06, 0.06, 0.18, 0.85))
	var txt := key
	var tcol := Color.WHITE
	if is_active:
		draw_arc(c, 22.0, 0.0, TAU, 32, Color(1, 1, 1, 0.9), 4.0)
		txt = "%.1f" % active_left
		tcol = Color("#ffe9a8")
	elif is_ready:
		draw_circle(c, 27.0, Color(col.r, col.g, col.b, 0.10 + 0.08 * sin(t * 6.0)))
		draw_arc(c, 22.0, 0.0, TAU, 32, col, 4.0)
	else:
		var frac := clampf(1.0 - left / total, 0.0, 1.0)
		draw_arc(c, 22.0, -PI * 0.5, -PI * 0.5 + TAU * frac, 32, col.darkened(0.3), 4.0)
		txt = "%.1f" % left if left < 10.0 else str(int(ceil(left)))
		tcol = Color(1, 1, 1, 0.92)
	var fs := 18 if txt.length() <= 3 else 15
	var sz := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
	draw_string(f, c + Vector2(-sz.x * 0.5, fs * 0.35), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, tcol)
	if not is_ready:
		draw_string(f, c + Vector2(-27, -18), key, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(col.r, col.g, col.b, 0.9))


func _touch_visible() -> bool:
	var mode := int(GameState.settings["touch"])
	return mode == 1 or (mode == 0 and DisplayServer.is_touchscreen_available())


func _buff(c: Vector2, col: Color, frac: float, kind: String) -> void:
	draw_circle(c, 20.0, Color(0.05, 0.06, 0.16, 0.85))
	draw_arc(c, 20.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(frac, 0.0, 1.0), 28, col, 3.0)
	match kind:
		"shield":
			SafeDraw.poly(self, PackedVector2Array([c + Vector2(-8, -8), c + Vector2(8, -8), c + Vector2(8, 2), c + Vector2(0, 10), c + Vector2(-8, 2)]), col)
		"magnet":
			draw_arc(c + Vector2(0, -1), 8.0, PI, TAU, 10, col, 4.0)
			draw_rect(Rect2(c.x - 10, c.y - 1, 4, 10), col)
			draw_rect(Rect2(c.x + 6, c.y - 1, 4, 10), col)
		"star":
			var pts := PackedVector2Array()
			for i in 10:
				var r := 11.0 if i % 2 == 0 else 5.0
				var a := -PI * 0.5 + i * PI / 5.0
				pts.append(c + Vector2(cos(a), sin(a)) * r)
			SafeDraw.poly(self, pts, col)


func _mini_star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 8:
		var rr := r if i % 2 == 0 else r * 0.35
		var a := i * PI / 4.0
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	SafeDraw.poly(self, pts, col)


func _ninja_head(c: Vector2) -> void:
	draw_circle(c, 11.0, Color("#1f2547"))
	draw_arc(c, 11.0, 0, TAU, 20, Color("#e8b84a"), 2.0)
	draw_rect(Rect2(c.x - 7, c.y - 5, 14, 4), Color("#d8323e"))
	draw_rect(Rect2(c.x - 1, c.y - 1, 7, 4), Color("#e2b48e"))
	draw_rect(Rect2(c.x + 1, c.y, 2, 2), Color.WHITE)
