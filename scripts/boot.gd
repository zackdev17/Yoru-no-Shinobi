extends Control

const TIPS := [
	"Tip: Double jump lets you cross the widest gaps.",
	"Tip: Slide under crows - or knock them down with a shuriken.",
	"Tip: Stomp oni from above. Never stomp a wisp - it burns!",
	"Tip: Jump on a taiko drum for a super bounce.",
	"Tip: Kage Dash makes you invincible and slices through enemies.",
	"Tip: Magnet pulls every nearby coin right to you!",
	"Tip: Lightning strike warnings glow red on the ground - move!",
	"Tip: Chain coins quickly to build a COMBO multiplier.",
]

var thread: Thread
var sfx_thread: Thread
const MAOU_SFX := ["skill_dash_eclipse", "skill_special_judgement", "skill_impact_judgement", "ult_charge_worldend",
	"ult_maou_eye", "ult_maou_pillar", "ult_maou_sword", "ult_maou_quake", "ult_maou_impact", "ult_maou_crack",
	"ult_maou_shatter", "ult_maou_suck", "ult_maou_end", "ult_maou_voice", "ult_maou_bgm", "ult_maou_bgm2"]
var tasks: Array = []
var done_tasks := 0
var progress := 0.0
var tip := ""
var t := 0.0
var finished := false
var started_change := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	tip = TIPS[randi() % TIPS.size()]
	sfx_thread = Thread.new()
	sfx_thread.start(_preload_maou_sfx)
	if not Assets.music_ready():
		thread = Thread.new()
		thread.start(Assets.build_music)
	for i in Themes.count():
		tasks.append(i)


func _preload_maou_sfx() -> void:
	for n in MAOU_SFX:
		Assets.sfx(n)


func _process(delta: float) -> void:
	t += delta
	if not tasks.is_empty():
		var i: int = tasks.pop_front()
		TexGen.ground_tex(i)
		done_tasks += 1
	var tex_p := float(done_tasks) / maxf(1.0, float(Themes.count()))
	var mus_p := 1.0 if Assets.music_ready() else Assets.music_progress * 0.98
	var target := tex_p * 0.3 + mus_p * 0.7
	progress = lerpf(progress, target, minf(1.0, delta * 6.0))
	queue_redraw()
	if tasks.is_empty() and Assets.music_ready() and progress > 0.985 and not started_change:
		started_change = true
		if thread:
			thread.wait_to_finish()
		if sfx_thread:
			sfx_thread.wait_to_finish()
		for n in ["jump", "djump", "coin", "hit", "powerup", "throw", "kill", "slide", "land", "dash", "stage", "gameover", "click", "thunder", "splash", "heart", "zap", "shield", "warn", "ult_lightning", "ult_tornado", "ult_fire", "ult_ice", "ult_reactor"]:
			Assets.sfx(n)
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func _draw() -> void:
	var sz := size
	var bands := 36
	for i in bands:
		var u := float(i) / (bands - 1)
		var c := Color("#0b1233").lerp(Color("#5a3a86"), pow(u, 1.5))
		draw_rect(Rect2(0, u * sz.y, sz.x, sz.y / bands + 1), c)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 90:
		var a := 0.4 + 0.6 * absf(sin(t * (0.8 + rng.randf() * 1.5) + i))
		draw_rect(Rect2(rng.randf() * sz.x, rng.randf() * sz.y * 0.6, 2, 2), Color(1, 1, 1, a))
	var mc := Vector2(sz.x * 0.74, sz.y * 0.26)
	for i in 10:
		draw_circle(mc, 50.0 + i * 16.0, Color(0.65, 0.7, 1.0, 0.03))
	draw_circle(mc, 46.0, Color("#f6f2dc"))
	var pts := PackedVector2Array()
	pts.append(Vector2(0, sz.y))
	var x := 0.0
	while x <= sz.x + 20.0:
		pts.append(Vector2(x, sz.y * 0.72 - 50.0 * sin(x * 0.006) - 26.0 * sin(x * 0.017 + 1.0)))
		x += 20.0
	pts.append(Vector2(sz.x, sz.y))
	SafeDraw.poly(self, pts, Color("#10153a"))
	var f := ThemeDB.fallback_font
	var title := "YORU NO SHINOBI"
	var tw := f.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 68).x
	draw_string(f, Vector2((sz.x - tw) * 0.5, sz.y * 0.38), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 68, Color("#ffd86a"))
	var sub := "ENDLESS NINJA RUN"
	var sw := f.get_string_size(sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 22).x
	draw_string(f, Vector2((sz.x - sw) * 0.5, sz.y * 0.38 + 36), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color(0.85, 0.9, 1.0, 0.9))
	var bw := 520.0
	var bx := (sz.x - bw) * 0.5
	var by := sz.y * 0.58
	draw_style_box(UITheme.box(Color(0.05, 0.05, 0.14, 0.85), Color(0.5, 0.45, 0.75, 0.9), 2, 12, 0), Rect2(bx, by, bw, 24))
	draw_style_box(UITheme.box(Color("#ffb838"), Color(0, 0, 0, 0), 0, 9, 0), Rect2(bx + 4, by + 4, maxf(14.0, (bw - 8.0) * progress), 16))
	var pct := "%d%%" % int(progress * 100.0)
	var pw := f.get_string_size(pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	draw_string(f, Vector2(bx + (bw - pw) * 0.5, by + 18), pct, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	var tipw := f.get_string_size(tip, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(f, Vector2((sz.x - tipw) * 0.5, by + 58), tip, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.9, 0.92, 1.0, 0.85))
