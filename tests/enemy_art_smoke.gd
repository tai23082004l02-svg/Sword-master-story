extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.begin()
	await process_frame
	assert(scene.enemy_views.size() == 2)
	var id: int = scene.battle.enemies[0].id
	var view = scene.enemy_views[id]
	scene.battle.enemies[0].windup = 0.3
	scene.update_enemies(0.01)
	assert(view.phase == "attack")
	scene.battle.hit(0, 999)
	scene.battle.tick(0.01)
	scene.update_enemies(0.1)
	assert(view.phase == "dead")
	scene.toggle_pause()
	var death: float = view.death_time
	scene.update_enemies(0.1)
	assert(view.death_time == death)
	scene.resume()
	for i in range(6):
		scene.update_enemies(0.1)
	assert(not scene.enemy_views.has(id))
	scene.battle.state = "won"
	scene.toggle_pause()
	assert(scene.battle.state == "won", "Cannot reopen a settled battle by pausing")
	scene.to_title()
	await process_frame
	assert(scene.enemy_views.is_empty())
	for voice in scene.audio.voices:
		voice.stop()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	print("PASS: enemy views, windup, death cleanup, pause freeze, terminal guard, title cleanup")
	quit()
