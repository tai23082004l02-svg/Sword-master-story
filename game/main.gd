extends Node2D

const BACKGROUND = preload("res://assets/world/moon_ruins.png")
const EnemyArt = preload("res://game/enemy_art.gd")
const BattleModel = preload("res://game/battle.gd")
var battle = BattleModel.new()
var screen := "title"
var ui: Control
var status: Label
var skill_button: Button
var pause_button: Button
var menu: VBoxContainer
var audio: Node
var hero_art: Node2D
var art_layer: Node2D
var skill_visual := 0.0
var hurt_visual := 0.0
var prior_hp := 220.0
var prior_x := 240.0
var preview_clip := "idle"
var result_delay := 0.0
var enemy_views: Dictionary = {}
var preview_buttons: Array[Button] = []

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("101b2d"))
	audio = preload("res://game/audio.gd").new()
	add_child(audio)
	battle.cue.connect(audio.play_cue)
	art_layer = Node2D.new()
	art_layer.z_index = 2
	add_child(art_layer)
	hero_art = preload("res://game/hero_art.gd").new()
	art_layer.add_child(hero_art)
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
	show_menu("KIẾM HÀNH", "PHẾ TÍCH NGÂN NGUYỆT · 0.3.1\nMột kiếm sĩ · Ba đợt quái\nTự đánh — chạm Kiếm khí để dùng kỹ năng", "Bắt đầu", begin)
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
	if screen == "title":
		var character := Button.new()
		character.text = "Xem nhân vật · Aether"
		character.custom_minimum_size.y = 60
		character.add_theme_font_size_override("font_size", 23)
		character.pressed.connect(show_character)
		menu.add_child(character)
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
	result_delay = 0
	skill_visual = 0
	hurt_visual = 0
	prior_hp = battle.hero_hp
	prior_x = battle.hero_x
	hero_art.set_clip("idle", true)
	clear_preview()
	clear_enemies()

func to_title() -> void:
	clear_enemies()
	clear_preview()
	screen = "title"
	battle.state = "idle"
	show_menu("KIẾM HÀNH", "Đánh thường tự động\nKỹ năng gây 48 sát thương cho toàn bộ địch · hồi 6 giây", "Bắt đầu", begin)

func use_skill() -> void:
	if battle.skill():
		skill_visual = 0.48
		hero_art.set_clip("skill", true)

func toggle_pause() -> void:
	if screen == "battle" and battle.state == "playing":
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
	update_hero(delta)
	update_enemies(minf(delta, 0.05))
	if screen == "battle" and battle.state in ["won", "lost"]:
		result_delay += delta
	if screen == "battle" and battle.state in ["won", "lost"] and result_delay >= 0.85:
		screen = "result"
		show_menu("CHIẾN THẮNG" if battle.state == "won" else "THẤT BẠI", "Hạ %d quái · Đợt %d/3 · %.1f giây\nBản thử chưa có phần thưởng hoặc lưu tiến trình" % [battle.kills, battle.wave, battle.elapsed], "Chơi lại", begin)
	status.visible = screen in ["battle", "paused"]
	skill_button.visible = screen == "battle"
	pause_button.visible = screen == "battle"
	status.text = "ĐỢT %d / 3      KIẾM SĨ  %d / 220 HP" % [battle.wave, ceili(battle.hero_hp)]
	skill_button.disabled = battle.cooldown > 0 or battle.intermission > 0
	skill_button.text = "KIẾM KHÍ · %.1fs" % battle.cooldown if battle.cooldown > 0 else "KIẾM KHÍ · Space"
	queue_redraw()

func draw_ellipse_shadow(pos: Vector2) -> void:
	draw_set_transform(pos, 0, Vector2(1, 0.25))
	draw_circle(Vector2.ZERO, 34, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	draw_texture_rect(BACKGROUND, Rect2(0, 0, 1280, 720), false)
	# Subtle vignette strips preserve HUD readability over painted scenery.
	draw_rect(Rect2(0, 0, 1280, 90), Color(0.02, 0.04, 0.08, 0.6))
	if screen in ["battle", "paused", "result"]:
		draw_ellipse_shadow(Vector2(battle.hero_x, 517))
		for enemy in battle.enemies:
			if enemy.hp <= 0:
				continue
			draw_ellipse_shadow(Vector2(enemy.x, 517))
			draw_rect(Rect2(enemy.x - 29, 342, 58, 6), Color("492e3b"))
			draw_rect(Rect2(enemy.x - 29, 342, 58 * maxf(0, enemy.hp / enemy.max_hp), 6), Color("df8680"))
		for effect in battle.effects:
			draw_string(ThemeDB.fallback_font, Vector2(effect.x - 15, 370 - (0.65 - effect.ttl) * 50), effect.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("ffe49b") if effect.skill else Color.WHITE)
	if screen == "character":
		draw_character_backdrop()
	if screen not in ["battle", "character"]:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.025, 0.045, 0.08, 0.83))

func refresh_mute() -> void:
	ui.get_node("Mute").text = "Âm: tắt" if audio.muted else "Âm: bật"

func update_hero(delta: float) -> void:
	hero_art.visible = screen in ["battle", "character"]
	hero_art.frozen = screen == "paused"
	if screen == "character":
		hero_art.position = Vector2(380, 530)
		hero_art.scale = Vector2(1.75, 1.75)
		hero_art.preview = true
		hero_art.set_clip(preview_clip)
		return
	hero_art.preview = false
	hero_art.position = Vector2(battle.hero_x, 500)
	hero_art.scale = Vector2(0.72, 0.72)
	if screen != "battle":
		if battle.state == "lost":
			hero_art.set_clip("death")
		return
	skill_visual = maxf(0, skill_visual - delta)
	hurt_visual = maxf(0, hurt_visual - delta)
	if battle.hero_hp < prior_hp:
		hurt_visual = 0.2
	prior_hp = battle.hero_hp
	if battle.state == "lost":
		hero_art.set_clip("death")
	elif battle.state == "won":
		hero_art.set_clip("idle")
	elif skill_visual > 0:
		hero_art.set_clip("skill")
	elif hurt_visual > 0:
		hero_art.set_clip("hurt")
	elif battle.windup > 0 or (battle.hero_timer > 0.04 and battle.intermission == 0):
		hero_art.set_clip("attack")
		hero_art.clock = 0.18 - battle.windup if battle.windup > 0 else 0.18 + (0.48 - battle.hero_timer)
	elif absf(battle.hero_x - prior_x) > 0.01:
		hero_art.set_clip("run")
	else:
		hero_art.set_clip("idle")
	prior_x = battle.hero_x

func clear_preview() -> void:
	for button in preview_buttons:
		button.queue_free()
	preview_buttons.clear()

func show_character() -> void:
	menu.queue_free()
	screen = "character"
	preview_clip = "idle"
	var names := ["Đứng", "Chạy", "Chém kiếm", "Ngân nguyệt", "Trúng đòn", "Ngã xuống"]
	var clips := ["idle", "run", "attack", "skill", "hurt", "death"]
	for i in range(clips.size()):
		var selected: String = clips[i]
		var button := make_button(names[i], Vector2(735 + (i % 2) * 230, 330 + (i / 2) * 74), Vector2(210, 60), func():
			preview_clip = selected
			hero_art.set_clip(selected, true))
		preview_buttons.append(button)
	preview_buttons.append(make_button("Về sảnh", Vector2(735, 590), Vector2(440, 60), to_title))

func draw_character_backdrop() -> void:
	draw_rect(Rect2(690, 100, 540, 555), Color(0.025, 0.06, 0.09, 0.90))
	draw_rect(Rect2(60, 100, 560, 525), Color("142b3a"))
	draw_rect(Rect2(60, 100, 560, 525), Color("8caa9d"), false, 2)
	draw_circle(Vector2(380, 340), 170, Color("1b3c4d"))
	draw_arc(Vector2(380, 340), 188, 0, TAU, 100, Color("426b70"), 2)
	draw_ellipse_shadow(Vector2(380, 572))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(730, 160), "AETHER", HORIZONTAL_ALIGNMENT_LEFT, -1, 52, Color("ebd7a5"))
	draw_string(font, Vector2(735, 202), "KIẾM SĨ NGÂN NGUYỆT", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("8ed9dc"))
	draw_string(font, Vector2(735, 250), "Lưỡi kiếm gìn giữ ánh trăng cuối cùng.", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("d2dfe2"))
	draw_string(font, Vector2(735, 285), "Xem sáu trạng thái của nhân vật", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("93aab6"))

func clear_enemies() -> void:
	for view in enemy_views.values():
		view.queue_free()
	enemy_views.clear()

func update_enemies(delta: float) -> void:
	if screen not in ["battle", "paused"]:
		if not enemy_views.is_empty():
			clear_enemies()
		return
	var active: Dictionary = {}
	for enemy in battle.enemies:
		active[enemy.id] = true
		if not enemy_views.has(enemy.id):
			var view := EnemyArt.new()
			art_layer.add_child(view)
			enemy_views[enemy.id] = view
		var view: Node2D = enemy_views[enemy.id]
		view.visible = screen == "battle"
		if screen == "battle":
			view.sync(enemy, delta if battle.state == "playing" else 0.0, battle.hero_x)
	for id in enemy_views.keys():
		if active.has(id):
			continue
		var view: Node2D = enemy_views[id]
		view.visible = screen == "battle"
		if screen == "battle" and view.fade_death(delta):
			view.queue_free()
			enemy_views.erase(id)
