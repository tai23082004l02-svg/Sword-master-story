extends ConfirmationDialog
var mixer: Node
var master: HSlider
var sfx: HSlider
var mute: CheckButton
var notice: Label
func _init(audio: Node = null) -> void:
	mixer = audio
	title = "Âm thanh"
	size = Vector2i(700, 410)
	ok_button_text = "Lưu"
	cancel_button_text = "Hủy"
	dialog_hide_on_ok = false
func _ready() -> void:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	add_child(box)
	mute = CheckButton.new()
	mute.text = "Tắt toàn bộ âm thanh"
	mute.button_pressed = mixer.muted
	box.add_child(mute)
	master = volume_row(box, "Âm lượng tổng", mixer.master_level)
	sfx = volume_row(box, "Hiệu ứng chiến đấu", mixer.sfx_level)
	notice = Label.new()
	notice.text = "Bấm Lưu để áp dụng · Không thay đổi tiến trình game"
	notice.add_theme_font_size_override("font_size", 18)
	box.add_child(notice)
	confirmed.connect(func():
		if mixer.save_settings(mute.button_pressed, master.value / 100.0, sfx.value / 100.0): hide()
		else: notice.text = mixer.last_error)
	visibility_changed.connect(func():
		if not visible: queue_free())
func volume_row(box: VBoxContainer, title_text: String, value: float) -> HSlider:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 24)
	box.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = roundf(value * 100)
	slider.custom_minimum_size = Vector2(640, 50)
	label.text = "%s · %d%%" % [title_text, slider.value]
	slider.value_changed.connect(func(level): label.text = "%s · %d%%" % [title_text, level])
	box.add_child(slider)
	return slider
