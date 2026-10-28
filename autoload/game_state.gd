extends Node

signal coins_changed
signal settings_changed
signal character_changed

const SAVE_PATH := "user://yoru_save.json"

const UPGRADES := {
	"hearts": {"name": "SPIRIT HEARTS", "desc": "+1 starting heart", "max": 2, "base": 350},
	"magnet": {"name": "MAGNET TALISMAN", "desc": "+2s magnet duration", "max": 5, "base": 120},
	"pouch": {"name": "SHURIKEN POUCH", "desc": "+2 max shuriken", "max": 5, "base": 100},
	"fortune": {"name": "LUCKY COINS", "desc": "+15% coin value", "max": 5, "base": 150},
	"ward": {"name": "PAPER WARD", "desc": "Start each run with a shield", "max": 1, "base": 500},
}
const UPGRADE_ORDER := ["hearts", "magnet", "pouch", "dash", "special", "ulti", "unique", "fortune", "ward"]
const DEFAULT_SKILL_UPG_BASE := 180

var coins := 0
var best_m := 0
var best_score := 0
var total_runs := 0
var seen_tutorial := false
var selected := "kage"
var owned: Array = ["kage"]
var char_upgrades := {"kage": {}}
var settings := {
	"music": 0.7, "sfx": 0.9, "shake": true, "bloom": true, "touch": 0, "shadows": true,
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_inputs()
	load_game()


func _key_action(action: String, keys: Array, joy: Array = []) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	for b in joy:
		var jb := InputEventJoypadButton.new()
		jb.button_index = b
		InputMap.action_add_event(action, jb)


func _setup_inputs() -> void:
	_key_action("jump", [KEY_SPACE, KEY_UP, KEY_W], [JOY_BUTTON_A])
	_key_action("slide", [KEY_DOWN, KEY_S], [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_B])
	_key_action("throw", [KEY_J, KEY_X, KEY_RIGHT, KEY_D], [JOY_BUTTON_X])
	_key_action("dash", [KEY_K, KEY_SHIFT, KEY_Z, KEY_LEFT], [JOY_BUTTON_Y, JOY_BUTTON_RIGHT_SHOULDER])
	_key_action("pause_game", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])
	_key_action("confirm", [KEY_ENTER, KEY_SPACE], [JOY_BUTTON_A])


func owns(id: String) -> bool:
	return owned.has(id)


func char_price(id: String) -> int:
	return int(Characters.get_def(id)["price"])


func can_buy_char(id: String) -> bool:
	return not owns(id) and coins >= char_price(id)


func buy_char(id: String) -> bool:
	if not can_buy_char(id):
		return false
	coins -= char_price(id)
	owned.append(id)
	if not char_upgrades.has(id):
		char_upgrades[id] = {}
	save_game()
	coins_changed.emit()
	return true


func select_char(id: String) -> bool:
	if not owns(id):
		return false
	selected = id
	save_game()
	character_changed.emit()
	return true


func char_def() -> Dictionary:
	return Characters.get_def(selected)


func upgrade_info(id: String) -> Dictionary:
	var cd := char_def()
	match id:
		"dash", "special", "ulti":
			var slot := "ultimate" if id == "ulti" else id
			var sk: Dictionary = cd["skills"][slot]
			return {
				"name": sk["name"],
				"desc": "-%.1fs cooldown" % float(sk["step"]),
				"max": 4,
				"base": DEFAULT_SKILL_UPG_BASE + (60 if id == "ulti" else 0),
			}
		"unique":
			return cd["unique"]
	return UPGRADES[id]


func upgrade_level_of(char_id: String, id: String) -> int:
	var d: Dictionary = char_upgrades.get(char_id, {})
	return int(d.get(id, 0))


func upgrade_level(id: String) -> int:
	return upgrade_level_of(selected, id)


func upgrade_cost(id: String) -> int:
	var lvl := upgrade_level(id)
	return int(upgrade_info(id)["base"]) * (lvl + 1) * int(char_def().get("cost_mult", 1))


func can_buy(id: String) -> bool:
	return upgrade_level(id) < int(upgrade_info(id)["max"]) and coins >= upgrade_cost(id)


func buy(id: String) -> bool:
	if not can_buy(id):
		return false
	coins -= upgrade_cost(id)
	if not char_upgrades.has(selected):
		char_upgrades[selected] = {}
	char_upgrades[selected][id] = upgrade_level(id) + 1
	save_game()
	coins_changed.emit()
	return true


func max_hearts() -> int:
	return 3 + upgrade_level("hearts")


func max_ammo() -> int:
	return 5 + 2 * upgrade_level("pouch")


func magnet_time() -> float:
	return 8.0 + 2.0 * upgrade_level("magnet")


func dash_cooldown() -> float:
	return Characters.skill_cd(selected, "dash", upgrade_level("dash"))


func special_cooldown() -> float:
	return Characters.skill_cd(selected, "special", upgrade_level("special"))


func ulti_cooldown() -> float:
	return Characters.skill_cd(selected, "ultimate", upgrade_level("ulti"))


func coin_mult() -> float:
	return 1.0 + 0.15 * upgrade_level("fortune")


func add_coins(n: int) -> void:
	coins += n
	coins_changed.emit()


func save_game() -> void:
	var data := {
		"coins": coins, "best_m": best_m, "best_score": best_score, "runs": total_runs,
		"settings": settings, "tutorial": seen_tutorial,
		"owned": owned, "selected": selected, "char_upgrades": char_upgrades,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	coins = int(parsed.get("coins", 0))
	best_m = int(parsed.get("best_m", 0))
	best_score = int(parsed.get("best_score", 0))
	total_runs = int(parsed.get("runs", 0))
	seen_tutorial = bool(parsed.get("tutorial", false))
	var ow = parsed.get("owned", ["kage"])
	owned = []
	if typeof(ow) == TYPE_ARRAY:
		for cid in ow:
			if Characters.DATA.has(String(cid)) and not owned.has(String(cid)):
				owned.append(String(cid))
	if not owned.has("kage"):
		owned.append("kage")
	char_upgrades = {}
	for cid in Characters.DATA.keys():
		char_upgrades[cid] = {}
	var cu = parsed.get("char_upgrades", null)
	if typeof(cu) == TYPE_DICTIONARY:
		for cid in cu.keys():
			if char_upgrades.has(cid) and typeof(cu[cid]) == TYPE_DICTIONARY:
				for uid in cu[cid].keys():
					char_upgrades[cid][String(uid)] = int(cu[cid][uid])
	else:
		var up = parsed.get("upgrades", {})
		if typeof(up) == TYPE_DICTIONARY:
			for uid in up.keys():
				char_upgrades["kage"][String(uid)] = int(up[uid])
	var sel := String(parsed.get("selected", "kage"))
	selected = sel if owned.has(sel) else "kage"
	var st = parsed.get("settings", {})
	if typeof(st) == TYPE_DICTIONARY:
		for k in settings.keys():
			if st.has(k):
				settings[k] = st[k]


func set_setting(key: String, value) -> void:
	settings[key] = value
	save_game()
	settings_changed.emit()
