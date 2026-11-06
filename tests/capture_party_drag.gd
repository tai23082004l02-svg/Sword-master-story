extends SceneTree
const Progress = preload("res://game/campaign_progress.gd")
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://docs/screenshots/party_drag_%s.png" % name) == OK)
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	var profile := Progress.new("user://capture-drag-%d/profile.json" % Time.get_ticks_usec())
	var data := profile.defaults()
	data.gold = 50
	data.xp = 18
	data.cleared = [1, 2]
	data.records = {"1": {"wins": 1, "best_time": 6.0}, "2": {"wins": 1, "best_time": 8.0}}
	data.hero_levels = [5, 1, 1, 1, 1]
	data.serial = 2
	data.last_claimed = 2
	assert(profile.commit(data))
	scene.progress = profile
	root.add_child(scene)
	await process_frame
	scene.open_stages()
	scene.prepare_stage(3)
	await capture("ready")
	var panel: Control = scene.campaign_panel
	var driver = panel.get_node("PartyDrag")
	var press := InputEventScreenTouch.new()
	press.position = panel.get_global_transform_with_canvas() * driver.cards[1].get_rect().get_center()
	press.pressed = true
	root.push_input(press, true)
	await process_frame
	var motion := InputEventScreenDrag.new()
	motion.position = panel.get_global_transform_with_canvas() * driver.cards[4].get_rect().get_center()
	root.push_input(motion, true)
	await capture("moving")
	assert(driver.dragging and profile.formation() == [0, 1, 2, 3, 4])
	var release := InputEventScreenTouch.new()
	release.position = motion.position
	release.pressed = false
	root.push_input(release, true)
	await capture("saved")
	assert(profile.formation() == [0, 2, 3, 4, 1] and profile.data.hero_levels == [5, 1, 1, 1, 1])
	for voice in scene.audio.voices: voice.stop()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	print("PASS: rendered native-touch drag preview, drop highlight and saved visual order")
	quit()
