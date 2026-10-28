extends Node

var container: SubViewportContainer
var vp: SubViewport
var world: World
var post: ShaderMaterial
var ui_layer: CanvasLayer
var ui: Control
var hud: HUD
var touch: TouchControls
var state := "menu"

var menu_root: Control
var pause_root: Control
var over_root: Control
var up_root: Control
var set_root: Control
var chars_root: Control
var chars_car: CharCarousel
var chars_upg: Button
var chars_coins: Label
var up_title: Label
var _chars_from := "menu"
var up_rows: VBoxContainer
var up_coins: Label
var menu_info: Label
var over_labels: Dictionary = {}
var logo: Control
var _t := 0.0
var _low_hp_t := 0.0
var _from_state := "menu"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	container = SubViewportContainer.new()
	container.stretch = true
	container.stretch_shrink = 2
	container.position = Vector2.ZERO
	container.size = Vector2(1280, 576)
	container.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := load("res://shaders/post.gdshader") as Shader
	post = ShaderMaterial.new()
	post.shader = sh
	container.material = post
	add_child(container)
	vp = SubViewport.new()
	vp.size = Vector2i(640, 288)
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.handle_input_locally = false
	container.add_child(vp)
	world = World.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	vp.add_child(world)

	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.theme = UITheme.get_theme()
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(ui)
	hud = HUD.new()
	ui.add_child(hud)
	hud.bind(world)
	hud.pause_pressed.connect(_pause)
	hud.set_visible_hud(false)
	touch = TouchControls.new()
	add_child(touch)
	touch.set_active(false)
	touch.bind(world)

	_build_menu()
	_build_pause()
	_build_over()
	_build_upgrades()
	_build_chars()
	_build_settings()

	world.run_ended.connect(_on_run_ended)
	GameState.coins_changed.connect(_refresh_info)
	GameState.character_changed.connect(_on_char_changed)
	await get_tree().process_frame
	world.start(true)
	Sfx.start_music()
	Sfx.set_intensity(0.3)
	_show("menu")


func _show(s: String) -> void:
	state = s
	if s in ["menu", "upgrades", "settings", "characters"]: Sfx.set_music_mode("menu")
	elif s in ["playing", "paused", "over"]: Sfx.set_music_mode("gameplay")
	menu_root.visible = s == "menu"
	pause_root.visible = s == "paused"
	over_root.visible = s == "over"
	up_root.visible = s == "upgrades"
	set_root.visible = s == "settings"
	chars_root.visible = s == "characters"
	hud.set_visible_hud(s == "playing" or s == "paused")
	touch.set_active(s == "playing")
	_refresh_info()
	match s:
		"menu": _focus(menu_root)
		"paused": _focus(pause_root)
		"over": _focus(over_root)
		"upgrades":
			_rebuild_upgrades()
			_focus(up_root)
		"settings": _focus(set_root)
		"characters":
			_rebuild_chars()
			chars_car.jump_to(maxi(0, Characters.ID_ORDER.find(GameState.selected)))
			_focus_chars()


func _focus_chars() -> void:
	await get_tree().process_frame
	if chars_upg != null and chars_upg.is_visible_in_tree():
		chars_upg.grab_focus()


func _focus(root: Control) -> void:
	await get_tree().process_frame
	for b in root.find_children("*", "Button", true, false):
		if (b as Button).is_visible_in_tree() and not (b as Button).disabled:
			(b as Button).grab_focus()
			return


func _start_game() -> void:
	get_tree().paused = false
	Sfx.set_muffled(false)
	touch.apply_character()
	world.start(false)
	_show("playing")
	if not GameState.seen_tutorial:
		GameState.seen_tutorial = true
		GameState.save_game()
		var t := "SPACE / W: JUMP (x2)    S: SLIDE    J: SHURIKEN    K: DASH    L/C/E: SPECIAL    U: ULTIMATE"
		if DisplayServer.is_touchscreen_available():
			t = "TAP THE BUTTONS: JUMP (x2)  SLIDE  SHURIKEN  DASH  SPECIAL  ULTI"
		hud.show_hint(t, 9.0)


func _to_menu() -> void:
	get_tree().paused = false
	Sfx.set_muffled(false)
	world.start(true)
	Sfx.set_intensity(0.3)
	_show("menu")


func _pause() -> void:
	if state != "playing":
		return
	get_tree().paused = true
	Sfx.set_muffled(true)
	Sfx.set_ult_audio_paused(true)
	_show("paused")


func _resume() -> void:
	get_tree().paused = false
	Sfx.set_muffled(false)
	Sfx.set_ult_audio_paused(false)
	_show("playing")


func _on_run_ended(st: Dictionary) -> void:
	await get_tree().create_timer(1.1, true, false, true).timeout
	if state != "playing":
		return
	over_labels["dist"].text = "%d m" % st["dist"]
	over_labels["coins"].text = "%d  (+%d)" % [st["coins"], st["money"]]
	over_labels["kills"].text = str(st["kills"])
	over_labels["combo"].text = "x%d" % st["combo"]
	over_labels["score"].text = str(st["score"])
	over_labels["best"].text = "NEW BEST!" if st["new_best"] else "BEST  %d" % GameState.best_score
	over_labels["best"].add_theme_color_override("font_color", Color("#ffd84a") if st["new_best"] else Color(0.8, 0.85, 1.0, 0.8))
	_show("over")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and state == "playing":
		_pause()


func _unhandled_input(e: InputEvent) -> void:
	if e.is_action_pressed("pause_game"):
		if state == "playing":
			_pause()
		elif state == "paused":
			_resume()
		elif state in ["upgrades", "settings"]:
			_show(_from_state)
		elif state == "characters":
			_show(_chars_from)


func _process(delta: float) -> void:
	_t += delta
	var th := Themes.at(world.applied_stage if world.applied_stage >= 0 else 0)
	var g: Color = th["grade"]
	post.set_shader_parameter("grade", g)
	post.set_shader_parameter("flash", world.fx_flash)
	post.set_shader_parameter("damage", world.fx_damage)
	post.set_shader_parameter("aberration", world.fx_ab)
	post.set_shader_parameter("dash", world.fx_dash)
	post.set_shader_parameter("fade", world.fx_fade)
	post.set_shader_parameter("cine", world.fx_cine)
	post.set_shader_parameter("rays", world.fx_rays)
	post.set_shader_parameter("cine_tint", Vector3(world.fx_tint.r, world.fx_tint.g, world.fx_tint.b))
	post.set_shader_parameter("rays_col", Vector3(world.fx_raycol.r, world.fx_raycol.g, world.fx_raycol.b))
	post.set_shader_parameter("fade_color", (th["fog"] as Color).lerp(Color(0.9, 0.92, 1.0), 0.6))
	var vig := 0.5
	if state == "playing" and world.player.hearts == 1 and not world.player.dead:
		_low_hp_t += delta
		vig = 0.6 + 0.15 * sin(_low_hp_t * 6.0)
		post.set_shader_parameter("damage", maxf(world.fx_damage, 0.18 + 0.12 * sin(_low_hp_t * 6.0)))
	if state in ["menu", "upgrades", "settings", "characters"]:
		vig = 0.65
	post.set_shader_parameter("vignette", vig * float(th.get("vig", 1.0)))
	if logo:
		logo.queue_redraw()


func _center(panel: Control) -> Control:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	cc.add_child(panel)
	ui.add_child(root)
	root.visible = false
	return root


func _build_menu() -> void:
	menu_root = Control.new()
	menu_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(menu_root)
	logo = LogoDraw.new()
	logo.set_anchors_preset(Control.PRESET_FULL_RECT)
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_root.add_child(logo)

	var vb := VBoxContainer.new()
	vb.position = Vector2(90, 262)
	vb.add_theme_constant_override("separation", 8)
	menu_root.add_child(vb)
	var play := UITheme.button("PLAY", 300)
	play.pressed.connect(_start_game)
	vb.add_child(play)
	var chb := UITheme.button("CHARACTERS", 300)
	chb.pressed.connect(func():
		_chars_from = "menu"
		_show("characters"))
	vb.add_child(chb)
	var upg := UITheme.button("UPGRADES", 300)
	upg.pressed.connect(func():
		_from_state = "menu"
		_show("upgrades"))
	vb.add_child(upg)
	var st := UITheme.button("SETTINGS", 300)
	st.pressed.connect(func():
		_from_state = "menu"
		_show("settings"))
	vb.add_child(st)
	if not OS.has_feature("web") and not OS.has_feature("mobile"):
		var q := UITheme.button("QUIT", 300)
		q.pressed.connect(func(): get_tree().quit())
		vb.add_child(q)
	menu_info = UITheme.label("", 20, Color(0.85, 0.9, 1.0, 0.85))
	menu_info.position = Vector2(94, 542)
	menu_root.add_child(menu_info)


func _refresh_info() -> void:
	if menu_info:
		menu_info.text = "BEST  %d m   |   TOP SCORE  %d   |   COINS  %d" % [GameState.best_m, GameState.best_score, GameState.coins]
	if up_coins:
		up_coins.text = "COINS  %d" % GameState.coins
	if chars_coins:
		chars_coins.text = "COINS  %d" % GameState.coins


func _build_pause() -> void:
	var pc := PanelContainer.new()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	pc.add_child(vb)
	vb.add_child(UITheme.label("PAUSED", 44, Color("#ffe9a8"), 1))
	var r := UITheme.button("RESUME")
	r.pressed.connect(_resume)
	vb.add_child(r)
	var rs := UITheme.button("RESTART")
	rs.pressed.connect(_start_game)
	vb.add_child(rs)
	var s := UITheme.button("SETTINGS")
	s.pressed.connect(func():
		_from_state = "paused"
		_show("settings"))
	vb.add_child(s)
	var m := UITheme.button("MAIN MENU")
	m.pressed.connect(_to_menu)
	vb.add_child(m)
	pause_root = _center(pc)


func _build_over() -> void:
	var pc := PanelContainer.new()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	pc.add_child(vb)
	vb.add_child(UITheme.label("YOU HAVE FALLEN", 38, Color("#ff7a8a"), 1))
	over_labels["best"] = UITheme.label("", 26, Color("#ffd84a"), 1)
	vb.add_child(over_labels["best"])
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 60)
	grid.add_theme_constant_override("v_separation", 6)
	vb.add_child(grid)
	for row in [["DISTANCE", "dist"], ["COINS", "coins"], ["ENEMIES", "kills"], ["BEST COMBO", "combo"], ["SCORE", "score"]]:
		grid.add_child(UITheme.label(row[0], 24, Color(0.8, 0.85, 1.0)))
		var v := UITheme.label("0", 26, Color.WHITE, 2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		over_labels[row[1]] = v
		grid.add_child(v)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	var retry := UITheme.button("RETRY", 190)
	retry.pressed.connect(_start_game)
	hb.add_child(retry)
	var up := UITheme.button("UPGRADES", 190)
	up.pressed.connect(func():
		_from_state = "over"
		_show("upgrades"))
	hb.add_child(up)
	var chs := UITheme.button("NINJAS", 150)
	chs.pressed.connect(func():
		_chars_from = "over"
		_show("characters"))
	hb.add_child(chs)
	var mn := UITheme.button("MENU", 150)
	mn.pressed.connect(_to_menu)
	hb.add_child(mn)
	over_root = _center(pc)


func _build_upgrades() -> void:
	var pc := PanelContainer.new()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	pc.add_child(vb)
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 14)
	var prev := UITheme.button("<", 60)
	prev.pressed.connect(func(): _cycle_char(-1))
	head.add_child(prev)
	up_title = UITheme.label("", 34, Color("#ffe9a8"), 1)
	up_title.custom_minimum_size = Vector2(520, 0)
	head.add_child(up_title)
	var nxt := UITheme.button(">", 60)
	nxt.pressed.connect(func(): _cycle_char(1))
	head.add_child(nxt)
	vb.add_child(head)
	up_coins = UITheme.label("", 26, Color("#ffd23a"), 1)
	vb.add_child(up_coins)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(800, 340)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)
	up_rows = VBoxContainer.new()
	up_rows.add_theme_constant_override("separation", 2)
	scroll.add_child(up_rows)
	var back := UITheme.button("BACK", 200)
	back.pressed.connect(func(): _show(_from_state))
	var c := CenterContainer.new()
	c.add_child(back)
	vb.add_child(c)
	up_root = _center(pc)


func _cycle_char(dir: int) -> void:
	var list: Array = []
	for id in Characters.ID_ORDER:
		if GameState.owns(id):
			list.append(id)
	if list.size() <= 1:
		return
	var i := list.find(GameState.selected)
	i = (i + dir + list.size()) % list.size()
	GameState.select_char(list[i])
	_rebuild_upgrades()


func _on_char_changed() -> void:
	touch.apply_character()
	if world.player != null and world.player.char_id != GameState.selected:
		world.player.set_character(GameState.selected)


func _rebuild_upgrades() -> void:
	for ch in up_rows.get_children():
		ch.queue_free()
	var cd := GameState.char_def()
	up_title.text = "%s UPGRADES" % String(cd["name"])
	for id in GameState.UPGRADE_ORDER:
		var info: Dictionary = GameState.upgrade_info(id)
		var lvl := GameState.upgrade_level(id)
		var mx := int(info["max"])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var names := VBoxContainer.new()
		names.custom_minimum_size = Vector2(430, 0)
		names.add_child(UITheme.label(String(info["name"]), 20, Color("#f4ecd8")))
		var desc := String(info["desc"])
		match id:
			"dash": desc += "   (now %.1fs)" % GameState.dash_cooldown()
			"special": desc += "   (now %.1fs)" % GameState.special_cooldown()
			"ulti": desc += "   (now %.1fs)" % GameState.ulti_cooldown()
		names.add_child(UITheme.label(desc, 16, Color(0.75, 0.8, 1.0, 0.85)))
		row.add_child(names)
		var pips := ""
		for i in mx:
			pips += "■" if i < lvl else "□"
		var pl := UITheme.label(pips, 22, Color("#ff7ab0"))
		pl.custom_minimum_size = Vector2(130, 0)
		row.add_child(pl)
		var b := UITheme.button("MAX" if lvl >= mx else "BUY  %d" % GameState.upgrade_cost(id), 170)
		b.custom_minimum_size = Vector2(170, 40)
		b.disabled = not GameState.can_buy(id)
		b.pressed.connect(func():
			if GameState.buy(id):
				Sfx.play("powerup")
				_rebuild_upgrades())
		row.add_child(b)
		up_rows.add_child(row)
	_refresh_info()


func _build_chars() -> void:
	var pc := PanelContainer.new()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	pc.add_child(vb)
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override("separation", 40)
	head.add_child(UITheme.label("CHOOSE YOUR NINJA", 32, Color("#ffe9a8"), 1))
	chars_coins = UITheme.label("", 24, Color("#ffd23a"), 1)
	head.add_child(chars_coins)
	vb.add_child(head)
	chars_car = CharCarousel.new()
	vb.add_child(chars_car)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 14)
	hb.add_child(chars_car.prev_btn)
	var upg := UITheme.button("UPGRADES", 220)
	upg.pressed.connect(func():
		_from_state = "characters"
		_show("upgrades"))
	chars_upg = upg
	hb.add_child(upg)
	hb.add_child(chars_car.dots)
	var back := UITheme.button("BACK", 200)
	back.pressed.connect(func(): _show(_chars_from))
	hb.add_child(back)
	hb.add_child(chars_car.next_btn)
	vb.add_child(hb)
	chars_root = _center(pc)


func _fmt_cd(v: float) -> String:
	return "%.1fs" % v if v < 10.0 else "%ds" % int(round(v))


func _rebuild_chars() -> void:
	var cards: Array = []
	for id in Characters.ID_ORDER:
		cards.append(_char_card(id))
	chars_car.set_cards(cards)
	chars_car.set_marker(Characters.ID_ORDER.find(GameState.selected))
	_refresh_info()


func _char_card(id: String) -> Control:
	var def := Characters.get_def(id)
	var is_owned := GameState.owns(id)
	var is_sel := GameState.selected == id
	var pal: Dictionary = def["pal"]
	var accent: Color = pal["glow"]
	var card := PanelContainer.new()
	var cw := CharCarousel.CARD_W
	card.custom_minimum_size = Vector2(cw, 0)
	var tier := String(def.get("tier", ""))
	var border := UITheme.GOLD if is_sel else Color(0.4, 0.42, 0.62, 0.85)
	var bg := Color(0.06, 0.07, 0.18, 0.92)
	var bw := 3 if is_sel else 2
	if tier != "":
		border = Color("#9aff3a") if not is_sel else UITheme.GOLD
		bg = Color(0.10, 0.04, 0.07, 0.95)
		bw = 4
	if tier == "SS-CLASS":
		border = Color("#c79bff") if not is_sel else UITheme.GOLD
		bg = Color(0.05, 0.02, 0.12, 0.96)
	card.add_theme_stylebox_override("panel", UITheme.box(bg, border, bw, 12, 8))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	card.add_child(vb)
	var pv := CharPreview.new()
	pv.char_id = id
	pv.locked = not is_owned
	pv.custom_minimum_size = Vector2(cw - 28.0, 96)
	vb.add_child(pv)
	if tier != "":
		vb.add_child(UITheme.label("%s  %s  %s" % ["*", tier, "*"], 13, Color("#9aff3a") if tier != "SS-CLASS" else Color("#e0b8ff"), 1))
	vb.add_child(UITheme.label(String(def["name"]), 26, Color("#ffe9a8") if tier == "" else (Color("#ff6a3a") if tier != "SS-CLASS" else Color("#ffd75a")), 1))
	vb.add_child(UITheme.label(String(def["title"]), 14, accent.lightened(0.2), 1))
	var desc := UITheme.label(String(def["desc"]), 13, Color(0.82, 0.86, 1.0, 0.9), 1)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(cw - 28.0, 52)
	vb.add_child(desc)
	vb.add_child(UITheme.label("RUN: %s" % String(def["run_name"]), 12, Color(0.7, 1.0, 0.85, 0.9)))
	var slots := [["dash", "K", Color("#b48aff")], ["special", "L", Color("#7ad8ff")], ["ultimate", "U", Color("#ff4cba")]]
	for sl in slots:
		var sk: Dictionary = def["skills"][String(sl[0])]
		var line := "[%s] %s  %s" % [String(sl[1]), String(sk["name"]), _fmt_cd(float(sk["cd"]))]
		vb.add_child(UITheme.label(line, 12, sl[2]))
	var b: Button
	if is_sel:
		b = UITheme.button("SELECTED", int(cw - 28.0))
		b.disabled = true
	elif is_owned:
		b = UITheme.button("SELECT", int(cw - 28.0))
		b.pressed.connect(func():
			if not chars_car.can_click():
				return
			GameState.select_char(id)
			_rebuild_chars())
	else:
		b = UITheme.button("BUY  %d" % GameState.char_price(id), int(cw - 28.0))
		b.disabled = not GameState.can_buy_char(id)
		b.pressed.connect(func():
			if not chars_car.can_click():
				return
			if GameState.buy_char(id):
				Sfx.play("powerup")
				GameState.select_char(id)
				_rebuild_chars())
	b.custom_minimum_size = Vector2(cw - 28.0, 40)
	var ci := Characters.ID_ORDER.find(id)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(spacer)
	b.focus_entered.connect(func(): chars_car.ensure_visible(ci))
	vb.add_child(b)
	return card


func _build_settings() -> void:
	var pc := PanelContainer.new()
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	vb.custom_minimum_size = Vector2(520, 0)
	pc.add_child(vb)
	vb.add_child(UITheme.label("SETTINGS", 40, Color("#ffe9a8"), 1))
	for row in [["MUSIC", "music"], ["SOUND FX", "sfx"]]:
		var h := HBoxContainer.new()
		var l := UITheme.label(row[0], 22)
		l.custom_minimum_size = Vector2(170, 0)
		h.add_child(l)
		var s := HSlider.new()
		s.min_value = 0.0
		s.max_value = 1.0
		s.step = 0.05
		s.value = float(GameState.settings[row[1]])
		s.custom_minimum_size = Vector2(300, 28)
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var key: String = row[1]
		s.value_changed.connect(func(v: float):
			GameState.set_setting(key, v)
			if key == "sfx":
				Sfx.play("coin"))
		h.add_child(s)
		vb.add_child(h)
	for row in [["SCREEN SHAKE", "shake"], ["BLOOM GLOW", "bloom"], ["DYNAMIC SHADOWS", "shadows"]]:
		var cb := CheckButton.new()
		cb.text = row[0]
		cb.button_pressed = bool(GameState.settings[row[1]])
		var key2: String = row[1]
		cb.toggled.connect(func(on: bool):
			GameState.set_setting(key2, on)
			if key2 == "shadows":
				world.apply_theme(maxi(world.applied_stage, 0)))
		vb.add_child(cb)
	var h2 := HBoxContainer.new()
	var l2 := UITheme.label("TOUCH BUTTONS", 22)
	l2.custom_minimum_size = Vector2(250, 0)
	h2.add_child(l2)
	var ob := OptionButton.new()
	ob.add_item("AUTO", 0)
	ob.add_item("ALWAYS ON", 1)
	ob.add_item("OFF", 2)
	ob.selected = int(GameState.settings["touch"])
	ob.item_selected.connect(func(i: int): GameState.set_setting("touch", i))
	h2.add_child(ob)
	vb.add_child(h2)
	var back := UITheme.button("BACK", 200)
	back.pressed.connect(func(): _show(_from_state))
	var c := CenterContainer.new()
	c.add_child(back)
	vb.add_child(c)
	set_root = _center(pc)


class LogoDraw extends Control:
	func _draw() -> void:
		var t := Time.get_ticks_msec() / 1000.0
		var f := ThemeDB.fallback_font
		var c := Vector2(1060, 190)
		var pts := PackedVector2Array()
		for i in 8:
			var r := 78.0 if i % 2 == 0 else 22.0
			var a := t * 0.9 + i * PI / 4.0
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		SafeDraw.poly(self, pts, Color(0.07, 0.08, 0.2, 0.75))
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, Color("#e8b84a"), 3.0)
		draw_circle(c, 11.0, Color("#e8b84a"))
		draw_circle(c, 5.0, Color(0.07, 0.08, 0.2))
		var glow := 0.6 + 0.4 * sin(t * 1.6)
		draw_string(f, Vector2(94, 118), "YORU NO", HORIZONTAL_ALIGNMENT_LEFT, -1, 52, Color(0.95, 0.9, 1.0, 0.95))
		draw_string(f, Vector2(90, 196), "SHINOBI", HORIZONTAL_ALIGNMENT_LEFT, -1, 84, Color(1.0, 0.45, 0.6, 0.35 * glow))
		draw_string(f, Vector2(94, 192), "SHINOBI", HORIZONTAL_ALIGNMENT_LEFT, -1, 84, Color("#ffd86a"))
		draw_string(f, Vector2(98, 226), "~ ENDLESS NINJA RUN ~", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.8, 0.88, 1.0, 0.9))
