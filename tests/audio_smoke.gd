extends SceneTree
const Mixer = preload("res://game/audio.gd")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var folder := "user://audio-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var path := folder + "/audio.cfg"
	var legacy := ConfigFile.new()
	legacy.set_value("audio", "muted", true)
	assert(legacy.save(path) == OK)
	var mixer := Mixer.new()
	mixer.config_path = path
	root.add_child(mixer)
	assert(mixer.muted and mixer.master_level == 1.0 and mixer.sfx_level == 1.0)
	assert(mixer.save_settings(false, 0.6, 0.3))
	assert(is_equal_approx(AudioServer.get_bus_volume_db(0), -6 + linear_to_db(0.6)))
	assert(is_equal_approx(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")), linear_to_db(0.3)))
	var reload := Mixer.new()
	reload.config_path = path
	root.add_child(reload)
	assert(not reload.muted and reload.master_level == 0.6 and reload.sfx_level == 0.3)
	reload.queue_free()
	mixer.play_cue("skill")
	mixer.play_cue("skill")
	mixer.play_cue("skill")
	mixer.play_cue("skill")
	assert(mixer.voices.all(func(v): return v.playing))
	assert(mixer.select_voice(0) == null and mixer.select_voice(1) == null)
	var oldest: AudioStreamPlayer = mixer.voices[0]
	assert(mixer.select_voice(2) == oldest)
	mixer.play_cue("wave")
	assert(oldest.get_meta("priority") == 2)
	mixer.play_cue("win")
	assert(mixer.voices.filter(func(v): return v.playing).size() == 1)
	assert(mixer.voices.any(func(v): return v.playing and v.get_meta("priority") == 3))
	mixer.stop_all()
	mixer.last_hit = -1000
	mixer.play_cue("hit")
	mixer.play_cue("hit")
	assert(mixer.voices.filter(func(v): return v.playing).size() == 1)
	assert(mixer.save_settings(true, 0.6, 0.3))
	assert(mixer.voices.all(func(v): return not v.playing))
	mixer.play_cue("skill")
	assert(mixer.voices.all(func(v): return not v.playing))
	assert(mixer.save_settings(false, 1.0, 0.0))
	assert(AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")))
	var previous := mixer.master_level
	mixer.config_path = folder + "/missing/audio.cfg"
	assert(not mixer.save_settings(true, 0.1, 0.2) and mixer.master_level == previous and not mixer.muted)
	assert(mixer.valid_level("bad") == 1.0 and mixer.valid_level(INF) == 1.0)
	assert(mixer.valid_level(-2) == 0 and mixer.valid_level(3) == 1)
	mixer.queue_free()
	await process_frame
	print("PASS: legacy audio config, volume buses/reload, priority pool, result isolation, hit throttle, mute/zero and save failure")
	quit()
