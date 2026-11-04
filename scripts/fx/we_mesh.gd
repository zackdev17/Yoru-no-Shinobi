class_name WEMesh
extends RefCounted

const SECTORS := 22
const RINGS := 10
const R0 := 15.0
const GROWTH := 1.5


static func idx(i: int, j: int) -> int:
	return posmod(i, SECTORS) * (RINGS + 1) + j


static func build(seed_val: int = 7) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var v := PackedVector2Array()
	v.resize(SECTORS * (RINGS + 1))
	var step := TAU / float(SECTORS)
	for i in SECTORS:
		for j in RINGS + 1:
			if j == 0:
				v[idx(i, 0)] = Vector2.ZERO
				continue
			var r := R0 * pow(GROWTH, float(j - 1)) * rng.randf_range(0.86, 1.14)
			var a := float(i) * step + rng.randf_range(-0.34, 0.34) * step
			v[idx(i, j)] = Vector2(cos(a), sin(a)) * r
	return v


static func shards(v: PackedVector2Array) -> Array:
	var out: Array = []
	for i in SECTORS:
		for j in range(1, RINGS + 1):
			var pts := PackedVector2Array()
			if j == 1:
				pts = PackedVector2Array([Vector2.ZERO, v[idx(i, 1)], v[idx(i + 1, 1)]])
			else:
				pts = PackedVector2Array([v[idx(i, j - 1)], v[idx(i, j)], v[idx(i + 1, j)], v[idx(i + 1, j - 1)]])
			var c := Vector2.ZERO
			for q in pts:
				c += q
			c /= float(pts.size())
			out.append({"pts": pts, "c": c, "d": c.length()})
	return out
