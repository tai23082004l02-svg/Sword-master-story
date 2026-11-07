extends Node2D

const BACKGROUND = preload("res://assets/world/moon_ruins.png")
const BossArt = preload("res://game/boss_art.gd")
const EnemyArt = preload("res://game/enemy_art.gd")
const BattleModel = preload("res://game/battle.gd")
const Campaign = preload("res://game/campaign_data.gd")
const Progress = preload("res://game/campaign_progress.gd")
const CampaignUI = preload("res://game/rpg_ui.gd")
const RPG = preload("res://game/rpg_data.gd")
var chapter_page := 0
var rpg_index := 0
var rpg_page := 0
var rpg_section := ""
var activity_mode := ""
var trial_index := -1
var battle_snapshots: Array = []
var progress = Progress.new()
var campaign_panel: Control
var wallet: Label
var campaign_active := false
var selected_stage := 1
var run_id := -1
var receipt: Dictionary = {}
var settlement_attempted := false
var battle_roster: Array[int] = []
var battle_equipment: Array = []
var battle_levels: Array[int] = []
var growth_index := 0
var growth_return := "title"
var battle_stage: Dictionary = {}
var battle_stage_id := 0
var battle = BattleModel.new()
var screen := "title"
var ui: Control
var progress_error := ""
var progress_error_until := 0
var status: Label
var skill_button: Button
var party_size := 5
var auto_skills := false
var skill_buttons: Array[Button] = []
var companion_views: Array[Node2D] = []
var auto_button: Button
var battle_speed := 1
var speed_button: Button
var pause_button: Button
var menu: VBoxContainer
var audio_settings_button: Button
var audio_dialog: ConfirmationDialog
var audio: Node
var hero_art: Node2D
var companion_preview: Node2D
var preview_index := 0
var preview_step := -1
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
	progress.load_game()
	auto_skills = progress.data.auto_skills
	party_size = progress.formation().size()
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
	audio_settings_button = make_button("Âm lượng", Vector2(230, 650), Vector2(170, 50), open_audio_settings)
	status = Label.new()
	status.position = Vector2(40, 28)
	status.add_theme_font_size_override("font_size", 25)
	ui.add_child(status)
	for i in range(5):
		var slot := i
		var button := make_button("", Vector2(30 + i * 248, 550), Vector2(232, 90), func(): use_party_skill(slot))
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_color_override("font_disabled_color", Color("b8cbd7"))
		var card := StyleBoxFlat.new()
		card.bg_color = Color(0.025, 0.07, 0.11, 0.94)
		card.border_color = Color("3b6178")
		card.set_border_width_all(1)
		card.set_corner_radius_all(8)
		button.add_theme_stylebox_override("normal", card)
		button.add_theme_stylebox_override("disabled", card)
		var hover: StyleBoxFlat = card.duplicate()
		hover.bg_color = Color("244b5c")
		button.add_theme_stylebox_override("hover", hover)
		skill_buttons.append(button)
	skill_button = skill_buttons[0]
	auto_button = make_button("Kỹ năng: tay", Vector2(940, 650), Vector2(290, 50), func(): set_auto_mode(not auto_skills))
	for i in range(1, 5):
		var view := preload("res://game/companion_art.gd").new()
		art_layer.add_child(view)
		companion_views.append(view)
	wallet = Label.new()
	wallet.position = Vector2(40, 28)
	wallet.add_theme_font_size_override("font_size", 22)
	ui.add_child(wallet)
	speed_button = make_button("Tốc độ: x1", Vector2(230, 650), Vector2(200, 50), cycle_battle_speed)
	speed_button.visible = false
	pause_button = make_button("Tạm dừng", Vector2(1060, 25), Vector2(170, 52), toggle_pause)
	show_menu("KIẾM HÀNH", title_subtitle(), "Chọn ải", open_stages)
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
		character.text = "Xem nhân vật · 5 tướng"
		character.custom_minimum_size.y = 60
		character.add_theme_font_size_override("font_size", 23)
		character.pressed.connect(show_character)
		menu.add_child(character)
		var growth := Button.new()
		growth.text = "Nâng tướng"
		growth.custom_minimum_size.y = 56
		growth.disabled = progress.read_only
		growth.add_theme_font_size_override("font_size", 23)
		growth.pressed.connect(func(): open_growth())
		menu.add_child(growth)
		var gear := Button.new()
		gear.text = "Trang bị"
		gear.custom_minimum_size.y = 50
		gear.add_theme_font_size_override("font_size", 23)
		gear.pressed.connect(func(): open_equipment())
		menu.add_child(gear)
		if progress.read_only:
			var retry := Button.new()
			retry.text = "Thử tải lại tiến trình"
			retry.custom_minimum_size.y = 50
			retry.pressed.connect(func():
				progress.load_game()
				to_title())
			menu.add_child(retry)
	if screen == "title":
		menu.visible = false
		clear_campaign_panel()
		campaign_panel = CampaignUI.new(self)
		ui.add_child(campaign_panel)
		campaign_panel.lobby()
	if screen == "paused":
		var home := Button.new()
		home.text = "Về sảnh"
		home.custom_minimum_size.y = 55
		home.pressed.connect(to_title)
		menu.add_child(home)

func begin() -> void:
	clear_campaign_panel()
	if is_instance_valid(menu):
		menu.queue_free()
		menu = null
	screen = "battle"
	if campaign_active:
		battle.start(battle_roster.size(), battle_roster, battle_stage, battle_levels, battle_equipment, battle_snapshots)
	else:
		if trial_index >= 0:
			var trial_stage := Campaign.stage(1)
			trial_stage.tactics = true
			battle.start(party_size,[0,trial_index] if trial_index>0 else [0],trial_stage)
		else: battle.start(party_size)
	result_delay = 0
	skill_visual = 0
	hurt_visual = 0
	prior_hp = battle.hero_hp
	prior_x = battle.hero_x
	hero_art.set_clip("idle", true)
	clear_preview()
	clear_enemies()
	for i in range(companion_views.size()):
		if i + 1 < battle.heroes.size():
			companion_views[i].configure(battle.heroes[i + 1].id)

func to_title() -> void:
	trial_index = -1
	if campaign_active and not progress.data.pending.is_empty():
		if not progress.abandon_run(run_id):
			show_progress_error()
			return
	campaign_active = false
	clear_campaign_panel()
	clear_enemies()
	clear_preview()
	screen = "title"
	battle.state = "idle"
	show_menu("KIẾM HÀNH", title_subtitle(), "Chọn ải", open_stages)

func use_skill() -> void:
	use_party_skill(0)

func use_party_skill(slot: int) -> void:
	if battle.skill(slot) and slot == 0:
		skill_visual = 0.48
		hero_art.set_clip("skill", true)

func toggle_pause() -> void:
	if screen == "battle" and battle.state == "playing":
		audio.stop_all()
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

func cycle_battle_speed() -> void:
	if screen != "battle" or battle.state != "playing": return
	battle_speed = battle_speed % 3 + 1
	speed_button.text = "Tốc độ: x%d" % battle_speed

func advance_battle(delta: float) -> void:
	# Repeat bounded steps so x3 never skips windups, heals or auto-skill checks.
	if screen != "battle" or battle.state != "playing": return
	for step in range(battle_speed):
		if battle.state != "playing": break
		if auto_skills:
			for id in ["brann", "sol", "aether", "lyra", "nyx"]:
				for slot in range(battle.heroes.size()):
					if battle.heroes[slot].id != id: continue
					if id == "sol" and not battle.heroes.any(func(a): return a.hp > 0 and a.hp <= a.max_hp - 30): continue
					use_party_skill(slot)
		battle.tick(minf(delta, 0.05))

func _process(delta: float) -> void:
	advance_battle(delta)
	var visual_delta := minf(delta, 0.05) * battle_speed if screen == "battle" else 0.0
	hero_art.playback_speed = float(battle_speed) if screen == "battle" else 1.0
	update_companions(visual_delta)
	update_hero(visual_delta)
	update_enemies(visual_delta)
	if screen == "battle" and battle.state in ["won", "lost"]:
		if campaign_active and not settlement_attempted:
			settle_campaign()
		result_delay += delta
	if screen == "battle" and battle.state in ["won", "lost"] and result_delay >= 0.85:
		screen = "result"
		if campaign_active:
			show_campaign_result()
		else:
			show_menu("CHIẾN THẮNG" if battle.state == "won" else "THẤT BẠI", "Hạ %d địch · %.1f giây\nTrận luyện · Không tính thưởng" % [battle.kills, battle.elapsed], "Chơi lại", begin)
	audio_settings_button.visible = screen in ["title", "paused"]
	wallet.visible = screen in ["title", "stages", "prepare", "result", "growth", "equipment", "rpg"]
	wallet.text = "Tiến trình đang khóa · " + progress.last_error if progress.read_only else "Vàng: %d     XP hành trình: %d     Đã vượt: %d/30" % [progress.data.gold, progress.data.xp, progress.data.cleared.size()]
	if progress.recovered and not progress.read_only:
		wallet.text += " · Đã mở bản dự phòng"
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
		button.text = "%d · %s · Cấp %d\n%d/%d HP · %s\n%s" % [i + 1, actor.name, actor.level, ceili(actor.hp), int(actor.max_hp), actor.skill, timing]
	speed_button.visible = screen == "battle"
	speed_button.disabled = battle.state != "playing"
	speed_button.text = "Tốc độ: x%d" % battle_speed
	pause_button.visible = screen == "battle"
	status.text = ((battle_stage.title + " · ") if activity_mode != "" and campaign_active else ((Campaign.label(battle_stage_id) + " · ") if campaign_active else "")) + ("BOSS" if battle.wave > 0 and battle.boss_wave() else "ĐỢT %d / %d" % [battle.wave, battle.wave_limit]) + "      ĐỘI %d/%d · %.1fs" % [battle.heroes.filter(func(a): return a.hp > 0).size(), battle.heroes.size(), battle.elapsed]
	if Time.get_ticks_msec() < progress_error_until: status.text = "Chưa lưu: " + progress_error
	queue_redraw()

func draw_ellipse_shadow(pos: Vector2) -> void:
	draw_set_transform(pos, 0, Vector2(1, 0.25))
	draw_circle(Vector2.ZERO, 34, Color(0, 0, 0, 0.3))
	draw_set_transform(Vector2.ZERO)

func _draw() -> void:
	var chapter_tint := Color.WHITE
	if campaign_active:
		chapter_tint = [Color.WHITE,Color("ffc393"),Color("cbddff")][RPG.chapter(int(battle_stage.get("id",1)))-1]
	draw_texture_rect(BACKGROUND, Rect2(0, 0, 1280, 720), false,chapter_tint)
	# Subtle vignette strips preserve HUD readability over painted scenery.
	draw_rect(Rect2(0, 0, 1280, 90), Color(0.02, 0.04, 0.08, 0.6))
	if screen in ["battle", "paused"]:
		draw_ellipse_shadow(Vector2(battle.hero_x, 517))
		for enemy in battle.enemies:
			if enemy.hp <= 0:
				continue
			draw_ellipse_shadow(Vector2(enemy.x, 517))
			if enemy.get("boss", false):
				draw_boss_hud(enemy)
				continue
			var role: String = {"armored":"GIÁP","healer":"HỒI MÁU","assassin":"SÁT THỦ"}.get(enemy.get("kind",""),"")
			if role != "": draw_string(ThemeDB.fallback_font,Vector2(enemy.x-45,330),role,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("edce92"))
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
		companion_preview.frozen = preview_step >= 0
		companion_preview.frame_override = preview_step
		hero_art.frozen = preview_step >= 0
		hero_art.frame_override = preview_step
		companion_preview.set_clip(preview_clip)
		hero_art.position = Vector2(380, 530)
		hero_art.scale = Vector2(1.75, 1.75)
		hero_art.preview = true
		hero_art.set_clip(preview_clip)
		return
	hero_art.frame_override = -1
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
			preview_step = -1
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
	preview_buttons.append(make_button("Frame trước", Vector2(75, 590), Vector2(160, 48), func(): step_preview(-1)))
	preview_buttons.append(make_button("Phát lại", Vector2(250, 590), Vector2(150, 48), func():
		preview_step = -1
		active_preview().set_clip(preview_clip, true)))
	preview_buttons.append(make_button("Frame sau", Vector2(415, 590), Vector2(160, 48), func(): step_preview(1)))
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
	draw_string(font, Vector2(735, 318), "Frame %02d / %02d" % [active_preview().frame_index() - int(hero_art.CLIPS[preview_clip][0]) + 1, int(hero_art.CLIPS[preview_clip][1])], HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("93aab6"))

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
	draw_string(font, Vector2(330, 117), "%s · GIAI ĐOẠN %d" % [["KỴ SĨ NGUYỆT THỰC","HỘ VỆ TRO HỒNG","TƯỚNG THÀNH BÌNH MINH"][int(enemy.get("variant",0))],enemy.phase], HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("e2b9ed"))
	draw_rect(Rect2(330, 128, 620, 15), Color("36263e"))
	draw_rect(Rect2(330, 128, 620 * maxf(0, enemy.hp / enemy.max_hp), 15), Color("a75ec2"))
	var label := "%d / %d HP" % [ceili(enemy.hp), int(enemy.max_hp)]
	if enemy.windup > 0:
		label += "  ·  " + enemy.attack_name
	draw_string(font, Vector2(330, 172), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("ead7f0"))

func update_companions(delta: float = -1.0) -> void:
	if delta < 0: delta = minf(get_process_delta_time(), 0.05)
	for i in range(companion_views.size()):
		var view := companion_views[i]
		view.visible = screen == "battle" and i + 1 < battle.heroes.size()
		view.frozen = screen != "battle" or battle.state != "playing"
		if i + 1 < battle.heroes.size():
			view.sync(battle.heroes[i + 1], delta, screen != "battle", battle.state in ["won", "lost"])
			var offsets := {"brann": Vector2(30, 455), "lyra": Vector2(-30, 480), "nyx": Vector2(0, 500), "sol": Vector2(40, 520)}
			var offset: Vector2 = offsets.get(view.actor.id, Vector2(0,480))
			view.position = Vector2(view.actor.x + offset.x, offset.y)
			view.scale = Vector2(0.72, 0.72)

func active_preview() -> Node2D:
	return hero_art if preview_index == 0 else companion_preview

func select_character(index: int) -> void:
	preview_step = -1
	preview_index = index
	preview_clip = "idle"
	if index > 0:
		companion_preview.configure(PartyData.HEROES[index].id)
	active_preview().set_clip("idle", true)
	preview_skill_button.text = PartyData.HEROES[index].skill

func step_preview(direction: int) -> void:
	var count: int = hero_art.CLIPS[preview_clip][1]
	var current: int = active_preview().frame_index() - int(hero_art.CLIPS[preview_clip][0])
	preview_step = posmod(current + direction, count)

func clear_campaign_panel() -> void:
	if is_instance_valid(campaign_panel):
		campaign_panel.visible = false
		campaign_panel.queue_free()
		campaign_panel = null

func new_campaign_panel() -> void:
	clear_campaign_panel()
	if is_instance_valid(menu):
		menu.queue_free()
		menu = null
	clear_preview()
	campaign_panel = CampaignUI.new(self)
	ui.add_child(campaign_panel)

func open_stages() -> void:
	if campaign_active and not progress.data.pending.is_empty():
		if not progress.abandon_run(run_id):
			show_progress_error()
			return
	campaign_active = false
	battle.state = "idle"
	clear_enemies()
	screen = "stages"
	new_campaign_panel()
	campaign_panel.stages()

func prepare_stage(id: int) -> void:
	if id < 1 or id > progress.unlocked(): return
	selected_stage = id
	campaign_active = false
	battle.state = "idle"
	clear_enemies()
	screen = "prepare"
	new_campaign_panel()
	campaign_panel.prepare(id)

func select_companion(id: int) -> void:
	if id < 1 or id >= RPG.HERO_COUNT or screen != "prepare" or not progress.data.rpg.recruited[id]: return
	if not id in progress.formation() and progress.formation().size() >= 5:
		campaign_panel.message("Đội đã đủ 5 tướng. Bỏ một đồng đội trước khi thêm.")
		return
	var roster: Array[int] = progress.formation()
	if id in roster: roster.erase(id)
	else: roster.append(id)
	if progress.set_formation(roster):
		party_size = roster.size()
		prepare_stage(selected_stage)
	else:
		campaign_panel.message(progress.last_error)

func reorder_companion(id: int, target_id: int) -> bool:
	if screen != "prepare": return false
	var roster: Array[int] = progress.formation()
	var old := roster.find(id)
	var target := roster.find(target_id)
	if old < 1 or target < 1 or old == target: return false
	roster.remove_at(old)
	roster.insert(target, id)
	if progress.set_formation(roster):
		prepare_stage(selected_stage)
		return true
	campaign_panel.message(progress.last_error)
	return false

func set_auto_mode(value: bool) -> void:
	if progress.set_auto(value):
		auto_skills = value
	else:
		show_progress_error()

func show_progress_error() -> void:
	if is_instance_valid(campaign_panel):
		campaign_panel.message(progress.last_error)
	elif screen == "battle":
		progress_error = progress.last_error
		progress_error_until = Time.get_ticks_msec()+4000
	elif screen == "paused" and is_instance_valid(menu):
		for child in menu.get_children():
			if child is Label:
				child.text = progress.last_error
				break

func start_campaign(id: int) -> void:
	if id < 1 or id > progress.unlocked() or progress.read_only: return
	var token: int = progress.begin_run(id)
	if token < 0:
		if is_instance_valid(campaign_panel): campaign_panel.message(progress.last_error)
		return
	selected_stage = id
	battle_stage_id = id
	activity_mode = ""
	trial_index = -1
	battle_stage = Campaign.stage(id)
	battle_stage.tactics = true
	battle_roster = progress.formation()
	battle_levels = progress.levels(true)
	battle_snapshots = []
	for i in range(RPG.HERO_COUNT): battle_snapshots.append(progress.hero_stats(i).duplicate(true))
	battle_equipment = progress.data.equipment.duplicate(true)
	party_size = battle_roster.size()
	campaign_active = true
	run_id = token
	receipt = {}
	settlement_attempted = false
	begin()

func show_campaign_result() -> void:
	if not campaign_active or battle.state not in ["won", "lost"]: return
	if not receipt.get("ok", false):
		settle_campaign()
	screen = "result"
	new_campaign_panel()
	if activity_mode != "": campaign_panel.activity_result(receipt)
	else: campaign_panel.result(receipt)

func settle_campaign() -> void:
	settlement_attempted = true
	receipt = progress.finish_run(run_id, battle.state == "won", battle.elapsed, battle.heroes.filter(func(a): return a.hp > 0).size())

func open_growth(origin: String = "title", index: int = -1) -> void:
	if screen not in ["title", "prepare", "growth"]: return
	growth_return = origin
	if index >= 0 and index < 5: growth_index = index
	campaign_active = false
	battle.state = "idle"
	clear_enemies()
	screen = "growth"
	new_campaign_panel()
	campaign_panel.growth(growth_index, growth_return)

func close_growth() -> void:
	if growth_return == "prepare": prepare_stage(selected_stage)
	else: to_title()

func upgrade_selected(index: int, expected_level: int) -> void:
	if screen != "growth" or index != growth_index: return
	var outcome: Dictionary = progress.upgrade_hero(index, expected_level)
	open_growth(growth_return, index)
	campaign_panel.message("Đã nâng %s lên cấp %d." % [PartyData.HEROES[index].name, outcome.level] if outcome.ok else outcome.error, outcome.ok)

func open_equipment(origin: String = "title", index: int = 0) -> void:
	if screen not in ["title", "prepare", "equipment", "growth"]: return
	growth_return = origin
	growth_index = index
	screen = "equipment"
	new_campaign_panel()
	campaign_panel.equipment(index, origin)

func change_equipment(id: String, slot: String = "") -> void:
	if screen != "equipment": return
	var ok: bool = progress.buy_equipment(id) if slot == "" else progress.equip_item(growth_index, slot, id)
	var error: String = progress.last_error
	open_equipment(growth_return, growth_index)
	campaign_panel.message("Đã lưu trang bị." if ok else error, ok)

func title_subtitle() -> String:
	return "CHƯƠNG I · %s\nBa chương · 30 ải\nChiến đấu, nhận thưởng và mở đường đi tiếp" % ProjectSettings.get_setting("application/config/version", "")

func open_audio_settings() -> void:
	if screen not in ["title", "paused"] or is_instance_valid(audio_dialog): return
	audio_dialog = preload("res://game/audio_settings.gd").new(audio)
	ui.add_child(audio_dialog)
	audio_dialog.visibility_changed.connect(func():
		if not audio_dialog.visible: refresh_mute())
	audio_dialog.popup_centered()

func open_rpg(section: String, index: int = -1) -> void:
	if screen == "battle": return
	if section == "stages": open_stages(); return
	if section == "team": prepare_stage(progress.unlocked()); return
	if campaign_active and not progress.data.pending.is_empty():
		if not progress.abandon_run(run_id):
			show_progress_error()
			return
	campaign_active = false
	battle.state = "idle"
	clear_enemies()
	screen = "rpg"
	rpg_section = section
	if index >= 0 and index < RPG.HERO_COUNT: rpg_index = index
	new_campaign_panel()
	match section:
		"heroes": campaign_panel.heroes(rpg_index)
		"inventory":
			rpg_page = mini(rpg_page,maxi(0,int((progress.data.rpg.inventory.size()-1)/6)))
			campaign_panel.inventory(rpg_index,rpg_page)
		"summon": campaign_panel.summon_page()
		"dungeons": campaign_panel.dungeons()
		"goals": campaign_panel.goals()
		"stats": campaign_panel.stats_page()

func rpg_action(action: String, index: int = 0, value: int = 0) -> void:
	if screen != "rpg": return
	var ok := false
	match action:
		"level":
			var outcome: Dictionary = progress.upgrade_hero(index,value)
			ok = outcome.get("ok",false)
			if not ok: progress.last_error = outcome.get("error","Chưa thể nâng tướng.")
		"skill": ok = progress.train_skill(index,value)
		"recruit": ok = progress.recruit(index)
		"ascend": ok = progress.ascend(index)
		"wishlist": ok = progress.set_wishlist(index)
		"equip": ok = progress.equip_loot(index,value)
		"unequip":
			var item: Dictionary = RPG.find_item(progress.data.rpg,value)
			if not item.is_empty(): ok = progress.unequip_loot(index,RPG.ITEMS[item.base].slot)
		"enhance": ok = progress.enhance_loot(index,value)
		"dismantle": ok = progress.dismantle_loot(index)
		"weekly": ok = progress.claim_weekly()
	var error: String = progress.last_error
	open_rpg(rpg_section)
	campaign_panel.message("Đã lưu thay đổi." if ok else error,ok)

func confirm_dismantle(uid: int) -> void:
	if screen != "rpg": return
	var item: Dictionary = RPG.find_item(progress.data.rpg,uid)
	if item.is_empty(): return
	var dialog := ConfirmationDialog.new()
	dialog.title = "Phân giải trang bị"
	dialog.dialog_text = "Phân giải%s +%d thành %d bụi? Không thể hoàn tác." % [RPG.ITEMS[item.base].name,item.rank,5+item.rank*3]
	dialog.ok_button_text = "Phân giải"
	dialog.cancel_button_text = "Hủy"
	dialog.confirmed.connect(func(): rpg_action("dismantle",uid))
	dialog.visibility_changed.connect(func():
		if not dialog.visible: dialog.queue_free())
	ui.add_child(dialog)
	dialog.popup_centered(Vector2i(650,200))

func rpg_summon(count: int) -> void:
	if screen != "rpg" or rpg_section != "summon": return
	var outcome: Dictionary = progress.summon(count)
	open_rpg("summon")
	if not outcome.ok: campaign_panel.message(outcome.error); return
	var lines: PackedStringArray = []
	for result in outcome.results:
		lines.append("%s +%d mảnh%s" % [PartyData.HEROES[int(result.hero)].name,result.shards," · MỞ TƯỚNG" if result.new else ""])
	var dialog := AcceptDialog.new()
	dialog.title = "Kết quả triệu hồi · Đã lưu"
	dialog.dialog_text = "\n".join(lines)
	dialog.visibility_changed.connect(func():
		if not dialog.visible: dialog.queue_free())
	ui.add_child(dialog)
	dialog.popup_centered(Vector2i(650,450))

func rpg_goal(id: String) -> void:
	for goal in RPG.GOALS:
		if goal.id != id: continue
		if progress.goal_value(goal) >= goal.target:
			var ok: bool = progress.claim_goal(id)
			var error: String = progress.last_error
			open_rpg("goals")
			campaign_panel.message("Đã nhận thưởng." if ok else error,ok)
		elif goal.kind == "enhance": open_rpg("inventory")
		elif goal.kind == "summons": open_rpg("summon")
		else: prepare_stage(progress.unlocked())
		return

func rpg_sweep(id: int) -> void:
	if screen != "prepare": return
	var result: Dictionary = progress.sweep(id,1)
	prepare_stage(id)
	campaign_panel.message("Đã quét: +%d vàng +%d XP +%d món +%d bụi." % [result.gold,result.xp,result.items,result.dust] if result.ok else result.error,result.ok)

func start_activity(mode: String) -> void:
	var token: int = progress.begin_activity(mode)
	if token < 0:
		if is_instance_valid(campaign_panel): campaign_panel.message("Vượtải 1-05 để mở hầm hoặc kiểm tra tiến trình lưu.")
		return
	activity_mode = mode
	trial_index = -1
	selected_stage = 1
	battle_stage_id = 1
	battle_stage = progress.activity_stage(mode,int(progress.data.pending.floor))
	battle_roster = progress.formation()
	battle_levels = progress.levels(true)
	battle_equipment = progress.data.equipment.duplicate(true)
	battle_snapshots = []
	for i in range(RPG.HERO_COUNT): battle_snapshots.append(progress.hero_stats(i).duplicate(true))
	party_size = battle_roster.size()
	campaign_active = true
	run_id = token
	receipt = {}
	settlement_attempted = false
	begin()

func start_trial(index: int) -> void:
	if index<0 or index>=RPG.HERO_COUNT or screen!="rpg": return
	campaign_active=false
	activity_mode=""
	trial_index=index
	party_size=2 if index>0 else 1
	begin()
