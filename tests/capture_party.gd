extends SceneTree
## Capture actual rendered frames; requires a display, not --headless.
func _initialize() -> void:
	call_deferred("run")
func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path) == OK)
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.show_character()
	for i in range(1, 5):
		scene.select_character(i)
		scene.preview_clip = "skill"
		for frame in range(12):
			await process_frame
		await capture("res://docs/screenshots/%s_viewer.png" % scene.PartyData.HEROES[i].id)
	scene.to_title()
	await process_frame
	scene.begin()
	for frame in range(300):
		if frame == 200:
			for i in range(5):
				scene.use_party_skill(i)
		await process_frame
		if frame == 208:
			await capture("res://docs/screenshots/party_battle.png")
	scene.toggle_pause()
	for voice in scene.audio.voices:
		voice.stop()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	quit()
