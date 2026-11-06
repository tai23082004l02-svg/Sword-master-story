extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.begin()
	await process_frame
	assert(scene.battle.heroes.size() == 5)
	assert(scene.skill_buttons.all(func(b): return b.visible))
	assert(scene.companion_views.all(func(v): return v.visible))
	scene.use_party_skill(1)
	assert(scene.battle.heroes[1].cooldown_left > 0 and scene.battle.cooldown == 0)
	scene.toggle_pause()
	var before: Array = scene.battle.heroes.duplicate(true)
	await process_frame
	assert(scene.battle.heroes == before)
	assert(scene.companion_views.all(func(v): return v.frozen))
	scene.resume()
	scene.auto_skills = true
	await process_frame
	assert(scene.battle.cooldown > 0)
	scene.to_title()
	await process_frame
	assert(scene.companion_views.all(func(v): return not v.visible))
	scene.party_size = 1
	scene.begin()
	await process_frame
	assert(scene.battle.heroes.size() == 1 and not scene.skill_buttons[1].visible)
	for voice in scene.audio.voices:
		voice.stop()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	print("PASS: party HUD, companions, skills, pause, auto, title and solo restart")
	quit()
