class_name WorldEndFx
extends CanvasLayer

const VW := 640.0
const VH := 288.0
const GRAV := 380.0
const SPREAD_SPEED := 430.0
const TEXT_AT := 1.6
const FADE_AT := 4.2

var world: World
var tex: ImageTexture
var imp := Vector2(320.0, 216.0)
var zoom := 1.0
var shards: Array = []
var coins: Array = []
var age := 0.0
var rd := 0.016
var vault := Vector2(19.0, 15.5)
var final_money := 0
var _pulse := 0.0
var _coin_snd := 0.0
var _arrived := 0
var _main: Node2D
var _add: Node2D
var _txt: Node2D
var _font: Font


func setup(w: World, t: ImageTexture, impact_screen: Vector2, z: float, mesh: PackedVector2Array) -> void:
	world = w
	tex = t
	imp = impact_screen
	zoom = z
	layer = 30
	_font = ThemeDB.fallback_font
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	var screen := Rect2(-30.0, -30.0, VW + 60.0, VH + 60.0)
	for sh in WEMesh.shards(mesh):
		var pts := PackedVector2Array()
		for q in (sh["pts"] as PackedVector2Array):
			pts.append(imp + q * zoom)
		var bb := Rect2(pts[0], Vector2.ZERO)
		for q in pts:
			bb = bb.expand(q)
		if not screen.intersects(bb):
			continue
		var c: Vector2 = imp + (sh["c"] as Vector2) * zoom
		var uv := PackedVector2Array()
		for q in pts:
			uv.append(Vector2(q.x / VW, q.y / VH))
		var dir := (c - imp).normalized() if c.distance_to(imp) > 1.0 else Vector2.UP
		shards.append({
			"pts": pts, "uv": uv, "c": c,
			"delay": (float(sh["d"]) * zoom) / SPREAD_SPEED + rng.randf_range(0.0, 0.07),
			"v": dir * rng.randf_range(15.0, 80.0) + Vector2(rng.randf_range(-25.0, 25.0), rng.randf_range(-70.0, -5.0)),
			"spin": rng.randf_range(-2.6, 2.6),
		})
	var mult := GameState.coin_mult()
	var add_value := 0
	for n in world.ent_root.get_children():
		if n is Coin:
			var cn := n as Coin
			var sp := Skills._we_screen(world, cn.global_position)
			if sp.x < 8.0 or sp.x > VW - 8.0 or sp.y < 8.0 or sp.y > VH - 8.0:
				sp = Vector2(rng.randf_range(0.0, VW), rng.randf_range(0.0, VH))
			var val := int(round(float(cn.value) * mult))
			add_value += val
			coins.append(_mk_coin(sp, val, rng))
			cn.queue_free()
	for i in clampi(world.coins_run / 2, 0, 26):
		coins.append(_mk_coin(Vector2(rng.randf_range(0.0, VW), rng.randf_range(0.0, VH)), 0, rng))
	final_money = world.money_run + add_value

	_main = Node2D.new()
	_main.draw.connect(_draw_main)
	add_child(_main)
	_add = Node2D.new()
	_add.material = Fx.add_mat()
	_add.draw.connect(_draw_add)
	add_child(_add)
	_txt = Node2D.new()
	_txt.draw.connect(func(): _draw_text(false))
	add_child(_txt)


func _mk_coin(sp: Vector2, val: int, rng: RandomNumberGenerator) -> Dictionary:
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	return {
		"s": sp, "val": val, "t0": 0.35 + rng.randf_range(0.0, 1.1), "dur": rng.randf_range(0.95, 1.4),
		"swirl": side * rng.randf_range(70.0, 190.0), "ph": rng.randf() * TAU, "done": false,
	}


func _process(delta: float) -> void:
	rd = delta / maxf(Engine.time_scale, 0.05)
	age += rd
	_pulse = maxf(0.0, _pulse - rd * 3.0)
	_coin_snd -= rd
	for c in coins:
		var u := (age - float(c["t0"])) / float(c["dur"])
		if u >= 1.0 and not bool(c["done"]):
			c["done"] = true
			_arrived += 1
			_pulse = 1.0
			if int(c["val"]) > 0:
				world.coins_run += 1
				world.money_run += int(c["val"])
			if _coin_snd <= 0.0:
				_coin_snd = 0.05
				Sfx.play("coin", 0.9 + minf(float(_arrived), 30.0) * 0.03, -8.0)
	_main.queue_redraw()
	_add.queue_redraw()
	_txt.queue_redraw()


func _draw_main() -> void:
	_main.draw_rect(Rect2(0.0, 0.0, VW, VH), Color(0.0, 0.0, 0.0, 1.0))
	_main.draw_texture_rect(TexGen.glow_tex(128), Rect2(imp - Vector2(260, 160), Vector2(520, 320)), false, Color(0.25, 0.08, 0.4, 0.22 * smoothstep(0.3, 1.5, age)))
	for s in shards:
		var ts := age - float(s["delay"])
		var pts: PackedVector2Array = s["pts"]
		var uv: PackedVector2Array = s["uv"]
		var m := 1.0
		var a := 1.0
		var out := pts
		if ts >= 0.0:
			var c: Vector2 = s["c"]
			var v: Vector2 = s["v"]
			var off := v * ts + Vector2(0.0, 0.5 * GRAV * ts * ts)
			var rot := float(s["spin"]) * ts
			var sc := maxf(0.0, 1.0 - 0.25 * ts)
			a = 1.0 - smoothstep(0.5, 1.5, ts)
			m = 1.0 - 0.55 * smoothstep(0.0, 0.8, ts)
			if a <= 0.01:
				continue
			out = PackedVector2Array()
			for q in pts:
				out.append(c + off + (q - c).rotated(rot) * sc)
		var col := Color(m, m, m, a)
		var cols := PackedColorArray()
		for i in out.size():
			cols.append(col)
		if tex != null:
			_main.draw_polygon(out, cols, uv, tex)
		else:
			var g := PackedColorArray()
			for i in out.size():
				g.append(Color(0.18 * m, 0.1 * m, 0.26 * m, a))
			_main.draw_polygon(out, g)
		if ts >= 0.0 and ts < 0.5:
			var closed := out.duplicate()
			closed.append(out[0])
			_main.draw_polyline(closed, Color(1.0, 0.85, 0.4, (1.0 - ts / 0.5) * a), 1.5)


func _draw_add() -> void:
	var vis := smoothstep(0.8, 2.2, age)
	if vis > 0.01:
		for i in 46:
			var h1 := fposmod(sin(float(i) * 12.9898) * 43758.5453, 1.0)
			var h2 := fposmod(sin(float(i) * 78.233) * 12543.123, 1.0)
			var x := h1 * VW
			var y := fposmod(h2 * VH - age * (6.0 + h1 * 12.0), VH)
			var gold := i % 2 == 0
			var al := (0.25 + 0.35 * absf(sin(age * 1.5 + float(i)))) * vis
			_add.draw_rect(Rect2(x, y, 1.5, 1.5), Color(1.0, 0.85, 0.4, al) if gold else Color(0.65, 0.4, 1.0, al))
	for c in coins:
		var u := (age - float(c["t0"])) / float(c["dur"])
		if u <= 0.0 or u >= 1.0:
			continue
		var e := pow(u, 1.7)
		var s: Vector2 = c["s"]
		var ctrl := (s + vault) * 0.5 + Vector2(-(vault - s).y, (vault - s).x).normalized() * float(c["swirl"])
		var p1 := _bez(s, ctrl, vault, e)
		var p0 := _bez(s, ctrl, vault, maxf(0.0, e - 0.07))
		_add.draw_line(p0, p1, Color(1.0, 0.8, 0.3, 0.6), 2.0)
		var wdt := absf(cos(age * 14.0 + float(c["ph"])))
		var r := lerpf(5.0, 3.0, e)
		var pts := PackedVector2Array()
		for i in 10:
			var an := float(i) * TAU / 10.0
			pts.append(p1 + Vector2(cos(an) * r * maxf(0.25, wdt), sin(an) * r))
		_add.draw_colored_polygon(pts, Color(1.0, 0.85, 0.3, 1.0))
		_add.draw_texture_rect(TexGen.glow_tex(64), Rect2(p1 - Vector2(9, 9), Vector2(18, 18)), false, Color(1.0, 0.8, 0.3, 0.55))
	if _pulse > 0.01 and age < 5.5:
		_add.draw_texture_rect(TexGen.glow_tex(64), Rect2(vault - Vector2(30, 30), Vector2(60, 60)), false, Color(1.0, 0.8, 0.3, 0.7 * _pulse))
	_draw_text(true)


func _bez(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var q := 1.0 - t
	return a * q * q + b * 2.0 * q * t + c * t * t


func _draw_text(add: bool) -> void:
	var tt := age - TEXT_AT
	if tt <= 0.0:
		return
	var fade := 1.0 - smoothstep(FADE_AT, FADE_AT + 0.9, age)
	if fade <= 0.01:
		return
	var title := "WORLD END"
	var fs := 46
	var spacing := lerpf(22.0, 5.0, smoothstep(0.0, 1.6, tt)) + sin(tt * 2.0) * 0.8
	var widths: Array[float] = []
	var total := 0.0
	for ch in title:
		var wch := _font.get_string_size(String(ch), HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		widths.append(wch)
		total += wch + spacing
	total -= spacing
	var x := (VW - total) * 0.5
	var y := VH * 0.5 + 12.0
	var ln := smoothstep(0.0, 0.9, tt) * fade
	if add:
		_add.draw_texture_rect(TexGen.glow_tex(128), Rect2(Vector2(40.0, y - 62.0), Vector2(VW - 80.0, 100.0)), false, Color(0.7, 0.4, 1.0, 0.35 * ln))
		_add.draw_line(Vector2(VW * 0.5 - 250.0 * ln, y - 17.0), Vector2(VW * 0.5 + 250.0 * ln, y - 17.0), Color(1.0, 0.85, 0.4, 0.5 * fade), 1.0)
	for i in title.length():
		var la := clampf((tt - float(i) * 0.09) / 0.45, 0.0, 1.0) * fade
		if la > 0.0:
			var drop := (1.0 - la) * -14.0
			var pos := Vector2(x, y + drop)
			var ch := String(title[i])
			var cx := pos.x + widths[i] * 0.5
			if add:
				_add.draw_texture_rect(TexGen.glow_tex(64), Rect2(Vector2(cx - 36.0, y - 40.0), Vector2(72.0, 72.0)), false, Color(1.0, 0.8, 0.3, 0.45 * la))
				_add.draw_string(_font, pos + Vector2(-1.8, 0.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.65, 0.35, 1.0, 0.7 * la))
				_add.draw_string(_font, pos + Vector2(1.8, 0.0), ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.45, 0.2, 0.55 * la))
			else:
				_txt.draw_string_outline(_font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, 6, Color(0.06, 0.0, 0.12, la))
				_txt.draw_string(_font, pos, ch, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1.0, 0.93, 0.7, la))
		x += widths[i] + spacing
	var sa := smoothstep(0.9, 1.5, tt) * fade
	if sa > 0.01 and add:
		var sub := "THE ECLIPSE SOVEREIGN HAS ERASED THE WORLD"
		var sw := _font.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
		_add.draw_string(_font, Vector2((VW - sw) * 0.5, y + 22.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.85, 0.75, 1.0, 0.85 * sa))
		var vs := "ALL COINS SEALED IN THE VAULT   +%d" % final_money
		var vw2 := _font.get_string_size(vs, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		_add.draw_string(_font, Vector2((VW - vw2) * 0.5, y + 42.0), vs, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.85, 0.35, sa))
