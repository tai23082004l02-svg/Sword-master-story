extends Node2D

const BattleModel = preload("res://game/battle.gd")
var battle = BattleModel.new()
var screen := "title"
var ui: Control
var status: Label
var skill_button: Button
var pause_button: Button
var menu: VBoxContainer
var audio: Node

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("101b2d"))
	audio = preload("res://game/audio.gd").new()
	add_child(audio)
	battle.cue.connect(audio.play_cue)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layer := CanvasLayer.new()
	add_child(layer)
	layer.add_child(ui)
	var mute_button := make_button("Âm: bật", Vector2(40, 640), Vector2(170, 50), func():
		audio.toggle_mute()
		refresh_mute())
	mute_button.name = "Mute"
	refresh_mute()
	status = Label.new()
	status.position = Vector2(40, 28)
	status.add_theme_font_size_override("font_size", 25)
	ui.add_child(status)
	skill_button = make_button("KIẾM KHÍ · Space", Vector2(920, 600), Vector2(310, 76), use_skill)
	pause_button = make_button("Tạm dừng", Vector2(1060, 25), Vector2(170, 52), toggle_pause)
	show_menu("KIẾM HÀNH", "Bản thử chiến đấu 0.2\nMột kiếm sĩ · Ba đợt quái\nTự đánh — chạm Kiếm khí để dùng kỹ năng", "Bắt đầu", begin)
	get_viewport().size_changed.connect(resize_ui)
	resize_ui()

func resize_ui() -> void:
	# Canvas stretch provides a consistent logical 1280×720 touch layout.
	queue_redraw()

func make_button(text: String, pos: Vector2, dimensions: Vector2, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.position = pos
	button.size = dimensions
	button.add_theme_font_size_override("font_size", 22)
	button.pressed.connect(callback)
	ui.add_child(button)
	return button

func show_menu(title: String, subtitle: String, action: String, callback: Callable) -> void:
	if is_instance_valid(menu):
		menu.queue_free()
	menu = VBoxContainer.new()
	menu.position = Vector2(350, 190)
	menu.size = Vector2(580, 350)
	menu.add_theme_constant_override("separation", 24)
	ui.add_child(menu)
	for text in [title, subtitle]:
		var label := Label.new()
		label.text = text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 38 if text == title else 23)
		menu.add_child(label)
	var button := Button.new()
	button.text = action
	button.custom_minimum_size.y = 64
	button.add_theme_font_size_override("font_size", 25)
	button.pressed.connect(callback)
	menu.add_child(button)
	if screen == "paused":
		var home := Button.new()
		home.text = "Về sảnh"
		home.custom_minimum_size.y = 55
		home.pressed.connect(to_title)
		menu.add_child(home)

func begin() -> void:
	menu.queue_free()
	screen = "battle"
	battle.start()

func to_title() -> void:
	screen = "title"
	battle.state = "idle"
	show_menu("KIẾM HÀNH", "Đánh thường tự động\nKỹ năng gây 48 sát thương cho toàn bộ địch · hồi 6 giây", "Bắt đầu", begin)

func use_skill() -> void:
	battle.skill()

func toggle_pause() -> void:
	if screen == "battle":
		battle.state = "paused"
		screen = "paused"
		show_menu("TẠM DỪNG", "Trận đấu đang dừng", "Tiếp tục", resume)
	elif screen == "paused":
		resume()

func resume() -> void:
	menu.queue_free()
	battle.state = "playing"
	screen = "battle"

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and screen == "battle":
		toggle_pause()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			use_skill()
		elif event.keycode == KEY_ESCAPE:
			toggle_pause()

func _process(delta: float) -> void:
	battle.tick(minf(delta, 0.05))
	if screen == "battle" and battle.state in ["won", "lost"]:
		screen = "result"
		show_menu("CHIẾN THẮNG" if battle.state == "won" else "THẤT BẠI", "Hạ %d quái · Đợt %d/3 · %.1f giây\nBản thử chưa có phần thưởng hoặc lưu tiến trình" % [battle.kills, battle.wave, battle.elapsed], "Chơi lại", begin)
	status.visible = screen in ["battle", "paused"]
	skill_button.visible = screen == "battle"
	pause_button.visible = screen == "battle"
	status.text = "ĐỢT %d / 3      KIẾM SĨ  %d / 220 HP" % [battle.wave, ceili(battle.hero_hp)]
	skill_button.disabled = battle.cooldown > 0 or battle.intermission > 0
	skill_button.text = "KIẾM KHÍ · %.1fs" % battle.cooldown if battle.cooldown > 0 else "KIẾM KHÍ · Space"
	queue_redraw()

func fighter(x: float, color: Color, is_hero: bool, warning: bool) -> void:
	var y := 455.0
	draw_ellipse_shadow(Vector2(x, y + 62))
	draw_rect(Rect2(x - 19, y + 5, 38, 42), color)
	draw_circle(Vector2(x, y - 11), 19, Color("efd1ac") if is_hero else Color("99a8b5"))
	draw_rect(Rect2(x - 22, y - 29, 43, 14), color.darkened(0.4))
	draw_line(Vector2(x - 10, y + 45), Vector2(x - 14, y + 62), color.darkened(0.4), 11)
	draw_line(Vector2(x + 10, y + 45), Vector2(x + 14, y + 62), color.darkened(0.4), 11)
	var sword_end := Vector2(x + 66, y - 42) if warning else Vector2(x + 48, y + 17)
	draw_line(Vector2(x + 17, y + 19), sword_end, Color("ffe7a0") if is_hero else Color("cf7184"), 7)
	if warning:
		draw_arc(Vector2(x, y), 65, -1.5, 0.7, 18, Color("ffd488"), 4)

func draw_ellipse_shadow(pos: Vector2) -> void:
	draw_set_transform(pos, 0, Vector2(1, 0.25))
	draw_circle(Vector2.ZERO, 34, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("101b2d"))
	draw_circle(Vector2(1010, 135), 63, Color("e1d7b4"))
	for i in range(9):
		var x := float(i * 180 - 80)
		draw_colored_polygon(PackedVector2Array([Vector2(x, 440), Vector2(x + 130, 160 + (i % 3) * 40), Vector2(x + 270, 440)]), Color("23344a"))
	draw_rect(Rect2(0, 440, 1280, 280), Color("253b3d"))
	draw_rect(Rect2(0, 525, 1280, 70), Color("685c50"))
	for i in range(25):
		draw_line(Vector2(i * 58, 550), Vector2(i * 58 + 25, 550), Color("8c7960"), 3)
	if screen in ["battle", "paused", "result"]:
		fighter(battle.hero_x, Color("4caeb5"), true, battle.windup > 0)
		for enemy in battle.enemies:
			if enemy.hp <= 0:
				continue
			fighter(enemy.x, Color("a778ab") if enemy.ranged else Color("bc6d67"), false, enemy.windup > 0)
			draw_rect(Rect2(enemy.x - 29, 395, 58, 6), Color("492e3b"))
			draw_rect(Rect2(enemy.x - 29, 395, 58 * maxf(0, enemy.hp / enemy.max_hp), 6), Color("df8680"))
		for effect in battle.effects:
			draw_string(ThemeDB.fallback_font, Vector2(effect.x - 15, 370 - (0.65 - effect.ttl) * 50), effect.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("ffe49b") if effect.skill else Color.WHITE)
	if screen != "battle":
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.025, 0.045, 0.08, 0.83))

func refresh_mute() -> void:
	ui.get_node("Mute").text = "Âm: tắt" if audio.muted else "Âm: bật"
