extends Node2D

const BACKGROUND = preload("res://assets/world/moon_ruins.png")
const BossArt = preload("res://game/boss_art.gd")
const EnemyArt = preload("res://game/enemy_art.gd")
const BattleModel = preload("res://game/battle.gd")
var battle = BattleModel.new()
var screen := "title"
var ui: Control
var status: Label
var skill_button: Button
var party_size := 5
var auto_skills := false
var skill_buttons: Array[Button] = []
var companion_views: Array[Node2D] = []
var auto_button: Button
var pause_button: Button
var menu: VBoxContainer
var audio: Node
var hero_art: Node2D
var companion_preview: Node2D
var preview_index := 0
var preview_skill_button: Button
const PartyData = preload("res://game/party_data.gd")
var feedback: Node2D
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
	art_layer.y_sort_enabled = true
	add_child(art_layer)
	hero_art = preload("res://game/hero_art.gd").new()
	art_layer.add_child(hero_art)
	companion_preview = preload("res://game/companion_art.gd").new()
	companion_preview.configure("brann")
	companion_preview.visible = false
	art_layer.add_child(companion_preview)
	feedback = preload("res://game/combat_feedback.gd").new()
	feedback.model = battle
	feedback.z_index = 3
	add_child(feedback)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var layer := CanvasLayer.new()
	add_child(layer)
	layer.add_child(ui)
	var mute_button := make_button("Âm: bật", Vector2(40, 650), Vector2(170, 50), func():
		audio.toggle_mute()
		refresh_mute())
	mute_button.name = "Mute"
	refresh_mute()
	status = Label.new()
	status.position = Vector2(40, 28)
	status.add_theme_font_size_override("font_size", 25)
	ui.add_child(status)
	for i in range(5):
		var slot := i
		var button := make_button("", Vector2(30 + i * 248, 550), Vector2(232, 90), func(): use_party_skill(slot))
		button.add_theme_font_size_override("font_size", 18)
		skill_buttons.append(button)
	skill_button = skill_buttons[0]
	auto_button = make_button("Kỹ năng: tay", Vector2(940, 650), Vector2(290, 50), func():
		auto_skills = not auto_skills)
	for i in range(1, 5):
		var view := preload("res://game/companion_art.gd").new()
		art_layer.add_child(view)
		companion_views.append(view)
	pause_button = make_button("Tạm dừng", Vector2(1060, 25), Vector2(170, 52), toggle_pause)
	show_menu("KIẾM HÀNH", "ĐỘI HÌNH · 0.4.1\nNăm vai trò · Ba đợt quái và boss\nChạm kỹ năng hoặc bật tự động", "Bắt đầu", begin)
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
		var formation := Button.new()
		formation.text = "Đội hình: %d/5 · chạm để đổi số tướng" % party_size
		formation.custom_minimum_size.y = 52
		formation.pressed.connect(func():
			party_size = party_size % 5 + 1
			formation.text = "Đội hình: %d/5 · chạm để đổi số tướng" % party_size)
		menu.add_child(formation)
		var character := Button.new()
		character.text = "Xem nhân vật · 5 tướng"
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
	battle.start(party_size)
	result_delay = 0
	skill_visual = 0
	hurt_visual = 0
	prior_hp = battle.hero_hp
	prior_x = battle.hero_x
	hero_art.set_clip("idle", true)
	clear_preview()
	clear_enemies()
	for i in range(companion_views.size()):
		companion_views[i].configure(PartyData.HEROES[i + 1].id)

func to_title() -> void:
	clear_enemies()
	clear_preview()
	screen = "title"
	battle.state = "idle"
	show_menu("KIẾM HÀNH", "Đánh thường tự động · Kỹ năng riêng từng tướng\n1 Aether · 2 Brann · 3 Lyra · 4 Nyx · 5 Sol", "Bắt đầu", begin)

func use_skill() -> void:
	use_party_skill(0)

func use_party_skill(slot: int) -> void:
	if battle.skill(slot) and slot == 0:
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
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
			use_party_skill(event.keycode - KEY_1)
		elif event.keycode == KEY_ESCAPE:
			toggle_pause()

func _process(delta: float) -> void:
	if auto_skills and screen == "battle" and battle.state == "playing":
		# Shield before damage; heal only after an ally actually needs it.
		for slot in [1, 4, 0, 2, 3]:
			if slot >= battle.heroes.size():
				continue
			if slot == 4 and not battle.heroes.any(func(a): return a.hp > 0 and a.hp <= a.max_hp - 30):
				continue
			use_party_skill(slot)
	battle.tick(minf(delta, 0.05))
	update_companions()
	update_hero(delta)
	update_enemies(minf(delta, 0.05))
	if screen == "battle" and battle.state in ["won", "lost"]:
		result_delay += delta
	if screen == "battle" and battle.state in ["won", "lost"] and result_delay >= 0.85:
		screen = "result"
		show_menu("CHIẾN THẮNG" if battle.state == "won" else "THẤT BẠI", "Hạ %d địch · Chặng %d/4 · %.1f giây\nBản thử chưa có phần thưởng hoặc lưu tiến trình" % [battle.kills, battle.wave, battle.elapsed], "Chơi lại", begin)
	feedback.visible = screen == "battle"
	feedback.queue_redraw()
	status.visible = screen in ["battle", "paused"]
	auto_button.visible = screen == "battle"
	auto_button.text = "Kỹ năng: tự động" if auto_skills else "Kỹ năng: tay"
	for i in range(skill_buttons.size()):
		var button := skill_buttons[i]
		button.visible = screen == "battle" and i < battle.heroes.size()
		if i >= battle.heroes.size():
			continue
		var actor: Dictionary = battle.heroes[i]
		button.disabled = battle.state != "playing" or actor.hp <= 0 or actor.cooldown_left > 0 or battle.intermission > 0 or battle.target_index() < 0
		var timing := "%.1fs" % actor.cooldown_left if actor.cooldown_left > 0 else "Sẵn sàng"
		if actor.hp <= 0:
			timing = "Đã gục"
		button.text = "%d · %s  %d/%d HP\n%s · %s" % [i + 1, actor.name, ceili(actor.hp), int(actor.max_hp), actor.skill, timing]
	pause_button.visible = screen == "battle"
	status.text = ("BOSS" if battle.wave == 4 else "ĐỢT %d / 3" % battle.wave) + "      ĐỘI %d/%d · %.1fs" % [battle.heroes.filter(func(a): return a.hp > 0).size(), battle.heroes.size(), battle.elapsed]
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
			if enemy.get("boss", false):
				draw_boss_hud(enemy)
				continue
			draw_rect(Rect2(enemy.x - 29, 342, 58, 6), Color("492e3b"))
			draw_rect(Rect2(enemy.x - 29, 342, 58 * maxf(0, enemy.hp / enemy.max_hp), 6), Color("df8680"))
	if screen == "character":
		draw_character_backdrop()
	if screen not in ["battle", "character"]:
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.025, 0.045, 0.08, 0.83))

func refresh_mute() -> void:
	ui.get_node("Mute").text = "Âm: tắt" if audio.muted else "Âm: bật"

func update_hero(delta: float) -> void:
	hero_art.visible = screen == "battle" or (screen == "character" and preview_index == 0)
	companion_preview.visible = screen == "character" and preview_index > 0
	hero_art.frozen = screen == "paused"
	if screen == "character":
		companion_preview.position = Vector2(380, 530)
		companion_preview.scale = Vector2(1.75, 1.75)
		companion_preview.preview = true
		companion_preview.frozen = false
		companion_preview.set_clip(preview_clip)
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
	if battle.hero_hp <= 0:
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
	var names := ["Đứng", "Chạy", "Đánh thường", PartyData.HEROES[preview_index].skill, "Trúng đòn", "Ngã xuống"]
	var clips := ["idle", "run", "attack", "skill", "hurt", "death"]
	for i in range(clips.size()):
		var selected: String = clips[i]
		var button := make_button(names[i], Vector2(735 + (i % 2) * 230, 330 + (i / 2) * 74), Vector2(210, 60), func():
			preview_clip = selected
			active_preview().set_clip(selected, true))
		if i == 3:
			preview_skill_button = button
		preview_buttons.append(button)
	for i in range(5):
		var selected_index := i
		var button := make_button(PartyData.HEROES[i].name, Vector2(715 + i * 100, 110), Vector2(94, 48), func(): select_character(selected_index))
		button.add_theme_font_size_override("font_size", 18)
		preview_buttons.append(button)
	select_character(preview_index)
	preview_buttons.append(make_button("Về sảnh", Vector2(735, 590), Vector2(440, 60), to_title))

func draw_character_backdrop() -> void:
	draw_rect(Rect2(690, 100, 540, 555), Color(0.025, 0.06, 0.09, 0.90))
	draw_rect(Rect2(60, 100, 560, 525), Color("142b3a"))
	draw_rect(Rect2(60, 100, 560, 525), Color("8caa9d"), false, 2)
	draw_circle(Vector2(380, 340), 170, Color("1b3c4d"))
	draw_arc(Vector2(380, 340), 188, 0, TAU, 100, Color("426b70"), 2)
	draw_ellipse_shadow(Vector2(380, 572))
	var font := ThemeDB.fallback_font
	var data: Dictionary = PartyData.HEROES[preview_index]
	var stories := ["Lưỡi kiếm gìn giữ ánh trăng cuối cùng.", "Tấm khiên đứng vững trước màn đêm.", "Mũi tên dẫn lối qua rừng sao.", "Tinh hỏa soi những vì sao đã tắt.", "Ánh bình minh gọi đồng đội đứng vững."]
	draw_string(font, Vector2(730, 220), data.name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 48, Color(data.color))
	draw_string(font, Vector2(735, 256), data.role + " · " + data.skill, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color("d2dfe2"))
	draw_string(font, Vector2(735, 290), stories[preview_index], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("d2dfe2"))
	draw_string(font, Vector2(735, 318), "Xem sáu trạng thái của nhân vật", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("93aab6"))

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
			var view: Node2D = BossArt.new() if enemy.get("boss", false) else EnemyArt.new()
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

func draw_boss_hud(enemy: Dictionary) -> void:
	draw_rect(Rect2(310, 90, 660, 100), Color(0.04, 0.02, 0.08, 0.85))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(330, 117), "KỴ SĨ NGUYỆT THỰC · GIAI ĐOẠN %d" % enemy.phase, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("e2b9ed"))
	draw_rect(Rect2(330, 128, 620, 15), Color("36263e"))
	draw_rect(Rect2(330, 128, 620 * maxf(0, enemy.hp / enemy.max_hp), 15), Color("a75ec2"))
	var label := "%d / %d HP" % [ceili(enemy.hp), int(enemy.max_hp)]
	if enemy.windup > 0:
		label += "  ·  " + enemy.attack_name
	draw_string(font, Vector2(330, 172), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ead7f0"))

func update_companions() -> void:
	for i in range(companion_views.size()):
		var view := companion_views[i]
		view.visible = screen == "battle" and i + 1 < battle.heroes.size()
		view.frozen = screen != "battle" or battle.state != "playing"
		if i + 1 < battle.heroes.size():
			view.sync(battle.heroes[i + 1], minf(get_process_delta_time(), 0.05), screen != "battle", battle.state in ["won", "lost"])
			var offsets := [Vector2(30, 455), Vector2(-30, 480), Vector2(0, 500), Vector2(40, 520)]
			view.position = Vector2(view.actor.x + offsets[i].x, offsets[i].y)
			view.scale = Vector2(0.72, 0.72)

func active_preview() -> Node2D:
	return hero_art if preview_index == 0 else companion_preview

func select_character(index: int) -> void:
	preview_index = index
	preview_clip = "idle"
	if index > 0:
		companion_preview.configure(PartyData.HEROES[index].id)
	active_preview().set_clip("idle", true)
	preview_skill_button.text = PartyData.HEROES[index].skill
