extends SceneTree
const Progress = preload("res://game/campaign_progress.gd")
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://docs/screenshots/campaign_%s.png" % name) == OK)
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.progress = Progress.new("user://capture-%d/campaign.json" % Time.get_ticks_usec())
	root.add_child(scene)
	await capture("title")
	scene.open_stages()
	await capture("stages")
	scene.prepare_stage(1)
	await capture("prepare")
	scene.set_auto_mode(true)
	for id in range(1, 11):
		scene.start_campaign(id)
		var boss_capture := false
		for frame in range(18000):
			scene._process(1.0 / 60)
			if id == 1 and frame == 100: await capture("battle")
			if id == 10 and not boss_capture and scene.battle.boss_wave() and not scene.battle.enemies.is_empty() and scene.battle.enemies[0].get("phase", 1) == 2:
				boss_capture = true
				await capture("boss")
			if frame % 120 == 0: await process_frame
			if scene.screen == "result": break
		assert(scene.battle.state == "won" and scene.receipt.ok)
		if id == 1:
			await capture("first_reward")
			scene.start_campaign(1)
			for frame in range(18000):
				scene._process(1.0 / 60)
				if frame % 120 == 0: await process_frame
				if scene.screen == "result": break
			assert(scene.receipt.ok and not scene.receipt.first)
			await capture("repeat_reward")
	await capture("complete")
	scene.open_stages()
	await capture("all_stages")
	for voice in scene.audio.voices: voice.stop()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	print("PASS: captured full campaign flow, first/repeat rewards, boss phase2 and chapter completion")
	quit()
