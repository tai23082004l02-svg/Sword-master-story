extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var image: Image = load("res://assets/hero/aether_sheet.png").get_image()
	assert(image.get_size() == Vector2i(1536, 1024))
	assert(image.get_pixel(0, 0).a < 0.01)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.show_character()
	await process_frame
	assert(scene.screen == "character" and scene.preview_buttons.size() == 15)
	for clip in scene.hero_art.CLIPS:
		scene.preview_clip = clip
		await process_frame
		assert(scene.hero_art.clip == clip)
		assert(scene.hero_art.visible)
	scene.to_title()
	await process_frame
	assert(scene.preview_buttons.is_empty())
	scene.begin()
	await process_frame
	scene.use_skill()
	await process_frame
	assert(scene.hero_art.clip == "skill")
	scene.toggle_pause()
	await process_frame
	var clock: float = scene.hero_art.clock
	await create_timer(0.1).timeout
	assert(scene.hero_art.clock == clock)
	for voice in scene.audio.voices:
		voice.stop()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	print("PASS: transparent atlas, six previews, return, combat skill, pause animation")
	quit()
