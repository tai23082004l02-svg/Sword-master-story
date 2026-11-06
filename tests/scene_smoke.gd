extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	assert(scene.screen == "title")
	scene.begin()
	await process_frame
	scene.toggle_pause()
	assert(scene.battle.state == "paused")
	await process_frame
	scene.resume()
	await process_frame
	scene.use_skill()
	assert(scene.battle.cooldown > 0)
	scene.to_title()
	await process_frame
	assert(scene.battle.state == "idle")
	scene.begin()
	await process_frame
	assert(scene.battle.wave == 1)
	print("PASS: scene title, begin, pause, resume, skill, title, restart")
	for voice in scene.audio.voices:
		voice.stop()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	quit()
