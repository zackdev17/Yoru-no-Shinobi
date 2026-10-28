class_name Themes
extends RefCounted

const PX_PER_M := 30.0
const STAGE_M := 380.0
const STAGE_PX := PX_PER_M * STAGE_M

static var _list: Array = []


static func count() -> int:
	return get_list().size()


static func get_list() -> Array:
	if _list.is_empty():
		_list = _build()
	return _list


static func at(i: int) -> Dictionary:
	var l := get_list()
	return l[posmod(i, l.size())]


static func c(hex: String, a: float = 1.0) -> Color:
	var col := Color.html(hex)
	col.a = a
	return col


static func _build() -> Array:
	var out: Array = []

	out.append({
		"name": "SAKURA MOON GARDEN",
		"sky": [c("#070b24"), c("#1c1c52"), c("#6a3f86")],
		"ambient": Color(0.50, 0.52, 0.80),
		"moon": {"pos": Vector2(470, 62), "r": 22.0, "col": c("#f6f2dc"), "glow": c("#aab4ff")},
		"stars": 1.0,
		"cloud_a": c("#2b2b62"), "cloud_b": c("#8f86c9"), "cloud_n": 5,
		"fuji": [c("#2e3a78"), c("#5266b0"), c("#e4e8fa"), c("#9aa6d8")],
		"mtn_far": c("#2a2f69"), "mtn_mid": c("#1b2150"),
		"village": c("#10153a"), "window": c("#ffc66a"),
		"tree": {"kind": "sakura", "a": c("#f08cbd"), "b": c("#b64a86"), "c": c("#ffd2e8"), "trunk": c("#251630")},
		"ground": {"style": "wood", "a": c("#6a4a45"), "b": c("#3b2631"), "lip": c("#a98066")},
		"weather": "petals",
		"firefly": {"count": 7, "col": c("#fff3a0")},
		"lantern": c("#ffb25c"), "moon_light": c("#93a9ff"), "moon_energy": 0.55,
		"fog": c("#7561b8", 0.22),
		"lightning": false, "aurora": false, "castle": false, "festival": false,
		"grade": Color(1.0, 0.98, 1.06),
		"water": [c("#17285e"), c("#2f4c9a")],
	})

	out.append({
		"name": "FROZEN SHRINE",
		"sky": [c("#04112b"), c("#0c3358"), c("#2a78a0")],
		"ambient": Color(0.46, 0.62, 0.90),
		"moon": {"pos": Vector2(180, 58), "r": 20.0, "col": c("#eaffff"), "glow": c("#8fe8ff")},
		"stars": 1.3,
		"cloud_a": c("#1a4670"), "cloud_b": c("#9fe0f5"), "cloud_n": 4,
		"fuji": [c("#24608c"), c("#4a95c4"), c("#f6fdff"), c("#a8d6ee")],
		"mtn_far": c("#245a84"), "mtn_mid": c("#163e66"),
		"village": c("#0c2447"), "window": c("#ffd78a"),
		"tree": {"kind": "pine", "a": c("#1d5a5c"), "b": c("#0f3a45"), "c": c("#f4fbff"), "trunk": c("#1a2a3a")},
		"ground": {"style": "stone", "a": c("#6f87a3"), "b": c("#3a4d6b"), "lip": c("#f0f8ff")},
		"weather": "snow",
		"firefly": {"count": 0, "col": c("#bfeaff")},
		"lantern": c("#ffcf86"), "moon_light": c("#9fe4ff"), "moon_energy": 0.65,
		"fog": c("#8ec8e8", 0.20),
		"lightning": false, "aurora": true, "castle": false, "festival": false,
		"grade": Color(0.95, 1.02, 1.1),
		"water": [c("#0d3a66"), c("#2a86b8")],
	})

	out.append({
		"name": "STORM OVER THE CASTLE",
		"sky": [c("#06060f"), c("#20162f"), c("#4a2f55")],
		"ambient": Color(0.38, 0.40, 0.62),
		"moon": {"pos": Vector2(430, 70), "r": 0.0, "col": c("#d8d8f0"), "glow": c("#9a8ad8")},
		"stars": 0.0,
		"cloud_a": c("#171326"), "cloud_b": c("#5b4a86"), "cloud_n": 9,
		"fuji": [c("#2a2650"), c("#46407c"), c("#a8aad4"), c("#6c6a9c")],
		"mtn_far": c("#241d42"), "mtn_mid": c("#161230"),
		"village": c("#0b0918"), "window": c("#ff9a5a"),
		"tree": {"kind": "pine", "a": c("#16202e"), "b": c("#0d1420"), "c": c("#3a4a62"), "trunk": c("#0f1020")},
		"ground": {"style": "slate", "a": c("#464c66"), "b": c("#20233a"), "lip": c("#6d7595")},
		"weather": "rain",
		"firefly": {"count": 0, "col": c("#ffffff")},
		"lantern": c("#ff5e4d"), "moon_light": c("#8a78d8"), "moon_energy": 0.35,
		"fog": c("#4a3a78", 0.28),
		"lightning": true, "aurora": false, "castle": true, "festival": false,
		"grade": Color(0.96, 0.96, 1.08),
		"water": [c("#0a1030"), c("#262a68")],
	})

	out.append({
		"name": "CRIMSON MAPLE FESTIVAL",
		"sky": [c("#14061a"), c("#5a1b3a"), c("#d0553c")],
		"ambient": Color(0.66, 0.46, 0.58),
		"moon": {"pos": Vector2(160, 84), "r": 34.0, "col": c("#ff7a52"), "glow": c("#ff4a3a")},
		"stars": 0.6,
		"cloud_a": c("#4a1a3a"), "cloud_b": c("#ff8a5a"), "cloud_n": 5,
		"fuji": [c("#5a2656"), c("#a0406a"), c("#ffd8c8"), c("#d07080")],
		"mtn_far": c("#5a2048"), "mtn_mid": c("#3a1438"),
		"village": c("#220c2a"), "window": c("#ffb84a"),
		"tree": {"kind": "maple", "a": c("#e8541f"), "b": c("#a8201f"), "c": c("#ffb347"), "trunk": c("#2a0f1c")},
		"ground": {"style": "wood", "a": c("#6e3a30"), "b": c("#3a1a28"), "lip": c("#c0703c")},
		"weather": "leaves",
		"firefly": {"count": 8, "col": c("#ffb060")},
		"lantern": c("#ff9a3c"), "moon_light": c("#ff7a5a"), "moon_energy": 0.55,
		"fog": c("#c0405a", 0.18),
		"lightning": false, "aurora": false, "castle": false, "festival": true,
		"grade": Color(1.08, 0.97, 0.94),
		"water": [c("#3a1236"), c("#a8403c")],
	})

	out.append({
		"name": "SPIRIT BAMBOO FOREST",
		"sky": [c("#030f14"), c("#0a3a3c"), c("#17806a")],
		"ambient": Color(0.40, 0.66, 0.62),
		"moon": {"pos": Vector2(500, 56), "r": 24.0, "col": c("#d6ffe6"), "glow": c("#5affc0")},
		"stars": 0.9,
		"cloud_a": c("#0d3a3a"), "cloud_b": c("#6affc8"), "cloud_n": 4,
		"fuji": [c("#14605a"), c("#2aa088"), c("#e0fff4"), c("#86dcc0")],
		"mtn_far": c("#0f4a48"), "mtn_mid": c("#082e30"),
		"village": c("#06201f"), "window": c("#8affc8"),
		"tree": {"kind": "bamboo", "a": c("#2f9a5a"), "b": c("#1a6a45"), "c": c("#7affa8"), "trunk": c("#13503a")},
		"ground": {"style": "bamboo", "a": c("#3a7a48"), "b": c("#16382a"), "lip": c("#5aa858")},
		"weather": "spirits",
		"firefly": {"count": 12, "col": c("#8affc0")},
		"lantern": c("#78ffb4"), "moon_light": c("#6affc8"), "moon_energy": 0.6,
		"fog": c("#2aa890", 0.26),
		"lightning": false, "aurora": true, "castle": false, "festival": false,
		"grade": Color(0.94, 1.08, 1.0),
		"water": [c("#04282c"), c("#1a8a78")],
	})


	out.append({
		"name": "SUNLIT HANAMI HILLS",
		"day": true, "sun": true, "lamp": 0.15, "glow_thr": 0.97, "glow_int": 0.4, "vig": 0.55,
		"sky": [c("#4f9ee8"), c("#86c6f6"), c("#e4f4ff")],
		"ambient": Color(0.90, 0.92, 0.98),
		"moon": {"pos": Vector2(470, 56), "r": 26.0, "col": c("#fffbe0"), "glow": c("#ffe9a0")},
		"stars": 0.0,
		"cloud_a": c("#f2f8ff"), "cloud_b": c("#ffffff"), "cloud_n": 6,
		"fuji": [c("#5b7fb8"), c("#8aa8d8"), c("#ffffff"), c("#d6e4f8")],
		"mtn_far": c("#8fb4e0"), "mtn_mid": c("#6f9fd0"),
		"village": c("#4f7a5a"), "window": c("#3a4a6a"), "wall": c("#f4ecda"), "roof": c("#b0584a"),
		"tree": {"kind": "sakura", "a": c("#ffb0d0"), "b": c("#e478a8"), "c": c("#fff0f6"), "trunk": c("#5a3a3a")},
		"ground": {"style": "grass", "a": c("#8a6a44"), "b": c("#5a4030"), "lip": c("#5cc050")},
		"weather": "petals",
		"firefly": {"count": 0, "col": c("#fff3a0")},
		"lantern": c("#ffd49a"), "moon_light": c("#fff2d0"), "moon_energy": 0.30,
		"fog": c("#c8e4ff", 0.16),
		"lightning": false, "aurora": false, "castle": false, "festival": false,
		"grade": Color(1.05, 1.03, 1.0),
		"water": [c("#3a8ad0"), c("#7ac8f0")],
	})

	out.append({
		"name": "GOLDEN RICE TERRACES",
		"day": true, "sun": true, "lamp": 0.2, "glow_thr": 0.97, "glow_int": 0.45, "vig": 0.6,
		"sky": [c("#5f9be0"), c("#ffd08a"), c("#fff1c8")],
		"ambient": Color(0.98, 0.90, 0.80),
		"moon": {"pos": Vector2(160, 92), "r": 32.0, "col": c("#fff6d0"), "glow": c("#ffc860")},
		"stars": 0.0,
		"cloud_a": c("#ffe9c8"), "cloud_b": c("#fffaf0"), "cloud_n": 5,
		"fuji": [c("#6a7aa0"), c("#98a8c8"), c("#fff6e8"), c("#e8d0c0")],
		"mtn_far": c("#b0a8c0"), "mtn_mid": c("#7e9a90"),
		"village": c("#5a7a3a"), "window": c("#4a3a2a"), "wall": c("#f0e0c0"), "roof": c("#7a5a3a"),
		"tree": {"kind": "maple", "a": c("#f0c030"), "b": c("#c88a18"), "c": c("#fff0a0"), "trunk": c("#4a3220")},
		"ground": {"style": "grass", "a": c("#8a6a30"), "b": c("#5a4020"), "lip": c("#9ad040")},
		"weather": "pollen", "pollen": c("#fff0a0", 0.85),
		"firefly": {"count": 0, "col": c("#ffe080")},
		"lantern": c("#ffd080"), "moon_light": c("#ffe0a0"), "moon_energy": 0.34,
		"fog": c("#ffe0a0", 0.20),
		"lightning": false, "aurora": false, "castle": false, "festival": false,
		"grade": Color(1.06, 1.0, 0.94),
		"water": [c("#6a9a40"), c("#c8d860")],
	})

	out.append({
		"name": "SILVER SNOW PEAKS",
		"day": true, "sun": true, "lamp": 0.15, "glow_thr": 0.98, "glow_int": 0.4, "vig": 0.5,
		"sky": [c("#3a86d8"), c("#78bcf0"), c("#d8f0ff")],
		"ambient": Color(0.88, 0.93, 1.0),
		"moon": {"pos": Vector2(300, 50), "r": 22.0, "col": c("#ffffff"), "glow": c("#cfeaff")},
		"stars": 0.0,
		"cloud_a": c("#e8f2fc"), "cloud_b": c("#ffffff"), "cloud_n": 5,
		"fuji": [c("#6a90c0"), c("#a8c8e8"), c("#ffffff"), c("#c8dcf4")],
		"mtn_far": c("#98b8dc"), "mtn_mid": c("#7aa0cc"),
		"village": c("#5a7088"), "window": c("#3a4a6a"), "wall": c("#dfe8f0"), "roof": c("#5a6a8a"),
		"tree": {"kind": "pine", "a": c("#2a6a58"), "b": c("#1a4a44"), "c": c("#ffffff"), "trunk": c("#3a2a22")},
		"ground": {"style": "stone", "a": c("#8aa0b8"), "b": c("#5a7090"), "lip": c("#ffffff")},
		"weather": "snow",
		"firefly": {"count": 0, "col": c("#bfeaff")},
		"lantern": c("#ffe0a0"), "moon_light": c("#e8f4ff"), "moon_energy": 0.30,
		"fog": c("#e0f0ff", 0.22),
		"lightning": false, "aurora": false, "castle": false, "festival": false,
		"grade": Color(0.98, 1.02, 1.06),
		"water": [c("#2a7ab8"), c("#8ae0f8")],
	})

	out.append({
		"name": "AZURE SEASIDE VILLAGE",
		"day": true, "sun": true, "lamp": 0.15, "glow_thr": 0.97, "glow_int": 0.4, "vig": 0.5,
		"sky": [c("#2a9cf0"), c("#6ccaf8"), c("#c8f2ff")],
		"ambient": Color(0.96, 0.94, 0.90),
		"moon": {"pos": Vector2(520, 50), "r": 26.0, "col": c("#fffbe6"), "glow": c("#fff0a0")},
		"stars": 0.0,
		"cloud_a": c("#f4faff"), "cloud_b": c("#ffffff"), "cloud_n": 6,
		"fuji": [c("#5a8ab8"), c("#8ab4dc"), c("#ffffff"), c("#dce8f8")],
		"mtn_far": c("#7ab0d8"), "mtn_mid": c("#5898c0"),
		"village": c("#3a6a58"), "window": c("#2a4a6a"), "wall": c("#f8f0e0"), "roof": c("#2a8ab0"),
		"tree": {"kind": "pine", "a": c("#3a9a5a"), "b": c("#1f6a44"), "c": c("#8aea8a"), "trunk": c("#5a3a28")},
		"ground": {"style": "wood", "a": c("#b08a5a"), "b": c("#6a4a30"), "lip": c("#e8c890")},
		"weather": "pollen", "pollen": c("#ffffff", 0.8),
		"firefly": {"count": 0, "col": c("#ffffff")},
		"lantern": c("#ffe0a0"), "moon_light": c("#fff4dc"), "moon_energy": 0.30,
		"fog": c("#d8f4ff", 0.16),
		"lightning": false, "aurora": false, "castle": false, "festival": false,
		"grade": Color(1.04, 1.02, 0.98),
		"water": [c("#0a6ab8"), c("#3ad0e8")],
	})

	out.append({
		"name": "TWILIGHT LOTUS LAKE",
		"sun": true, "lamp": 1.0,
		"sky": [c("#1c1050"), c("#a0407a"), c("#ffa060")],
		"ambient": Color(0.72, 0.60, 0.78),
		"moon": {"pos": Vector2(250, 150), "r": 40.0, "col": c("#ffd0a0"), "glow": c("#ff7a60")},
		"stars": 0.5,
		"cloud_a": c("#6a2a6a"), "cloud_b": c("#ffa070"), "cloud_n": 5,
		"fuji": [c("#4a2a6a"), c("#8a4a8a"), c("#ffd0c0"), c("#e08a90")],
		"mtn_far": c("#5a2a6a"), "mtn_mid": c("#3a1a52"),
		"village": c("#1c1030"), "window": c("#ffc06a"),
		"tree": {"kind": "sakura", "a": c("#d070c0"), "b": c("#8a3a90"), "c": c("#ffc0e0"), "trunk": c("#2a1430")},
		"ground": {"style": "wood", "a": c("#5a3a58"), "b": c("#2e1c3a"), "lip": c("#c07890")},
		"weather": "spirits",
		"firefly": {"count": 10, "col": c("#ffd890")},
		"lantern": c("#ff9a6a"), "moon_light": c("#ff9a80"), "moon_energy": 0.50,
		"fog": c("#c05a90", 0.22),
		"lightning": false, "aurora": false, "castle": false, "festival": false,
		"grade": Color(1.06, 0.97, 1.02),
		"water": [c("#2a1050"), c("#d0508a")],
	})

	out.append({
		"name": "EMBER VOLCANO FORGE",
		"lamp": 1.0,
		"sky": [c("#0a0305"), c("#3a0c10"), c("#b0301a")],
		"ambient": Color(0.62, 0.42, 0.38),
		"moon": {"pos": Vector2(400, 70), "r": 30.0, "col": c("#ff5a2a"), "glow": c("#ff3010")},
		"stars": 0.3,
		"cloud_a": c("#2a0a0c"), "cloud_b": c("#c04a22"), "cloud_n": 6,
		"fuji": [c("#2a1010"), c("#5a1c14"), c("#ff9a30"), c("#d04a14")],
		"mtn_far": c("#3a1212"), "mtn_mid": c("#240a0a"),
		"village": c("#140606"), "window": c("#ff8a2a"),
		"tree": {"kind": "pine", "a": c("#3a1a14"), "b": c("#1a0a0a"), "c": c("#ff7a20"), "trunk": c("#1a0808")},
		"ground": {"style": "magma", "a": c("#4a3036"), "b": c("#1e1216"), "lip": c("#7a5048")},
		"weather": "embers",
		"firefly": {"count": 6, "col": c("#ff8a30")},
		"lantern": c("#ff7a2a"), "moon_light": c("#ff6a3a"), "moon_energy": 0.50,
		"fog": c("#d03a1a", 0.25),
		"lightning": false, "aurora": false, "castle": true, "festival": false,
		"grade": Color(1.1, 0.95, 0.9),
		"water": [c("#3a0a06"), c("#ff6a1a")],
	})

	var order := [0, 5, 1, 6, 2, 7, 3, 8, 4, 9, 10]
	var res: Array = []
	for i in order:
		res.append(out[i])
	return res
