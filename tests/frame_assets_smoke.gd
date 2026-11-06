extends SceneTree
const Frames = preload("res://game/sprite_frames.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for id in Frames.BANKS:
		var bank: SpriteFrames = Frames.BANKS[id]
		assert(bank.get_frame_count("frames") == 24)
		var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/frames/%s/manifest.json" % id))
		for i in range(24):
			var texture := Frames.texture(id, i)
			assert(texture.resource_path == "res://assets/frames/%s/%02d.png" % [id, i])
			assert(not texture is AtlasTexture, "Each pose must own an independent image")
			var image := texture.get_image()
			var box := image.get_used_rect()
			assert(box.has_area() and box.position.x >= 8 and box.position.y >= 8)
			assert(box.end.x <= image.get_width() - 8 and box.end.y <= image.get_height() - 8)
			var offset := Frames.offset(id, i)
			assert(offset == Vector2(manifest.frames[i].draw_offset[0], manifest.frames[i].draw_offset[1]))
	# The raised Lyra bows and boss halo extend above the old row boundary.
	assert(Frames.offset("lyra", 14).y + 224 + 8 < 0)
	assert(Frames.offset("eclipse", 19).y + 224 + 8 < 0)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.show_character()
	for id in range(5):
		scene.select_character(id)
		for clip in scene.hero_art.CLIPS:
			scene.preview_clip = clip
			await process_frame
			var start: int = scene.hero_art.CLIPS[clip][0]
			var count: int = scene.hero_art.CLIPS[clip][1]
			for i in range(count):
				scene.preview_step = i
				await process_frame
				assert(scene.active_preview().frame_index() == start + i)
			var clock: float = scene.active_preview().clock
			await process_frame
			assert(scene.active_preview().clock == clock)
			scene.step_preview(1)
			await process_frame
			assert(scene.active_preview().frame_index() == start)
	for voice in scene.audio.voices: voice.stop()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	print("PASS: 168 standalone textures, transparent margins, offsets, cross-row bows/halo and manual frame stepping")
	quit()
