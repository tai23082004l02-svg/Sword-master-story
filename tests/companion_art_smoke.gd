extends SceneTree
const Art = preload("res://game/companion_art.gd")
const Party = preload("res://game/party_data.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	for i in range(1, 5):
		var actor := Party.create(i)
		var art := Art.new()
		art.configure(actor.id)
		root.add_child(art)
		var image := art.sheet.get_image()
		assert(image.get_size() == Vector2i(1536, 1024))
		assert(image.get_pixel(0, 0).a < 0.08)
		assert(not art.sword_overlays)
		art.sync(actor, 0.01, false)
		assert(art.clip == "idle")
		actor.x += 10
		art.sync(actor, 0.01, false)
		assert(art.clip == "run")
		actor.windup = 0.12
		art.sync(actor, 0.01, false)
		assert(art.clip == "attack")
		actor.visual = 0.4
		art.sync(actor, 0.01, false)
		assert(art.clip == "skill")
		actor.visual = 0
		actor.hp -= 5
		art.sync(actor, 0.01, false)
		assert(art.clip == "hurt")
		var clock: float = art.clock
		art.sync(actor, 1, true)
		await process_frame
		assert(art.clock == clock, "Pause freezes companion clock")
		actor.hp = 0
		art.sync(actor, 0.01, false, true)
		assert(art.clip == "death", "Last defeated hero must animate even in terminal state")
		art.sync(actor, 1, false, true)
		assert(art.clock > 0.7)
		art.configure(actor.id)
		actor = Party.create(i)
		art.sync(actor, 0.01, false)
		assert(art.clip == "idle" and art.hurt_left == 0)
		art.queue_free()
		await process_frame
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.show_character()
	for i in range(5):
		scene.select_character(i)
		for clip in scene.hero_art.CLIPS:
			scene.preview_clip = clip
			await process_frame
			assert(scene.active_preview().clip == clip and scene.active_preview().visible)
			assert(scene.preview_skill_button.text == Party.HEROES[i].skill)
	scene.to_title()
	await process_frame
	assert(not scene.companion_preview.visible)
	scene.begin()
	await process_frame
	assert(scene.companion_views.all(func(v): return v.visible and v.sheet != v.SHEET))
	scene.toggle_pause()
	for voice in scene.audio.voices:
		voice.stop()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	print("PASS: four sheets, six states, pause, terminal death, reset, five-character viewer and battle integration")
	quit()
