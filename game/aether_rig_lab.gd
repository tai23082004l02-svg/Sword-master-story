extends Node2D
const RigScene = preload("res://scenes/aether_rig.tscn")
var rig: Node2D
var ui: Control
var clip_label: Label
var paused := false
var selected := "idle"
func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("0c1824"))
	rig = RigScene.instantiate()
	rig.position = Vector2(385, 600)
	rig.scale = Vector2(1.55, 1.55)
	rig.z_index = 20
	add_child(rig)
	var layer := CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	layer.add_child(ui)
	label_at("AETHER · BẢN THỬ BỘ XƯƠNG", Vector2(55, 24), 30)
	label_at("24 bộ phận rời · Giáp Ngân Nguyệt", Vector2(55, 65), 20)
	label_at("Thử chuyển động", Vector2(825, 120), 26)
	clip_label = label_at("Đứng", Vector2(825, 164), 20)
	var clips := ["idle", "run", "attack", "skill", "hurt", "death"]
	var names := ["Đứng", "Chạy", "Đánh", "Kỹ năng", "Trúng đòn", "Ngã xuống"]
	for i in range(6):
		var index := i
		button(names[i], Vector2(825 + i % 2 * 190, 210 + i / 2 * 66), Vector2(175, 54), func():
			selected = clips[index]
			paused = false
			rig.set_clip(selected)
			clip_label.text = names[index])
	button("Hiện / ẩn xương", Vector2(825, 420), Vector2(365, 52), func(): rig.show_bones = not rig.show_bones)
	button("Tách / ghép bộ phận", Vector2(825, 482), Vector2(365, 52), func(): rig.set_exploded(not rig.exploded))
	button("Dừng / tiếp tục", Vector2(825, 544), Vector2(365, 52), func():
		paused = not paused
		if paused: rig.player.pause()
		else: rig.player.play())
	var speed := HSlider.new()
	speed.position = Vector2(825, 635)
	speed.size = Vector2(365, 30)
	speed.min_value = 0.25
	speed.max_value = 1.5
	speed.step = 0.05
	speed.value = 1.0
	speed.value_changed.connect(func(value): rig.player.speed_scale = value)
	ui.add_child(speed)
	label_at("Tốc độ: chậm / nhanh", Vector2(825, 603), 18)
	button("Về sảnh", Vector2(1020, 30), Vector2(170, 52), func(): get_tree().change_scene_to_file("res://scenes/main.tscn"))
	label_at("Bản thử ghép khớp · Chưa thay Aether trong trận", Vector2(55, 665), 20)
func label_at(text: String, pos: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	ui.add_child(label)
	return label
func button(text: String, pos: Vector2, size: Vector2, callback: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(callback)
	ui.add_child(b)
func _draw() -> void:
	draw_rect(Rect2(45, 105, 710, 530), Color("142c3c"))
	draw_rect(Rect2(45, 105, 710, 530), Color("6c939e"), false, 2)
	draw_circle(Vector2(420, 365), 215, Color("1c394b"))
	draw_line(Vector2(80, 612), Vector2(720, 612), Color("57747e"), 2)
