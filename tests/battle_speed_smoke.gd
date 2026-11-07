extends SceneTree
const Progress = preload("res://game/campaign_progress.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.progress = Progress.new("user://speed-%d.json" % Time.get_ticks_usec())
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	assert(scene.battle_speed == 1 and not scene.speed_button.visible)
	scene.cycle_battle_speed()
	assert(scene.battle_speed == 1)
	var outcomes: Array = []
	for speed in [1, 2, 3]:
		scene.start_campaign(1)
		scene.auto_skills = true
		scene.battle_speed = speed
		scene._process(0)
		assert(scene.speed_button.visible and scene.speed_button.text.ends_with("x%d" % speed))
		var elapsed: float = scene.battle.elapsed
		scene.advance_battle(1.0/60)
		assert(is_equal_approx(scene.battle.elapsed-elapsed, speed/60.0))
		# Pause/focus must stop simulation at every speed; retain speed on resume.
		scene.toggle_pause()
		elapsed = scene.battle.elapsed
		scene._process(0.1)
		scene.cycle_battle_speed()
		assert(scene.battle.elapsed == elapsed and scene.battle_speed == speed)
		assert(not scene.speed_button.visible)
		scene.resume()
		for frame in range(18000):
			scene.advance_battle(1.0/60)
			if scene.battle.state != "playing": break
		assert(scene.battle.state == "won")
		outcomes.append({"elapsed":scene.battle.elapsed,"hp":scene.battle.heroes.map(func(a):return a.hp),"kills":scene.battle.kills})
		scene.show_campaign_result()
		assert(scene.receipt.ok and scene.receipt.elapsed == scene.battle.elapsed)
		var snapshot: Dictionary = scene.progress.data.duplicate(true)
		scene.show_campaign_result()
		assert(scene.progress.data == snapshot)
		scene.to_title()
		scene._process(0)
		assert(not scene.speed_button.visible)
	assert(outcomes[0] == outcomes[1] and outcomes[1] == outcomes[2])
	scene.start_campaign(1)
	scene.battle_speed = 1
	for expected in [2, 3, 1]:
		scene.speed_button.pressed.emit()
		assert(scene.battle_speed == expected)
	# Frame stalls retain the previous 50ms cap per simulation step.
	scene.battle_speed = 3
	var elapsed: float = scene.battle.elapsed
	scene.advance_battle(2.0)
	assert(is_equal_approx(scene.battle.elapsed-elapsed, 0.15))
	scene._process(0)
	assert(scene.hero_art.playback_speed == 3.0)
	scene._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(scene.screen == "paused")
	elapsed = scene.battle.elapsed
	scene.advance_battle(0.05)
	assert(scene.battle.elapsed == elapsed)
	assert(Engine.time_scale == 1.0)
	scene.to_title()
	scene.audio.stop_all()
	scene.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("PASS: x1/x2/x3 simulation ratios, identical battle outcomes/elapsed, auto skills, pause/focus, button cycle, visual speed, delta cap and reward dedup")
	quit()
