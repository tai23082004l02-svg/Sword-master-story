extends SceneTree
const Progress = preload("res://game/campaign_progress.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.progress = Progress.new("user://capture-speed-%d.json" % Time.get_ticks_usec())
	root.add_child(scene)
	await process_frame
	scene.start_campaign(1)
	scene.cycle_battle_speed()
	scene.cycle_battle_speed()
	assert(scene.battle_speed == 3)
	await create_timer(0.6).timeout
	scene.set_process(false)
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://docs/screenshots/battle_speed_x3.png") == OK)
	scene.audio.stop_all()
	scene.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("PASS: rendered x3 battle button using isolated save")
	quit()
