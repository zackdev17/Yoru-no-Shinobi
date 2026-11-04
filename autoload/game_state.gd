extends Node

signal coins_changed
signal settings_changed
signal character_changed
signal save_replaced          # progres diganti penuh (restore / impor kode) -> UI perlu refresh
signal backup_status_changed  # status backup eksternal berubah

# --- Sistem penyimpanan (lihat README bagian 10) ---
const SAVE_PATH := "user://yoru_save.json"   # save utama (privat; selamat dari update aplikasi)
const SAVE_BAK := "user://yoru_save.bak"     # salinan save valid sebelumnya
const EXT_FOLDER := "YoruNoShinobi"          # cermin di Documents/ (selamat dari uninstall)
const EXT_FILE := "yoru_save.json"
const CODE_PREFIX := "YNS1-"                 # awalan kode save yang bisa disalin
const MIRROR_MIN_INTERVAL := 4.0             # jeda minimum antar tulis cermin (detik)
const PERM_WAIT_MAX := 30.0                  # batas tunggu dialog izin sebelum cermin boleh jalan

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

var rev := 0                       # naik setiap save; dipakai memilih salinan terbaru
var perm_asked := false
var ext_state := "unavailable"     # unavailable (bukan Android) | ok | need_permission | error
var _last_text := ""
var _mirror_dirty := false
var _mirror_cd := 0.0
var _mirror_blocked := false       # tahan tulis cermin selama menunggu restore saat install baru
var _block_timer := 0.0
var _awaiting_perm := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_inputs()
	var had_local := FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_BAK)
	load_game()
	_refresh_ext_state()
	if _is_android():
		get_tree().on_request_permissions_result.connect(_on_permission_result)
		# Install baru (tanpa save lokal) atau belum pernah diminta -> minta izin sekali,
		# lalu coba pulihkan dari Documents/YoruNoShinobi.
		if ext_state != "ok" and (not had_local or not perm_asked):
			request_backup_permission()


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


# ---------------------------------------------------------------------------
# Penyimpanan data
#  1. user://yoru_save.json  : tulis atomik (tmp -> rename) + checksum + .bak
#  2. Documents/YoruNoShinobi: cermin otomatis di Android -> progres bisa dipulihkan setelah uninstall
#  3. Kode save (clipboard)  : cadangan manual yang selalu bisa dipakai
# Saat load, salinan dengan `rev` tertinggi yang valid (checksum cocok) dipakai.
# ---------------------------------------------------------------------------

var ext_dir_override := ""   # hanya untuk pengujian di desktop: paksa mode cermin ke folder ini


func _is_android() -> bool:
	return OS.has_feature("android") or ext_dir_override != ""


func _ext_dir() -> String:
	if ext_dir_override != "":
		return ext_dir_override
	return OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join(EXT_FOLDER)


func _ext_path() -> String:
	return _ext_dir().path_join(EXT_FILE)


func _snapshot() -> Dictionary:
	return {
		"coins": coins, "best_m": best_m, "best_score": best_score, "runs": total_runs,
		"settings": settings, "tutorial": seen_tutorial,
		"owned": owned, "selected": selected, "char_upgrades": char_upgrades,
		"perm_asked": perm_asked,
	}


func _wrap(data: Dictionary) -> String:
	var payload := JSON.stringify(data)
	return JSON.stringify({
		"v": 2, "rev": rev, "saved_at": int(Time.get_unix_time_from_system()),
		"sum": payload.sha256_text(), "payload": payload,
	})


# Parser JSON yang diam (tidak mencetak error engine untuk input rusak).
func _parse(text: String):
	var j := JSON.new()
	if j.parse(text) != OK:
		return null
	return j.data


# Mengembalikan {"rev": int, "data": Dictionary} bila valid, {} bila rusak.
func _unwrap(text: String) -> Dictionary:
	if text.is_empty():
		return {}
	var parsed = _parse(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	if parsed.has("payload"):
		var payload := String(parsed["payload"])
		if payload.sha256_text() != String(parsed.get("sum", "")):
			return {}
		var d = _parse(payload)
		if typeof(d) != TYPE_DICTIONARY:
			return {}
		return {"rev": int(parsed.get("rev", 0)), "data": d}
	if parsed.has("coins"):   # format lama (tanpa checksum)
		return {"rev": 0, "data": parsed}
	return {}


func _read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	return _unwrap(FileAccess.get_file_as_string(path))


func _write_atomic(path: String, text: String) -> bool:
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(text)
	f.flush()
	f.close()
	if FileAccess.get_file_as_string(tmp) != text:   # verifikasi hasil tulis
		DirAccess.remove_absolute(tmp)
		return false
	if DirAccess.rename_absolute(tmp, path) != OK:
		DirAccess.remove_absolute(tmp)
		return false
	return true


func save_game() -> void:
	rev += 1
	_last_text = _wrap(_snapshot())
	if not _read_save(SAVE_PATH).is_empty():          # simpan save valid lama sebagai .bak
		DirAccess.copy_absolute(SAVE_PATH, SAVE_BAK)
	if not _write_atomic(SAVE_PATH, _last_text):      # cadangan bila rename gagal
		var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if f:
			f.store_string(_last_text)
			f.close()
	_mirror_dirty = true


func load_game() -> void:
	var best := {}
	var cands: Array = [SAVE_PATH, SAVE_BAK]
	if _is_android():
		cands.append(_ext_path())
	for src in cands:
		var r := _read_save(src)
		if r.is_empty():
			continue
		if best.is_empty() or int(r["rev"]) > int(best["rev"]):   # seri -> yang lebih awal di daftar
			best = r
			best["src"] = src
	if best.is_empty():
		return
	_apply(best["data"])
	rev = int(best["rev"])
	if String(best["src"]) != SAVE_PATH:
		save_game()   # sembuhkan save utama dari cadangan/cermin


func _apply(parsed: Dictionary) -> void:
	coins = int(parsed.get("coins", 0))
	best_m = int(parsed.get("best_m", 0))
	best_score = int(parsed.get("best_score", 0))
	total_runs = int(parsed.get("runs", 0))
	seen_tutorial = bool(parsed.get("tutorial", false))
	perm_asked = bool(parsed.get("perm_asked", perm_asked))
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


# --- Cermin eksternal (Android) -------------------------------------------

func _ext_writable() -> bool:
	if not _is_android():
		return false
	var dir := _ext_dir()
	if not DirAccess.dir_exists_absolute(dir):
		if DirAccess.make_dir_recursive_absolute(dir) != OK:
			return false
	var probe := dir.path_join(".probe")
	var f := FileAccess.open(probe, FileAccess.WRITE)
	if f == null:
		return false
	f.close()
	DirAccess.remove_absolute(probe)
	return true


func _refresh_ext_state() -> void:
	var old := ext_state
	if not _is_android():
		ext_state = "unavailable"
	elif _ext_writable():
		ext_state = "ok"
	else:
		ext_state = "need_permission"
	if old != ext_state:
		backup_status_changed.emit()


func _mirror_external() -> void:
	_mirror_dirty = false
	_mirror_cd = MIRROR_MIN_INTERVAL
	if not _is_android() or _mirror_blocked:
		return
	if _last_text.is_empty():
		_last_text = _wrap(_snapshot())
	var old := ext_state
	if not _ext_writable():
		ext_state = "need_permission"
	else:
		var path := _ext_path()
		if _write_atomic(path, _last_text):
			ext_state = "ok"
		else:
			var f := FileAccess.open(path, FileAccess.WRITE)   # file lama milik instalasi sebelumnya
			if f:
				f.store_string(_last_text)
				f.close()
				ext_state = "ok"
			else:
				ext_state = "error"
	if old != ext_state:
		backup_status_changed.emit()


func request_backup_permission() -> void:
	if not _is_android():
		return
	perm_asked = true
	_awaiting_perm = true
	_mirror_blocked = true
	_block_timer = PERM_WAIT_MAX
	if OS.request_permissions():   # true = semua izin sudah diberikan
		_after_permission_change()


func _on_permission_result(_permission: String, _granted: bool) -> void:
	_after_permission_change()


func _after_permission_change() -> void:
	_awaiting_perm = false
	_refresh_ext_state()
	if ext_state == "ok":
		var r := _read_save(_ext_path())
		if not r.is_empty() and int(r["rev"]) > rev:
			_apply(r["data"])
			rev = int(r["rev"])
			save_game()
			_emit_replaced()
	_mirror_blocked = false
	_mirror_dirty = true
	backup_status_changed.emit()


func _emit_replaced() -> void:
	coins_changed.emit()
	character_changed.emit()
	settings_changed.emit()
	save_replaced.emit()


# --- Kode save (cadangan manual lewat clipboard) ----------------------------

func export_code() -> String:
	return CODE_PREFIX + Marshalls.utf8_to_base64(_wrap(_snapshot()))


func import_code(code: String) -> bool:
	var c := code.strip_edges().replace("\n", "").replace("\r", "").replace(" ", "")
	if not c.begins_with(CODE_PREFIX):
		return false
	var r := _unwrap(Marshalls.base64_to_utf8(c.substr(CODE_PREFIX.length())))
	if r.is_empty() or int(r["rev"]) < 1:
		return false
	var keep_asked := perm_asked
	_apply(r["data"])
	perm_asked = keep_asked
	rev = maxi(rev, int(r["rev"]))
	save_game()
	_mirror_external()
	_emit_replaced()
	return true


# --- Pemicu simpan otomatis -------------------------------------------------

func flush_save() -> void:
	save_game()
	_mirror_external()


func _process(delta: float) -> void:
	if _mirror_cd > 0.0:
		_mirror_cd -= delta
	if _mirror_blocked and _awaiting_perm:
		_block_timer -= delta
		if _block_timer <= 0.0:
			_after_permission_change()
	if _mirror_dirty and not _mirror_blocked and _mirror_cd <= 0.0:
		_mirror_external()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST:
			flush_save()
		NOTIFICATION_APPLICATION_RESUMED:
			if _awaiting_perm:
				_after_permission_change()   # kembali dari layar pengaturan "akses semua file"
			else:
				_refresh_ext_state()


func set_setting(key: String, value) -> void:
	settings[key] = value
	save_game()
	settings_changed.emit()
