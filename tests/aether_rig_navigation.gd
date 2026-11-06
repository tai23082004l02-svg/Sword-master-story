extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	assert(change_scene_to_file("res://scenes/main.tscn") == OK)
	await process_frame
	await process_frame
	assert(current_scene.rig_button.visible)
	current_scene.rig_button.pressed.emit()
	await process_frame
	await process_frame
	assert(current_scene.name == "AetherRigLab")
	for child in current_scene.ui.get_children():
		if child is Button and child.text == "Về sảnh":
			child.pressed.emit()
			break
	await process_frame
	await process_frame
	assert(current_scene.screen == "title" and current_scene.rig_button.visible)
	for voice in current_scene.audio.voices: voice.stop()
	await create_timer(0.15).timeout
	current_scene.queue_free()
	await process_frame
	print("PASS: title button opens rig lab, return restores title")
	quit()
