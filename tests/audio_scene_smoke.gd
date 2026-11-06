extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.progress = preload("res://game/campaign_progress.gd").new("user://audio-scene-%d.json" % Time.get_ticks_usec())
	root.add_child(scene)
	await process_frame
	scene.audio.config_path = "user://audio-scene-settings-%d.cfg" % Time.get_ticks_usec()
	assert(str(ProjectSettings.get_setting("application/config/version")) in scene.title_subtitle())
	scene.open_audio_settings()
	await process_frame
	var dialog: ConfirmationDialog = scene.audio_dialog
	dialog.master.value = 60
	dialog.sfx.value = 25
	dialog.confirmed.emit()
	await process_frame
	assert(scene.audio.master_level == 0.6 and scene.audio.sfx_level == 0.25)
	scene.open_audio_settings()
	await process_frame
	dialog = scene.audio_dialog
	dialog.master.value = 10
	dialog.hide()
	await process_frame
	assert(scene.audio.master_level == 0.6)
	scene.begin()
	await process_frame
	assert(not scene.audio_settings_button.visible)
	scene.audio.play_cue("skill")
	scene.toggle_pause()
	assert(scene.audio.voices.all(func(v): return not v.playing))
	await process_frame
	assert(scene.audio_settings_button.visible)
	scene.open_audio_settings()
	await process_frame
	dialog = scene.audio_dialog
	assert(scene.screen == "paused" and scene.battle.state == "paused")
	scene.audio.config_path = "user://missing-audio-directory/profile.cfg"
	dialog.confirmed.emit()
	assert(dialog.visible and dialog.notice.text == scene.audio.last_error)
	dialog.hide()
	await process_frame
	scene.resume()
	scene.to_title()
	assert(str(ProjectSettings.get_setting("application/config/version")) in scene.title_subtitle())
	scene.audio.stop_all()
	scene.queue_free()
	await process_frame
	print("PASS: audio dialog save/cancel/error, paused state, button visibility, version consistency")
	await create_timer(0.15).timeout
	quit()
