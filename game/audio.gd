extends Node
## Local SFX mixer; fixed pool, important cues may replace lower-priority voices.
const PRIORITY = {"hit": 0, "skill": 1, "wave": 2, "win": 3, "lose": 3}
var voices: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var last_hit := -1000
var muted := false
var master_level := 1.0
var sfx_level := 1.0
var config_path := "user://audio.cfg"
var last_error := ""
var serial := 0

func _ready() -> void:
	for bus_name in ["Music", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	var config := ConfigFile.new()
	if config.load(config_path) == OK:
		var stored: Variant = config.get_value("audio", "muted", false)
		muted = stored if stored is bool else false
		master_level = valid_level(config.get_value("audio", "master", 1.0))
		sfx_level = valid_level(config.get_value("audio", "sfx", 1.0))
	apply_mix()
	for event in PRIORITY:
		streams[event] = load("res://audio/%s.wav" % event)
	for i in range(4):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -14
		voice.bus = "SFX"
		voice.set_meta("priority", -1)
		voice.set_meta("serial", 0)
		add_child(voice)
		voices.append(voice)

func valid_level(value: Variant) -> float:
	if not (value is int or value is float) or not is_finite(float(value)): return 1.0
	return clampf(float(value), 0.0, 1.0)

func apply_mix() -> void:
	AudioServer.set_bus_volume_db(0, -6.0 + linear_to_db(maxf(master_level, 0.0001)))
	AudioServer.set_bus_mute(0, muted or master_level == 0)
	var bus := AudioServer.get_bus_index("SFX")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(sfx_level, 0.0001)))
		AudioServer.set_bus_mute(bus, sfx_level == 0)

func save_settings(new_muted: bool, master: float, sfx: float) -> bool:
	var config := ConfigFile.new()
	config.set_value("audio", "muted", new_muted)
	config.set_value("audio", "master", valid_level(master))
	config.set_value("audio", "sfx", valid_level(sfx))
	var temporary := config_path + ".tmp"
	if config.save(temporary) != OK:
		last_error = "Chưa lưu được âm thanh. Hãy thử lại."
		return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(config_path)) != OK:
		last_error = "Chưa hoàn tất lưu âm thanh. Hãy thử lại."
		return false
	muted = new_muted
	master_level = valid_level(master)
	sfx_level = valid_level(sfx)
	last_error = ""
	apply_mix()
	if muted or master_level == 0 or sfx_level == 0: stop_all()
	return true

func select_voice(priority: int) -> AudioStreamPlayer:
	for voice in voices:
		if not voice.playing: return voice
	var selected: AudioStreamPlayer = null
	for voice in voices:
		if int(voice.get_meta("priority")) >= priority: continue
		if selected == null or int(voice.get_meta("priority")) < int(selected.get_meta("priority")) or (voice.get_meta("priority") == selected.get_meta("priority") and int(voice.get_meta("serial")) < int(selected.get_meta("serial"))):
			selected = voice
	return selected

func play_cue(event: String) -> void:
	if not streams.has(event) or muted or master_level == 0 or sfx_level == 0: return
	if event == "hit" and Time.get_ticks_msec() - last_hit < 100: return
	var voice := select_voice(PRIORITY[event])
	if voice == null: return
	if event == "hit": last_hit = Time.get_ticks_msec()
	if event in ["win", "lose"]: stop_all()
	voice.stop()
	serial += 1
	voice.set_meta("priority", PRIORITY[event])
	voice.set_meta("serial", serial)
	voice.stream = streams[event]
	voice.play()

func toggle_mute() -> bool:
	save_settings(not muted, master_level, sfx_level)
	return muted

func stop_all() -> void:
	for voice in voices: voice.stop()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: stop_all()

func _exit_tree() -> void:
	stop_all()
	for voice in voices: voice.stream = null
	streams.clear()
