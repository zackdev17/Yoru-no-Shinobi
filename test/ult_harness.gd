extends Node
# Harness uji: jalankan WORLD END Maou dan simpan screenshot pada waktu tertentu.
# Pakai:  ULT_TIMES="5,12,20" godot --path . res://test/ult_harness.tscn
var main: Node
var world: World
var times: Array = []
var idx := 0
var phase := "boot"
var frames := 0
var outdir := "/home/claude/shots"


func _ready() -> void:
	var tv := OS.get_environment("ULT_TIMES")
	for s in tv.split(",", false):
		times.append(float(s))
	DirAccess.make_dir_recursive_absolute(outdir)
	if not GameState.owned.has("maou"):
		GameState.owned.append("maou")
	GameState.selected = "maou"
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)


func _process(_d: float) -> void:
	frames += 1
	if phase == "boot":
		if frames == 20:
			world = main.world
			world.start(false)
			world.player.ult_cd = 0.0
			world.player.start_ultimate()
			phase = "run"
			frames = 0
			print("ULT started len=", world.player.ult_len)
		return
	var p: Ninja = world.player
	if phase == "run":
		if idx >= times.size():
			print("DONE")
			get_tree().quit()
			return
		var target: float = times[idx]
		if p.ultimate_elapsed < target - 0.6:
			var skip := minf(0.12, target - 0.6 - p.ultimate_elapsed)
			p.ultimate_elapsed += skip
			world.ultimate_elapsed += skip
		if p.ultimate_elapsed >= target:
			var img: Image = main.vp.get_texture().get_image()
			img.save_png("%s/t_%05.1f.png" % [outdir, target])
			print("shot ", target)
			idx += 1
		if not p.ultimate_active and idx < times.size():
			print("ultimate ended early at ", p.ultimate_elapsed)
			get_tree().quit()
