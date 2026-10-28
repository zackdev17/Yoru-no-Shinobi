class_name Characters
extends RefCounted

const SHURIKEN_RECHARGE := 3.0
const ULTI_START_FRACTION := 0.35
const ID_ORDER := ["kage", "hayate", "honoo", "kori", "kakuou", "maou"]

static var DATA := {
	"kage": {
		"name": "KAGE", "title": "SHADOW NINJA", "price": 0,
		"desc": "Balanced ninja of the night. Kills with shadows and thunder.",
		"run_style": "classic", "run_name": "SILENT RUN",
		"speed": 1.0, "jump": 1.0, "gravity": 1.0,
		"pal": {
			"navy": Color("#3a4690"), "navy_l": Color("#5666b8"), "wrap": Color("#cfd4ea"),
			"red": Color("#d8323e"), "skin": Color("#e2b48e"), "eye": Color(1.8, 2.0, 2.2),
			"glow": Color("#7aa8ff"), "trail": Color(0.4, 0.9, 1.0, 0.55), "dust": Color(0.8, 0.8, 0.95),
		},
		"skills": {
			"dash": {"name": "KAGE DASH", "kind": "shadow", "cd": 3.2, "step": 0.4, "min": 0.8,
				"time": 0.24, "speed": 3.0, "touch": "DASH", "info": "Invincible dash that slashes"},
			"special": {"name": "SHADOW X", "kind": "shadow", "cd": 4.2, "step": 0.4, "min": 1.0,
				"touch": "SHADOW X", "info": "Teleport-slash up to 3 foes"},
			"ultimate": {"name": "THUNDER JUDGEMENT", "kind": "thunder", "cd": 28.0, "step": 2.5, "min": 10.0,
				"touch": "ULTI", "info": "Lightning wipes the whole screen"},
		},
		"unique": {"name": "CLONE ARTS", "desc": "+1 Shadow X target", "max": 3, "base": 260},
	},
	"hayate": {
		"name": "HAYATE", "title": "WIND RUNNER", "price": 900,
		"desc": "Fast and light. Refreshes jumps in the air and cuts with wind.",
		"run_style": "sprint", "run_name": "WIND SPRINT",
		"speed": 1.07, "jump": 1.04, "gravity": 0.95,
		"pal": {
			"navy": Color("#2f7a62"), "navy_l": Color("#4fb08a"), "wrap": Color("#e8f4dc"),
			"red": Color("#ffd23a"), "skin": Color("#e8c09a"), "eye": Color(1.0, 2.3, 1.3),
			"glow": Color("#7affc0"), "trail": Color(0.5, 1.0, 0.7, 0.55), "dust": Color(0.75, 0.95, 0.85),
		},
		"skills": {
			"dash": {"name": "WIND DASH", "kind": "gale", "cd": 2.6, "step": 0.3, "min": 0.8,
				"time": 0.30, "speed": 3.5, "touch": "AIR DASH", "info": "Long dash, refills double jump"},
			"special": {"name": "GALE SLASH", "kind": "gale", "cd": 5.5, "step": 0.5, "min": 1.5,
				"touch": "GALE", "info": "Piercing wind wave forward"},
			"ultimate": {"name": "STORM RUSH", "kind": "storm", "cd": 26.0, "step": 2.5, "min": 9.0,
				"len": 4.4, "zoom": 2.0, "touch": "ULTI", "info": "Giant tornado rush that smashes everything"},
		},
		"unique": {"name": "WIND RANGE", "desc": "+25% Gale Slash range", "max": 4, "base": 220},
	},
	"honoo": {
		"name": "HONOO", "title": "FLAME BRAWLER", "price": 1800,
		"desc": "Heavy hitter. Burns everything close and rains meteors.",
		"run_style": "stomp", "run_name": "FLAME STOMP",
		"speed": 1.0, "jump": 1.07, "gravity": 1.05,
		"pal": {
			"navy": Color("#8a2a2a"), "navy_l": Color("#c4503a"), "wrap": Color("#f2d8a8"),
			"red": Color("#ff9a2a"), "skin": Color("#e2a47e"), "eye": Color(2.4, 1.4, 0.5),
			"glow": Color("#ff8a4a"), "trail": Color(1.0, 0.55, 0.2, 0.55), "dust": Color(1.0, 0.7, 0.4),
		},
		"skills": {
			"dash": {"name": "FLARE DASH", "kind": "fire", "cd": 3.4, "step": 0.4, "min": 1.0,
				"time": 0.26, "speed": 3.0, "touch": "FLARE", "info": "Burning dash, hits nearby foes"},
			"special": {"name": "FIREBALL", "kind": "fireball", "cd": 5.0, "step": 0.5, "min": 1.5,
				"touch": "FIRE", "info": "Shoots blazing fireballs that explode"},
			"ultimate": {"name": "METEOR RAIN", "kind": "meteor", "cd": 30.0, "step": 3.0, "min": 10.0,
				"len": 4.8, "zoom": 1.8, "touch": "ULTI", "info": "Meteor storm + giant meteor finale"},
		},
		"unique": {"name": "EMBER CORE", "desc": "+15% blast, more fireballs", "max": 4, "base": 240},
	},
	"kori": {
		"name": "KORI", "title": "FROST MAIDEN", "price": 2800,
		"desc": "Cool and graceful. Freezes foes so they shatter on touch.",
		"run_style": "skate", "run_name": "ICE SKATE",
		"speed": 1.03, "jump": 1.0, "gravity": 0.97,
		"pal": {
			"navy": Color("#3a6aa8"), "navy_l": Color("#6aa4dc"), "wrap": Color("#eaf6ff"),
			"red": Color("#9a6aff"), "skin": Color("#efd2c0"), "eye": Color(1.3, 2.1, 2.5),
			"glow": Color("#8adcff"), "trail": Color(0.6, 0.9, 1.0, 0.6), "dust": Color(0.85, 0.95, 1.0),
		},
		"skills": {
			"dash": {"name": "ICE SLIDE", "kind": "ice", "cd": 3.6, "step": 0.4, "min": 1.0,
				"time": 0.28, "speed": 3.0, "touch": "ICE", "info": "Dash that freezes foes ahead"},
			"special": {"name": "FROST NOVA", "kind": "frost_nova", "cd": 7.0, "step": 0.6, "min": 2.0,
				"touch": "FROST", "info": "Freezes foes around you"},
			"ultimate": {"name": "ABSOLUTE ZERO", "kind": "blizzard", "cd": 30.0, "step": 3.0, "min": 10.0,
				"len": 4.4, "zoom": 2.0, "touch": "ULTI", "info": "Freezes the world, then shatters it"},
		},
		"unique": {"name": "FROST HEART", "desc": "+0.6s freeze duration", "max": 4, "base": 240},
	},
	"kakuou": {
		"name": "KAKUOU", "title": "ATOMIC OVERLORD", "price": 20000, "tier": "S-CLASS",
		"desc": "A walking reactor. Radiation burns all near him, and one nuke ends the night.",
		"run_style": "titan", "run_name": "TITAN MARCH", "extras": "overlord",
		"speed": 1.12, "jump": 1.10, "gravity": 0.95,
		"bonus_hearts": 2, "start_shield": true, "passive": "radiation", "passive_radius": 70.0,
		"cost_mult": 3,
		"pal": {
			"navy": Color("#1a1620"), "navy_l": Color("#3d2a48"), "wrap": Color("#7a2a2a"),
			"red": Color("#ff4a1a"), "skin": Color("#cdb4a0"), "eye": Color(2.8, 0.35, 0.2),
			"glow": Color("#9aff3a"), "trail": Color(0.65, 1.0, 0.2, 0.65), "dust": Color(0.7, 1.0, 0.4),
		},
		"skills": {
			"dash": {"name": "PLASMA DASH", "kind": "plasma", "cd": 2.2, "step": 0.25, "min": 0.6,
				"time": 0.34, "speed": 4.0, "touch": "PLASMA", "info": "Long plasma dash, vaporizes foes"},
			"special": {"name": "NUKE BLAST", "kind": "nuke_blast", "cd": 4.0, "step": 0.4, "min": 1.2,
				"touch": "NUKE", "info": "Huge blast that wipes nearby foes"},
			"ultimate": {"name": "ZERO HOUR", "kind": "nuke", "cd": 24.0, "step": 2.5, "min": 8.0,
				"len": 5.6, "zoom": 1.5, "touch": "ULTI", "info": "Countdown, then a nuke erases everything"},
		},
		"unique": {"name": "FISSION CORE", "desc": "+12% nuke radius", "max": 5, "base": 900},
	},
	"maou": {
		"name": "MAOU", "title": "ECLIPSE DEMON LORD", "price": 50000, "tier": "SS-CLASS",
		"desc": "Lord of dusk and dawn. Darkness and holy light kneel to him. One gaze ends the world.",
		"run_style": "titan", "run_name": "SOVEREIGN MARCH", "extras": "demonlord",
		"speed": 1.15, "jump": 1.12, "gravity": 0.92,
		"bonus_hearts": 3, "start_shield": true, "passive": "eclipse", "passive_radius": 96.0,
		"cost_mult": 4, "ult_start": 0.5,
		"pal": {
			"navy": Color("#120a20"), "navy_l": Color("#3a2060"), "wrap": Color("#f0d890"),
			"red": Color("#ffc83a"), "skin": Color("#cbb6d0"), "eye": Color(3.2, 2.3, 0.5),
			"glow": Color("#c79bff"), "trail": Color(0.78, 0.5, 1.0, 0.65), "dust": Color(1.0, 0.85, 0.5),
		},
		"skills": {
			"dash": {"name": "ECLIPSE STEP", "kind": "eclipse", "cd": 2.0, "step": 0.2, "min": 0.5,
				"time": 0.34, "speed": 4.2, "touch": "ECLIPSE", "info": "Phase dash, annihilates everything in its path"},
			"special": {"name": "TWILIGHT JUDGEMENT", "kind": "judgement", "cd": 3.5, "step": 0.35, "min": 1.0,
				"touch": "JUDGE", "info": "Pillars of light and darkness erase foes ahead"},
			"ultimate": {"name": "WORLD END", "kind": "worldend", "cd": 120.0, "step": 10.0, "min": 60.0,
				"len": 16.4, "zoom": 1.6, "touch": "ULTI", "info": "The Demon Lord's gaze ends the world. The run ends and every coin is sealed in your vault"},
		},
		"unique": {"name": "ECLIPSE CORE", "desc": "+15% Judgement reach", "max": 5, "base": 1500},
	},
}


static func get_def(id: String) -> Dictionary:
	if DATA.has(id):
		return DATA[id]
	return DATA["kage"]


static func skill_cd(id: String, slot: String, level: int) -> float:
	var s: Dictionary = get_def(id)["skills"][slot]
	return maxf(float(s["min"]), float(s["cd"]) - float(s["step"]) * float(level))
