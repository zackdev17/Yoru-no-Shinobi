class_name TexGen
extends RefCounted

const GW := 64
const GH := 75

static var _cache := {}


static func _hash(x: float, y: float, s: float = 0.0) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233 + s * 37.719) * 43758.5453, 1.0)


static func light_tex(falloff: float = 1.6, size: int = 128) -> ImageTexture:
	var key := "light_%s_%d" % [str(falloff), size]
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half := size * 0.5
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - half, y + 0.5 - half).length() / half
			var v := clampf(1.0 - d, 0.0, 1.0)
			v = pow(v, falloff)
			img.set_pixel(x, y, Color(v, v, v, v))
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t


static func glow_tex(size: int = 64) -> ImageTexture:
	return light_tex(2.2, size)


static func cone_tex() -> ImageTexture:
	if _cache.has("cone"):
		return _cache["cone"]
	var w := 96
	var h := 128
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var fy := float(y) / h
			var half_w := lerpf(0.08, 0.5, fy)
			var dx: float = absf(float(x) / w - 0.5) / half_w
			var v := clampf(1.0 - dx, 0.0, 1.0) * (1.0 - fy)
			v = pow(v, 1.3)
			img.set_pixel(x, y, Color(v, v, v, v))
	var t := ImageTexture.create_from_image(img)
	_cache["cone"] = t
	return t


static func shape_tex(kind: String) -> ImageTexture:
	if _cache.has("shape_" + kind):
		return _cache["shape_" + kind]
	var pix: Array = []
	var col := Color.WHITE
	match kind:
		"petal":
			pix = ["0110", "1111", "0110"]
		"leaf":
			pix = ["00110", "01111", "11110", "01100"]
		"flake":
			pix = ["010", "111", "010"]
		"drop":
			pix = ["1", "1", "1", "1", "1", "1"]
		"spark":
			pix = ["1"]
		"dust":
			pix = ["11", "11"]
		"orb":
			pix = ["0110", "1111", "1111", "0110"]
		_:
			pix = ["1"]
	var h := pix.size()
	var w: int = (pix[0] as String).length()
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			if (pix[y] as String)[x] == "1":
				img.set_pixel(x, y, col)
	var t := ImageTexture.create_from_image(img)
	_cache["shape_" + kind] = t
	return t


static func ground_tex(stage: int) -> CanvasTexture:
	var idx := posmod(stage, Themes.count())
	var key := "ground_%d" % idx
	if _cache.has(key):
		return _cache[key]
	var t := _make_ground(Themes.at(idx))
	_cache[key] = t
	return t


static func _make_ground(theme: Dictionary) -> CanvasTexture:
	var g: Dictionary = theme["ground"]
	var style: String = g["style"]
	var ca: Color = g["a"]
	var cb: Color = g["b"]
	var lip: Color = g["lip"]
	var top := 9

	var hm := PackedFloat32Array()
	hm.resize(GW * GH)
	var cm: Array = []
	cm.resize(GW * GH)
	var spec := PackedFloat32Array()
	spec.resize(GW * GH)

	for y in GH:
		for x in GW:
			var h := 0.0
			var col := Color(0, 0, 0, 0)
			var sp := 0.0
			if y < top:
				var lump := 3.0 + 2.2 * sin(x * 0.42 + 1.3) + 1.4 * sin(x * 0.95)
				if style == "wood":
					lump = 3.0 + 0.8 * sin(x * 0.9)
				if style == "slate" or style == "magma":
					lump = 3.0
				if float(y) >= lump:
					var k := float(y) - lump
					var shade := clampf(1.0 - k * 0.12, 0.55, 1.0)
					col = lip * shade
					col.a = 1.0
					h = 1.0 - k * 0.1
					if style == "slate" or style == "magma":
						sp = 1.0 - clampf(k * 0.4, 0.0, 1.0)
					if style == "grass" and _hash(x, y, 9.0) > 0.78:
						col = lip.lightened(0.28)
					if style == "stone" and _hash(x, y, 4.0) > 0.93:
						col = Color(1, 1, 1, 1)
			else:
				var yy := y - top
				match style:
					"wood":
						var r := yy / 12
						var iy := yy % 12
						var shift := (r % 2) * 32
						var sx := (x + shift) % 64
						var grain := _hash(floorf(float(sx) * 0.18) + r * 7.0, iy * 0.7, 1.0)
						var bevel := sin(float(iy) / 12.0 * PI)
						h = 0.35 + 0.65 * bevel
						col = ca.lerp(cb, 0.25 + grain * 0.5)
						if iy == 0:
							col = cb * 0.55
							h = 0.0
						if sx == 0 or sx == 63:
							col = cb * 0.55
							h = 0.0
						if (sx == 4 or sx == 28) and iy == 5:
							col = Color("#d6b25a")
							h = 0.9
						col.a = 1.0
						sp = 0.1
					"stone":
						var r2 := yy / 14
						var iy2 := yy % 14
						var shift2 := (r2 % 2) * 16
						var sx2 := (x + shift2) % 32
						var seam := iy2 == 0 or sx2 == 0
						var edge := minf(minf(float(iy2), 13.0 - iy2), minf(float(sx2), 31.0 - sx2))
						h = clampf(edge / 3.0, 0.0, 1.0) * 0.8
						col = ca.lerp(cb, _hash(x * 0.3, yy * 0.3, r2) * 0.7)
						if seam:
							col = cb * 0.5
							h = 0.0
						if iy2 < 2 and not seam:
							col = col.lerp(Color.WHITE, 0.35)
						col.a = 1.0
						sp = 0.25
					"slate":
						var r3 := yy / 18
						var iy3 := yy % 18
						var shift3 := (r3 % 2) * 20
						var sx3 := (x + shift3) % 40
						var seam3 := iy3 == 0 or sx3 == 0
						var edge3 := minf(minf(float(iy3), 17.0 - iy3), minf(float(sx3), 39.0 - sx3))
						h = clampf(edge3 / 2.5, 0.0, 1.0) * 0.6
						col = ca.lerp(cb, _hash(x * 0.4, yy * 0.2, r3 + 3.0) * 0.8)
						if seam3:
							col = cb * 0.45
							h = 0.0
						col.a = 1.0
						sp = 0.9 if not seam3 else 0.0
					"grass":
						var gr := _hash(x * 0.37, yy * 0.31, 7.0)
						col = ca.lerp(cb, clampf(float(yy) / 40.0 + gr * 0.45, 0.0, 1.0))
						if yy < 5:
							col = col.lerp(lip, (1.0 - float(yy) / 5.0) * 0.6)
						if gr > 0.93:
							col = col.lightened(0.25)
						h = 0.3 + gr * 0.4
						col.a = 1.0
						sp = 0.0
					"magma":
						var mr := yy / 18
						var miy := yy % 18
						var mshift := (mr % 2) * 20
						var msx := (x + mshift) % 40
						var mseam := miy == 0 or msx == 0
						var medge := minf(minf(float(miy), 17.0 - miy), minf(float(msx), 39.0 - msx))
						h = clampf(medge / 2.5, 0.0, 1.0) * 0.7
						col = ca.lerp(cb, _hash(x * 0.4, yy * 0.2, mr + 5.0) * 0.8)
						if mseam:
							col = Color("#ff7a1c").lerp(Color("#ffd060"), _hash(x, yy, 2.0) * 0.5)
							h = 0.0
						col.a = 1.0
						sp = 0.6 if not mseam else 0.0
					"bamboo":
						var r4 := yy / 12
						var iy4 := yy % 12
						var cyl := sin((float(iy4) + 0.5) / 12.0 * PI)
						h = cyl
						col = ca.lerp(cb, 1.0 - cyl)
						var nodex := (x + r4 * 11) % 24
						if nodex == 0 or nodex == 1:
							col = cb * 0.7
							h = cyl * 0.6
						if nodex == 2:
							col = ca.lerp(Color.WHITE, 0.25)
							h = cyl + 0.2
						col.a = 1.0
						sp = 0.5 * cyl
					_:
						col = ca
						col.a = 1.0
			hm[y * GW + x] = h
			cm[y * GW + x] = col
			spec[y * GW + x] = sp

	var diff := Image.create(GW, GH, false, Image.FORMAT_RGBA8)
	var norm := Image.create(GW, GH, false, Image.FORMAT_RGBA8)
	var spc := Image.create(GW, GH, false, Image.FORMAT_RGBA8)
	for y in GH:
		for x in GW:
			var xm := (x - 1 + GW) % GW
			var xp := (x + 1) % GW
			var ym := maxi(y - 1, 0)
			var yp := mini(y + 1, GH - 1)
			var dx := hm[y * GW + xp] - hm[y * GW + xm]
			var dy := hm[yp * GW + x] - hm[ym * GW + x]
			var n := Vector3(-dx * 2.4, dy * 2.4, 1.0).normalized()
			norm.set_pixel(x, y, Color(n.x * 0.5 + 0.5, n.y * 0.5 + 0.5, n.z * 0.5 + 0.5, 1.0))
			diff.set_pixel(x, y, cm[y * GW + x])
			var s := spec[y * GW + x]
			spc.set_pixel(x, y, Color(s, s, s, 0.5))

	var ct := CanvasTexture.new()
	ct.diffuse_texture = ImageTexture.create_from_image(diff)
	ct.normal_texture = ImageTexture.create_from_image(norm)
	ct.specular_texture = ImageTexture.create_from_image(spc)
	ct.specular_color = Color(1.0, 0.95, 0.85)
	ct.specular_shininess = 0.5
	ct.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	return ct
