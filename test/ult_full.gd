extends Node
# Jalankan ultimate Maou real-time (tanpa lompat waktu) sampai selesai dan laporkan.
var main: Node
var world: World
var frames := 0
var ended := false
func _ready() -> void:
	if not GameState.owned.has("maou"):
		GameState.owned.append("maou")
	GameState.selected = "maou"
	main = load("res://scenes/main.tscn").instantiate()
	add_child(main)
func _process(_d: float) -> void:
	frames += 1
	if frames == 20:
		world = main.world
		world.run_ended.connect(func(): ended = true; print("run_ended fired at elapsed ", snappedf(world.player.ultimate_elapsed, 0.1)))
		world.start(false)
		world.player.ult_cd = 0.0
		world.player.start_ultimate()
		print("start")
	if frames > 20 and world.player.ultimate_active and world.player.ultimate_elapsed < 70.4:
		world.player.ultimate_elapsed += 0.12
		world.ultimate_elapsed += 0.12
	if frames > 20 and frames % 120 == 0:
		print("t=", snappedf(world.player.ultimate_elapsed, 0.1), " active=", world.player.ultimate_active)
	if frames > 20 and not world.player.ultimate_active and frames > 40:
		print("finished active=false ended=", ended, " frames=", frames)
		get_tree().quit()
