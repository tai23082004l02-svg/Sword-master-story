extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.begin()
	# Play the actual full encounter. Skill is used immediately on cooldown.
	for i in range(6000):
		scene.use_skill()
		await process_frame
		if scene.battle.wave == 4 and not scene.battle.enemies.is_empty():
			var enemy: Dictionary = scene.battle.enemies[0]
			if enemy.phase == 2 and enemy.windup > 0:
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://docs/screenshots/eclipse_boss.png")
				break
	for i in range(6000):
		scene.use_skill()
		await process_frame
		if scene.screen == "result":
			assert(scene.battle.state == "won")
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://docs/screenshots/boss_victory.png")
			break
	assert(scene.screen == "result")
	scene.to_title()
	for voice in scene.audio.voices:
		voice.stop()
	await create_timer(0.2).timeout
	scene.queue_free()
	await process_frame
	print("PASS: rendered full encounter with boss phase2 and victory")
	quit()
