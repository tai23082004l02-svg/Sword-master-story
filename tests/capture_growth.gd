extends SceneTree
const Progress = preload("res://game/campaign_progress.gd")
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://docs/screenshots/growth_%s.png" % name) == OK)
func run() -> void:
	var folder := "user://capture-growth-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var profile := Progress.new(folder + "/profile.json")
	var legacy := profile.defaults()
	legacy.version = 1
	legacy.erase("hero_levels")
	legacy.gold = 130
	legacy.xp = 52
	legacy.cleared = [1]
	legacy.records = {"1": {"wins": 1, "best_time": 6.25}}
	legacy.auto_skills = true
	legacy.serial = 1
	legacy.last_claimed = 1
	var file := FileAccess.open(profile.path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.progress = profile
	root.add_child(scene)
	await process_frame
	scene.open_growth()
	await capture("before")
	scene.upgrade_selected(0, 1)
	await capture("after")
	scene.open_growth("title", 4)
	scene.upgrade_selected(4, 1)
	await capture("sol")
	scene.close_growth()
	scene.prepare_stage(2)
	await capture("prepare")
	scene.start_campaign(2)
	assert(scene.battle.heroes[0].level == 2 and scene.battle.heroes[4].level == 2)
	for i in range(18000):
		scene._process(1.0 / 60)
		if i == 150: await capture("battle")
		if i % 120 == 0: await process_frame
		if scene.screen == "result": break
	assert(scene.receipt.ok and scene.receipt.won and scene.progress.unlocked() == 3)
	await capture("result")
	scene.to_title()
	var cap := Progress.new(folder + "/cap.json")
	var data := cap.defaults()
	data.gold = 10000
	data.xp = 10000
	assert(cap.commit(data))
	for level in range(1, 20): assert(cap.upgrade_hero(0, level).ok)
	scene.progress = cap
	scene.open_growth("title", 0)
	await capture("max")
	data = cap.data.duplicate(true)
	data.gold = 0
	data.xp = 0
	assert(cap.commit(data))
	scene.open_growth("title", 2)
	await capture("insufficient")
	for voice in scene.audio.voices: voice.stop()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	print("PASS: captured legacy migration, upgrade before/after, support hero, campaign application, cap and insufficient funds")
	quit()
