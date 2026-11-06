extends SceneTree
const Progress = preload("res://game/campaign_progress.gd")
class FailingProgress extends Progress:
	var fail := false
	func commit(candidate: Dictionary) -> bool:
		if fail:
			last_error = "Simulated storage failure"
			return false
		return super.commit(candidate)
func _initialize() -> void:
	call_deferred("run")
func find_button(node: Node, prefix: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text.begins_with(prefix): return child
		var result := find_button(child, prefix)
		if result != null: return result
	return null
func stop_scene(scene: Node) -> void:
	for voice in scene.audio.voices: voice.stop()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
func run() -> void:
	var folder := "user://growth-scene-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var path := folder + "/profile.json"
	var legacy := Progress.new(path).defaults()
	legacy.version = 1
	legacy.erase("hero_levels")
	legacy.gold = 130
	legacy.xp = 52
	legacy.cleared = [1]
	legacy.records = {"1": {"wins": 1, "best_time": 6.25}}
	legacy.auto_skills = true
	legacy.serial = 1
	legacy.last_claimed = 1
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.progress = Progress.new(path)
	root.add_child(scene)
	await process_frame
	find_button(scene.menu, "Nâng tướng").pressed.emit()
	await process_frame
	assert(scene.screen == "growth" and scene.wallet.visible)
	assert(not find_button(scene.campaign_panel, "Nâng lên cấp 2").disabled)
	find_button(scene.campaign_panel, "Nâng lên cấp 2").pressed.emit()
	await process_frame
	assert(scene.progress.levels() == [2, 1, 1, 1, 1])
	assert(scene.progress.data.gold == 100 and scene.progress.data.xp == 42)
	scene.upgrade_selected(0, 1)
	await process_frame
	assert(scene.progress.data.gold == 100)
	find_button(scene.campaign_panel, "Nyx ·").pressed.emit()
	await process_frame
	find_button(scene.campaign_panel, "Nâng lên cấp 2").pressed.emit()
	await process_frame
	assert(scene.progress.levels() == [2, 1, 1, 2, 1])
	scene.close_growth()
	await process_frame
	assert(scene.screen == "title")
	scene.open_stages()
	scene.prepare_stage(1)
	await process_frame
	assert("242 HP" in find_button(scene.campaign_panel, "Aether").text)
	find_button(scene.campaign_panel, "Nâng tướng").pressed.emit()
	await process_frame
	assert(scene.screen == "growth" and scene.growth_return == "prepare")
	for i in range(5):
		scene.open_growth("prepare", i)
		await process_frame
		assert(scene.growth_index == i)
	scene.close_growth()
	await process_frame
	assert(scene.screen == "prepare" and scene.selected_stage == 1)
	scene.start_campaign(1)
	await process_frame
	assert(scene.battle.heroes[0].level == 2 and scene.battle.heroes[0].max_hp == 242)
	assert(scene.battle.heroes[3].id == "nyx" and scene.battle.heroes[3].level == 2)
	assert("Cấp 2" in scene.skill_buttons[0].text)
	assert(scene.progress.upgrade_hero(0, 2).ok)
	assert(scene.battle.heroes[0].level == 2)
	scene.toggle_pause()
	scene.to_title()
	scene.start_campaign(1)
	await process_frame
	assert(scene.battle.heroes[0].level == 3 and scene.battle.heroes[0].max_hp == 264)
	scene.to_title()
	await stop_scene(scene)
	var loaded = load("res://scenes/main.tscn").instantiate()
	loaded.progress = Progress.new(path)
	root.add_child(loaded)
	await process_frame
	assert(loaded.progress.levels() == [3, 1, 1, 2, 1] and loaded.progress.unlocked() == 2)
	assert(loaded.progress.data.gold == 20 and loaded.progress.data.xp == 12 and loaded.auto_skills)
	await stop_scene(loaded)
	# Storage failure keeps the upgrade button retryable, without spending.
	var storage := FailingProgress.new(folder + "/failed.json")
	var data := storage.defaults()
	data.gold = 500
	data.xp = 500
	assert(storage.commit(data))
	var failed = load("res://scenes/main.tscn").instantiate()
	failed.progress = storage
	root.add_child(failed)
	await process_frame
	failed.open_growth("title", 3)
	await process_frame
	storage.fail = true
	find_button(failed.campaign_panel, "Nâng lên cấp 2").pressed.emit()
	await process_frame
	assert(storage.levels()[3] == 1 and storage.data.gold == 500)
	storage.fail = false
	find_button(failed.campaign_panel, "Nâng lên cấp 2").pressed.emit()
	await process_frame
	assert(storage.levels()[3] == 2 and storage.data.gold == 470)
	data = storage.data.duplicate(true)
	data.hero_levels[0] = 20
	assert(storage.commit(data))
	failed.open_growth("title", 0)
	await process_frame
	assert(find_button(failed.campaign_panel, "Đã đạt cấp 20").disabled)
	data = storage.data.duplicate(true)
	data.gold = 0
	data.xp = 0
	assert(storage.commit(data))
	failed.open_growth("title", 1)
	await process_frame
	assert(find_button(failed.campaign_panel, "Nâng lên cấp 2").disabled)
	assert("Cần thêm" in failed.campaign_panel.notice.text)
	await stop_scene(failed)
	print("PASS: legacy profile through upgrade UI, all five heroes, quote/double click, prepare return, updated HUD/stats, next-battle snapshot, reload, failed save/retry, cap and insufficient-funds UI")
	quit()
