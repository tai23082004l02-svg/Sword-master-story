extends SceneTree
const Progress = preload("res://game/campaign_progress.gd")
func _initialize() -> void:
	call_deferred("run")
func find_button(node: Node, prefix: String) -> Button:
	for child in node.get_children():
		if child is Button and child.text.begins_with(prefix): return child
		var found := find_button(child, prefix)
		if found != null: return found
	return null
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.progress = Progress.new("user://equipment-scene-%d.json" % Time.get_ticks_usec())
	scene.progress.data.gold = 2000
	assert(scene.progress.commit(scene.progress.data))
	root.add_child(scene)
	await process_frame
	find_button(scene.menu, "Trang bị").pressed.emit()
	await process_frame
	assert(scene.screen == "equipment" and scene.wallet.visible)
	find_button(scene.campaign_panel, "Mua · 80 vàng").pressed.emit()
	await process_frame
	assert(scene.progress.data.gold == 1920)
	find_button(scene.campaign_panel, "Trang bị").pressed.emit()
	await process_frame
	assert(scene.progress.hero_stats(0).damage == 26)
	assert(find_button(scene.campaign_panel, "Đã mặc").disabled)
	find_button(scene.campaign_panel, "Tháo vũ khí").pressed.emit()
	await process_frame
	find_button(scene.campaign_panel, "Nyx").pressed.emit()
	await process_frame
	find_button(scene.campaign_panel, "Trang bị").pressed.emit()
	await process_frame
	assert(scene.progress.hero_stats(3).damage == 19)
	scene.close_growth()
	await process_frame
	assert(scene.screen == "title")
	scene.open_stages()
	scene.prepare_stage(1)
	await process_frame
	find_button(scene.campaign_panel, "Trang bị").pressed.emit()
	await process_frame
	assert(scene.growth_return == "prepare")
	scene.close_growth()
	await process_frame
	assert(scene.screen == "prepare")
	assert("Đánh 19" in find_button(scene.campaign_panel, "Nyx").text)
	scene.start_campaign(1)
	await process_frame
	assert(scene.battle.heroes[3].damage == 19)
	scene.to_title()
	for voice in scene.audio.voices: voice.stop()
	scene.queue_free()
	await process_frame
	print("PASS: equipment menu, buy/equip/unequip, hero selection, prepare return and battle stats")
	quit()
