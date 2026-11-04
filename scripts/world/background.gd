class_name Background
extends Node2D

var theme: Dictionary = {}
var layers: Array = []
var _unshaded: CanvasItemMaterial
var _additive: CanvasItemMaterial
var _t := 0.0
var _stars: Array = []
var _aurora: BGLayer
var _moon_glow: BGLayer
var _rays: BGLayer
var _lantern_layers: Array = []
var _bolt: Line2D
var _bolt_t := 0.0
var _sky_flash: ColorRect


func _ready() -> void:
	_unshaded = CanvasItemMaterial.new()
	_unshaded.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_additive = CanvasItemMaterial.new()
	_additive.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD

	_add("sky", 1280, 0.0, -100, false, false, 1)
	for i in 3:
		var st := _add("stars", 1280, 0.012 + i * 0.006, -99, false, true, 11 + i)
		_stars.append(st)
	_aurora = _add("aurora", 1280, 0.0, -98, true, false, 5)
	_moon_glow = _add("moon", 1280, 0.0, -97, true, false, 3, true)
	_add("moon", 1280, 0.0, -93, false, false, 3)
	_rays = _add("rays", 1280, 0.0, -95, true, false, 8, true)
	_add("clouds", 1280, 0.05, -94, false, true, 21)
	_add("fuji", 1900, 0.10, -92, false, true, 31)
	_add("ridge", 1280, 0.16, -91, false, true, 2)
	_add("clouds", 1280, 0.10, -90, false, true, 41)
	_add("ridge", 1280, 0.26, -89, false, true, 3)
	_add("village", 1280, 0.36, -88, false, true, 51)
	_add("village", 1280, 0.36, -87, true, true, 51, true)
	_add("trees", 1280, 0.62, -86, false, true, 61)
	_lantern_layers.append(_add("lanterns", 1280, 0.82, -85, false, true, 71))
	_lantern_layers.append(_add("lanterns", 1280, 0.82, -84, true, true, 71, true))

	_bolt = Line2D.new()
	_bolt.width = 2.0
	_bolt.default_color = Color(0.9, 0.92, 1.0)
	_bolt.material = _additive
	_bolt.z_index = -92
	_bolt.visible = false
	add_child(_bolt)
	_sky_flash = ColorRect.new()
	_sky_flash.color = Color(0.8, 0.85, 1.0, 0.0)
	_sky_flash.size = Vector2(700, 300)
	_sky_flash.material = _additive
	_sky_flash.z_index = -92
	add_child(_sky_flash)


func _add(kind: String, w: float, k: float, z: int, additive: bool, tile: bool, seed_v: int, glow := false) -> BGLayer:
	var l := BGLayer.new()
	l.kind = kind
	l.W = w
	l.k = k
	l.z_index = z
	l.tile = tile
	l.seed_val = seed_v
	l.glow_pass = glow or additive
	l.material = _additive if (additive or glow) else _unshaded
	add_child(l)
	layers.append(l)
	return l


func apply_theme(t: Dictionary) -> void:
	theme = t
	for l in layers:
		var bl: BGLayer = l
		bl.rebuild(t)
	var day: bool = t.get("day", false)
	for l in layers:
		var bl2: BGLayer = l
		if bl2.kind == "village" and bl2.glow_pass:
			bl2.visible = not day
	_aurora.visible = bool(t["aurora"])
	for ll in _lantern_layers:
		(ll as BGLayer).visible = bool(t["festival"])
	for st in _stars:
		(st as BGLayer).visible = (t["stars"] as float) > 0.0


func update_scroll(cam_x: float, delta: float) -> void:
	_t += delta
	for l in layers:
		var bl: BGLayer = l
		if bl.tile:
			var s := cam_x * bl.k
			if bl.kind == "clouds":
				s += _t * (4.0 + bl.k * 60.0)
			var m := fposmod(s, bl.W)
			bl.position.x = cam_x - m
		else:
			bl.position.x = cam_x
	for i in _stars.size():
		(_stars[i] as BGLayer).modulate.a = 0.55 + 0.45 * sin(_t * (1.3 + i * 0.7) + i * 2.0)
	_moon_glow.modulate.a = 0.85 + 0.15 * sin(_t * 0.7)
	_rays.modulate.a = 0.7 + 0.3 * sin(_t * 0.45 + 1.0)
	_rays.position.x = cam_x + sin(_t * 0.2) * 8.0
	if _aurora.visible:
		_aurora.position.x = cam_x + sin(_t * 0.25) * 22.0
		_aurora.modulate.a = 0.6 + 0.4 * sin(_t * 0.6)
	for ll in _lantern_layers:
		(ll as BGLayer).modulate.a = 0.9 + 0.1 * sin(_t * 3.0 + (1.0 if (ll as BGLayer).glow_pass else 0.0))
	if _bolt.visible:
		_bolt_t -= delta
		_bolt.position.x = cam_x
		if _bolt_t <= 0.0:
			_bolt.visible = false
	_sky_flash.position = Vector2(cam_x - 350, -6)
	_sky_flash.color.a = move_toward(_sky_flash.color.a, 0.0, delta * 1.6)


func lightning(x_screen: float) -> void:
	var pts := PackedVector2Array()
	var x := x_screen - 320.0
	var y := -4.0
	pts.append(Vector2(x, y))
	while y < 190.0:
		y += 10.0 + randf() * 14.0
		x += (randf() - 0.5) * 26.0
		pts.append(Vector2(x, y))
	_bolt.points = pts
	_bolt.visible = true
	_bolt_t = 0.22
	_sky_flash.color.a = 0.55
