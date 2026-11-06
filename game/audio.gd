extends Node

var voices: Array[AudioStreamPlayer] = []
var streams: Dictionary = {}
var last_hit := -1000
var muted := false

func _ready() -> void:
	for bus_name in ["Music", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus_name) < 0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus_name)
			AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	AudioServer.set_bus_volume_db(0, -6)
	var config := ConfigFile.new()
	if config.load("user://audio.cfg") == OK:
		muted = config.get_value("audio", "muted", false)
	AudioServer.set_bus_mute(0, muted)
	for event in ["hit", "skill", "wave", "win", "lose"]:
		streams[event] = load("res://audio/%s.wav" % event)
	for i in range(4):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -14
		voice.bus = "SFX"
		add_child(voice)
		voices.append(voice)

func play_cue(event: String) -> void:
	if not streams.has(event):
		return
	if event == "hit":
		if Time.get_ticks_msec() - last_hit < 100:
			return
		last_hit = Time.get_ticks_msec()
	for voice in voices:
		if not voice.playing:
			voice.stream = streams[event]
			voice.play()
			return

func toggle_mute() -> bool:
	muted = not muted
	AudioServer.set_bus_mute(0, muted)
	var config := ConfigFile.new()
	config.set_value("audio", "muted", muted)
	config.save("user://audio.cfg")
	return muted

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		for voice in voices:
			voice.stop()
