extends Node2D
## Independent frame textures only; gameplay timing remains owned by Battle.
const Frames = preload("res://game/sprite_frames.gd")
const CLIPS = {"idle": [0, 6, 0.16], "run": [6, 6, 0.09], "attack": [12, 6, 0.06], "skill": [18, 3, 0.16], "hurt": [21, 1, 0.20], "death": [22, 2, 0.36]}
var character_id := "aether"
var frame_override := -1
var sword_overlays := true
var clip := "idle"
var clock := 0.0
var facing := 1.0
var frozen := false
var preview := false

func set_clip(value: String, restart := false) -> void:
	if not CLIPS.has(value):
		return
	if value != clip or restart:
		clip = value
		clock = 0
		queue_redraw()

func _ready() -> void:
	var cleanup := ShaderMaterial.new()
	cleanup.shader = preload("res://game/shaders/sprite_alpha.gdshader")
	material = cleanup
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	if not frozen:
		clock += delta
	queue_redraw()

func frame_index() -> int:
	var data: Array = CLIPS[clip]
	var index := maxi(0, frame_override) if frame_override >= 0 else maxi(0, int(clock / float(data[2])))
	if frame_override >= 0 or (clip in ["death", "hurt", "attack", "skill"] and not preview):
		index = mini(index, int(data[1]) - 1)
	else:
		index %= int(data[1])
	return int(data[0]) + index

func _draw() -> void:
	var frame := frame_index()
	var index := frame - int(CLIPS[clip][0])
	draw_set_transform(Vector2.ZERO, 0, Vector2(facing, 1))
	Frames.draw_frame(self, character_id, frame)
	if sword_overlays and clip == "skill":
		var phase := fmod(clock, 0.48) / 0.48
		var tint := Color(0.3, 0.95, 1, (1.0 - phase) * 0.7)
		draw_arc(Vector2(18, -85), 90 + phase * 45, -1.65, 1.0, 32, tint, 4)
		draw_arc(Vector2(18, -85), 76 + phase * 45, -1.6, 0.8, 32, Color(tint, tint.a * 0.4), 8)
	if sword_overlays and clip == "attack" and index in [2, 3]:
		draw_arc(Vector2(20, -80), 85, -1.5, 0.75, 24, Color(0.7, 1, 1, 0.65), 3)
	draw_set_transform(Vector2.ZERO)
