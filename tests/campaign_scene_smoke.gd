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
		var nested := find_button(child, prefix)
		if nested != null: return nested
	return null
func stop_scene(scene: Node) -> void:
	for voice in scene.audio.voices: voice.stop()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
func run() -> void:
	var path := "user://campaign-scene-%d/profile.json" % Time.get_ticks_usec()
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.progress = Progress.new(path)
	root.add_child(scene)
	await process_frame
	find_button(scene.menu, "Chọn ải").pressed.emit()
	await process_frame
	assert(scene.screen == "stages")
	assert(not find_button(scene.campaign_panel, "1-01").disabled)
	assert(find_button(scene.campaign_panel, "1-02").disabled)
	find_button(scene.campaign_panel, "1-01").pressed.emit()
	await process_frame
	assert(scene.screen == "prepare")
	scene.select_companion(1)
	await process_frame
	scene.select_companion(1)
	await process_frame
	scene.move_companion(4, -1)
	await process_frame
	assert(scene.progress.formation() == [0, 2, 4, 3, 1])
	scene.set_auto_mode(true)
	find_button(scene.campaign_panel, "Bắt đầu").pressed.emit()
	await process_frame
	assert(scene.screen == "battle" and scene.battle.wave_limit == 2)
	assert(scene.battle.heroes[1].id == "lyra" and scene.battle.heroes[2].id == "sol")
	assert(scene.companion_views[0].character_id == "lyra")
	scene._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(scene.screen == "paused")
	var elapsed: float = scene.battle.elapsed
	scene._process(0.2)
	assert(scene.battle.elapsed == elapsed)
	scene.resume()
	for frame in range(18000):
		scene._process(1.0 / 60)
		if scene.battle.state == "won": break
	assert(scene.battle.state == "won" and scene.receipt.ok)
	assert(scene.progress.data.gold == scene.Campaign.reward(1, true).gold, "Save reward immediately, before result animation delay")
	scene._process(1)
	await process_frame
	assert(scene.screen == "result" and scene.receipt.first)
	var gold: int = scene.progress.data.gold
	scene.show_campaign_result()
	scene._process(1)
	assert(scene.progress.data.gold == gold)
	find_button(scene.campaign_panel, "Ải tiếp theo").pressed.emit()
	await process_frame
	assert(scene.screen == "prepare" and scene.selected_stage == 2)
	scene.start_campaign(2)
	for actor in scene.battle.heroes: actor.hp = 0
	scene._process(0.02)
	scene._process(1)
	await process_frame
	assert(scene.receipt.ok and not scene.receipt.won and scene.progress.data.gold == gold)
	assert(find_button(scene.campaign_panel, "Ải tiếp theo") == null)
	scene.start_campaign(2)
	scene.toggle_pause()
	scene.to_title()
	await process_frame
	assert(scene.progress.data.pending.is_empty() and scene.progress.data.gold == gold)
	await stop_scene(scene)
	var reloaded = load("res://scenes/main.tscn").instantiate()
	reloaded.progress = Progress.new(path)
	root.add_child(reloaded)
	await process_frame
	assert(reloaded.screen == "title" and reloaded.progress.unlocked() == 2)
	assert(reloaded.progress.data.gold == gold and reloaded.progress.formation() == [0, 2, 4, 3, 1])
	assert(reloaded.auto_skills)
	await stop_scene(reloaded)
	var storage = FailingProgress.new(path)
	var failed_scene = load("res://scenes/main.tscn").instantiate()
	failed_scene.progress = storage
	root.add_child(failed_scene)
	await process_frame
	failed_scene.start_campaign(2)
	storage.fail = true
	failed_scene.battle.state = "won"
	failed_scene._process(1)
	await process_frame
	assert(failed_scene.screen == "result" and not failed_scene.receipt.ok)
	assert(storage.data.gold == gold and find_button(failed_scene.campaign_panel, "Ải tiếp theo") == null)
	storage.fail = false
	find_button(failed_scene.campaign_panel, "Thử lưu lại").pressed.emit()
	await process_frame
	assert(failed_scene.receipt.ok and storage.unlocked() == 3)
	var saved_gold: int = storage.data.gold
	failed_scene.show_campaign_result()
	assert(storage.data.gold == saved_gold)
	await stop_scene(failed_scene)
	print("PASS: stage lock, preparation/reorder, correct art/skills by ID, pause, immediate durable reward, no duplicate, next stage, defeat, abandon scene reload and failed-result save/retry")
	quit()
