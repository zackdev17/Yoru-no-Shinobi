class_name LevelGen
extends RefCounted

const GY := 216.0
const AHEAD := 950.0

const HORDE_START := 0.85
const HORDE_MIN := 360.0
const HORDE_MAX := 900.0
const CLOSE_RUN := 560.0

var w: Node
var cursor := 0.0
var rng := RandomNumberGenerator.new()
var since_power := 0
var since_light := 0.0
var last := ""
var count := 0
var _stage_seen := 0
var _horde_stage := -1


func reset(start_x: float) -> void:
	cursor = start_x
	_stage_seen = 0
	_horde_stage = -1
	since_power = 0
	since_light = 0.0
	last = ""
	count = 0
	rng.randomize()


func difficulty() -> float:
	return clampf(cursor / (Themes.STAGE_PX * 3.0), 0.0, 1.0)


func update(player_x: float) -> void:
	while cursor < player_x + AHEAD:
		_next()


func stage() -> int:
	return int(cursor / Themes.STAGE_PX)


func _next() -> void:
	var st := stage()
	var boundary := float(st + 1) * Themes.STAGE_PX
	var remain := boundary - cursor
	if remain < CLOSE_RUN:
		w.add_ground(cursor, boundary, st)
		_props(cursor, boundary, st)
		_coin_line(cursor + 60.0, minf(boundary - 40.0, cursor + 300.0), GY - 18.0)
		cursor = boundary
		w.add_gate(boundary + 70.0, st + 1)
		return
	count += 1
	var d := difficulty() + st * 0.04
	var opts: Array = [["flat", 1.6], ["gap", 2.1], ["bridge", 1.3], ["platforms", 1.6], ["spikes", 1.8],
		["oni", 2.8 + d * 3.0], ["crow", 2.0 + d * 2.8], ["wisp", 1.5 + d * 2.2], ["barrel", 0.9 + d * 1.2], ["mixed", d * 3.0]]
	if st % 5 == 2:
		opts.append(["strike", 3.0])
	if count < 3:
		opts = [["flat", 1.0], ["gap", 1.0]]
	if st != _stage_seen:
		_stage_seen = st
		last = "flat"
		_p_flat(d, st)
		since_power += 1
		return
	if _horde_due(st, remain):
		last = "horde"
		_p_horde(d, st)
		since_power += 1
		return
	var total := 0.0
	for o in opts:
		if o[0] != last:
			total += o[1]
	var r := rng.randf() * total
	var pick := "flat"
	for o in opts:
		if o[0] == last:
			continue
		r -= o[1]
		if r <= 0.0:
			pick = o[0]
			break
	last = pick
	call("_p_" + pick, d, st)
	since_power += 1


func _gap_w(d: float) -> float:
	return rng.randf_range(70.0, 100.0 + 50.0 * d)


func _coin_line(x0: float, x1: float, y: float) -> void:
	var x := x0
	while x <= x1:
		w.spawn_coin(Vector2(x, y))
		x += 16.0


func _coin_arc(x0: float, x1: float, y: float, h: float) -> void:
	var n := maxi(3, int((x1 - x0) / 16.0))
	for i in n + 1:
		var u := float(i) / n
		w.spawn_coin(Vector2(lerpf(x0, x1, u), y - sin(u * PI) * h))


func _props(x0: float, x1: float, st: int) -> void:
	var th := Themes.at(st)
	var x := x0 + rng.randf_range(30.0, 90.0)
	while x < x1 - 30.0:
		var kinds: Array = ["bush", "bush", "rock", "fence", "banner", "stone_lantern", "stone_lantern", "paper_pole", "shrine"]
		if th["festival"]:
			kinds.append_array(["paper_pole", "paper_pole", "paper_pole"])
		var k: String = kinds[rng.randi() % kinds.size()]
		if since_light > 260.0 and k in ["bush", "rock", "fence", "banner"]:
			k = "stone_lantern" if rng.randf() < 0.6 else "paper_pole"
		if k in ["stone_lantern", "paper_pole", "shrine"]:
			since_light = 0.0
		w.add_prop(k, x, st)
		var step := rng.randf_range(110.0, 220.0)
		since_light += step
		x += step


func _powerup(x: float, y: float) -> void:
	if since_power < 4:
		return
	since_power = 0
	var kinds := ["shield", "shield", "magnet", "magnet", "star", "lightning"]
	var k: String = kinds[rng.randi() % kinds.size()]
	if w.player.hearts < w.player.max_hearts and rng.randf() < 0.35:
		k = "heart"
	w.spawn_powerup(k, Vector2(x, y))


func _ground(len: float, st: int, props: bool = true) -> void:
	w.add_ground(cursor, cursor + len, st)
	if props:
		_props(cursor, cursor + len, st)


func _p_flat(_d: float, st: int) -> void:
	var len := rng.randf_range(260.0, 420.0)
	_ground(len, st)
	if rng.randf() < 0.5:
		_coin_line(cursor + 50, cursor + len - 50, GY - 18.0)
	else:
		_coin_arc(cursor + 60, cursor + len - 60, GY - 16.0, 46.0)
	_powerup(cursor + len * 0.5, GY - 34.0)
	cursor += len


func _gap_core(width: float, d: float, st: int) -> void:
	w.add_water(cursor, cursor + width, st)
	_coin_arc(cursor + 8.0, cursor + width - 8.0, GY - 26.0, 44.0)
	cursor += width
	var land := rng.randf_range(170.0, 240.0)
	_ground(land, st)
	cursor += land


func _p_gap(d: float, st: int) -> void:
	_gap_core(_gap_w(d), d, st)


func _p_bridge(d: float, st: int) -> void:
	var width := rng.randf_range(230.0, 290.0)
	w.add_water(cursor, cursor + width, st)
	w.add_platform(cursor + 50.0, GY - 48.0, 56.0, st)
	w.add_platform(cursor + width * 0.5 - 28.0, GY - 82.0, 56.0, st)
	w.add_platform(cursor + width - 100.0, GY - 48.0, 56.0, st)
	_coin_line(cursor + 56.0, cursor + 96.0, GY - 64.0)
	_coin_line(cursor + width * 0.5 - 24.0, cursor + width * 0.5 + 24.0, GY - 98.0)
	_coin_line(cursor + width - 94.0, cursor + width - 54.0, GY - 64.0)
	_powerup(cursor + width * 0.5, GY - 116.0)
	cursor += width
	var land := 200.0
	_ground(land, st)
	cursor += land


func _p_platforms(_d: float, st: int) -> void:
	var len := 400.0
	_ground(len, st)
	w.add_platform(cursor + 70.0, GY - 52.0, 64.0, st)
	w.add_platform(cursor + 180.0, GY - 86.0, 56.0, st)
	w.add_platform(cursor + 290.0, GY - 52.0, 64.0, st)
	_coin_line(cursor + 78.0, cursor + 126.0, GY - 68.0)
	_coin_line(cursor + 184.0, cursor + 228.0, GY - 102.0)
	_coin_line(cursor + 298.0, cursor + 346.0, GY - 68.0)
	if rng.randf() < 0.5:
		w.spawn_hazard("spikes", Vector2(cursor + 150.0, GY), st, 24.0)
	_powerup(cursor + 205.0, GY - 126.0)
	cursor += len


func _p_spikes(d: float, st: int) -> void:
	var len := 460.0
	_ground(len, st)
	var n := 1 + int(d * 2.0 + rng.randf() * 1.6)
	for i in mini(n, 3):
		var x := cursor + 130.0 + i * 130.0
		var wd := 24.0 if rng.randf() < 0.6 else 36.0
		w.spawn_hazard("spikes", Vector2(x, GY), st, wd)
		_coin_arc(x - 26.0, x + 26.0, GY - 18.0, 32.0)
	cursor += len


func _p_oni(d: float, st: int) -> void:
	var len := 480.0
	_ground(len, st)
	w.spawn_hazard("oni", Vector2(cursor + 330.0, GY), st)
	if rng.randf() < 0.82:
		w.spawn_hazard("oni", Vector2(cursor + 430.0, GY), st)
	if d > 0.45 and rng.randf() < 0.5:
		w.spawn_hazard("oni", Vector2(cursor + 475.0, GY), st)
	_coin_arc(cursor + 140.0, cursor + 240.0, GY - 20.0, 40.0)
	cursor += len


func _p_crow(d: float, st: int) -> void:
	var len := 460.0
	_ground(len, st)
	var n := 1 + int(d * 2.4 * rng.randf())
	for i in n:
		w.spawn_hazard("crow", Vector2(cursor + 300.0 + i * 78.0, GY - 21.0 - (i % 2) * 18.0), st)
	_coin_line(cursor + 110.0, cursor + 230.0, GY - 18.0)
	cursor += len


func _p_wisp(d: float, st: int) -> void:
	var len := 460.0
	_ground(len, st)
	w.spawn_hazard("wisp", Vector2(cursor + 315.0, GY - 36.0), st)
	if rng.randf() < 0.8:
		w.spawn_hazard("wisp", Vector2(cursor + 410.0, GY - 54.0), st)
	_coin_arc(cursor + 90.0, cursor + 220.0, GY - 20.0, 34.0)
	cursor += len


func _p_barrel(_d: float, st: int) -> void:
	var len := 440.0
	_ground(len, st)
	w.spawn_hazard("barrel", Vector2(cursor + 360.0, GY), st)
	_coin_arc(cursor + 100.0, cursor + 200.0, GY - 20.0, 36.0)
	cursor += len


func _p_strike(d: float, st: int) -> void:
	var len := 480.0
	_ground(len, st)
	w.spawn_hazard("strike", Vector2(cursor + 270.0, GY), st)
	w.spawn_hazard("strike", Vector2(cursor + 380.0, GY), st)
	_coin_line(cursor + 60.0, cursor + 200.0, GY - 18.0)
	cursor += len


func _p_mixed(d: float, st: int) -> void:
	_gap_core(rng.randf_range(80.0, 100.0), d, st)
	_p_spikes(d, st)


func _horde_due(st: int, remain: float) -> bool:
	if _horde_stage == st or bool(w.demo):
		return false
	var frac := (cursor - float(st) * Themes.STAGE_PX) / Themes.STAGE_PX
	return frac >= HORDE_START and remain - CLOSE_RUN >= HORDE_MIN


func _p_horde(d: float, st: int) -> void:
	_horde_stage = st
	var remain := float(st + 1) * Themes.STAGE_PX - cursor
	var len := clampf(remain - CLOSE_RUN, HORDE_MIN, HORDE_MAX)
	_ground(len, st)
	var waves := clampi(int(len / 230.0), 1, 4)
	var gap := (len - 230.0) / float(waves)
	var prev := -1
	for k in waves:
		var x := cursor + 150.0 + gap * float(k)
		var kind := rng.randi() % 3
		if kind == prev:
			kind = (kind + 1) % 3
		prev = kind
		match kind:
			0:
				var n := 3 + int(d * 2.5) + rng.randi_range(0, 1)
				var sp := rng.randf_range(26.0, 34.0)
				for i in n:
					w.spawn_hazard("oni", Vector2(x + float(i) * sp, GY), st)
			1:
				var n2 := 4 + int(d * 3.0)
				for i in n2:
					w.spawn_hazard("crow", Vector2(x + float(i) * 46.0, GY - 21.0 - float(i % 3) * 14.0), st)
			_:
				var n3 := 2 + int(d * 2.0)
				for i in n3:
					w.spawn_hazard("oni", Vector2(x + float(i) * 30.0, GY), st)
				w.spawn_hazard("wisp", Vector2(x + float(n3) * 15.0, GY - 48.0), st)
				for i in 2:
					w.spawn_hazard("crow", Vector2(x + 70.0 + float(i) * 52.0, GY - 30.0 - float(i) * 14.0), st)
	_coin_arc(cursor + len - 170.0, cursor + len - 60.0, GY - 20.0, 40.0)
	_powerup(cursor + len - 90.0, GY - 34.0)
	cursor += len
