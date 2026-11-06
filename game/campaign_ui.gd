extends Control
## Campaign presentation. Progression and rewards are committed by the model.
const Campaign = preload("res://game/campaign_data.gd")
const Party = preload("res://game/party_data.gd")
var host
var notice: Label
func _init(controller = null) -> void:
	host = controller
func text(value: String, pos: Vector2, size: Vector2, font_size: int = 22, color := Color("dce8ef")) -> Label:
	var label := Label.new()
	label.text = value
	label.position = pos
	label.size = size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	add_child(label)
	return label
func button(value: String, pos: Vector2, size: Vector2, action: Callable, disabled := false) -> Button:
	var b := Button.new()
	b.text = value
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", 20)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("183344")
	normal.border_color = Color("537b8f")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(10)
	b.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color("244b5c")
	b.add_theme_stylebox_override("hover", hover)
	var locked := normal.duplicate()
	locked.bg_color = Color("101f2c")
	locked.border_color = Color("293c49")
	b.add_theme_stylebox_override("disabled", locked)
	b.add_theme_color_override("font_disabled_color", Color("637888"))
	b.disabled = disabled
	b.pressed.connect(action)
	add_child(b)
	return b
func message(value: String, success: bool = false) -> void:
	if is_instance_valid(notice):
		notice.text = value
		notice.add_theme_color_override("font_color", Color("94cfbd") if success else Color("ffb6a5"))
func stages() -> void:
	text("CHƯƠNG I · PHẾ TÍCH NGÂN NGUYỆT", Vector2(50, 94), Vector2(1180, 40), 30, Color("edce92"))
	text("Vượt ải để mở đường đi tiếp · Đã vượt %d / 10" % host.progress.data.cleared.size(), Vector2(50, 140), Vector2(1180, 35), 21)
	for i in range(10):
		var id := i + 1
		var stage := Campaign.stage(id)
		var cleared: bool = id in host.progress.data.cleared
		var unlocked: bool = id <= host.progress.unlocked()
		var kind := "%d đợt" % stage.waves.size()
		if id in [5, 10]: kind += " · BOSS"
		var state := "Đã vượt" if cleared else ("Sẵn sàng" if unlocked else "Chưa mở")
		var card := button("1-%02d\n%s\n%s\n%s" % [id, stage.title, kind, state], Vector2(50 + i % 5 * 238, 192 + i / 5 * 156), Vector2(224, 138), func(): host.prepare_stage(id), not unlocked or host.progress.read_only)
		card.add_theme_font_size_override("font_size", 19)
	var complete: bool = host.progress.data.cleared.size() == 10
	text("Đã hoàn thành chương! Có thể chơi lại các ải để nhận thưởng trận." if complete else "Ải 5 và 10 có Kỵ sĩ Nguyệt Thực. Thưởng lần đầu chỉ nhận một lần mỗi ải.", Vector2(50, 520), Vector2(1180, 50), 21, Color("94cfbd"))
	notice = text(host.progress.last_error, Vector2(290, 585), Vector2(610, 65), 18, Color("ffb6a5"))
	button("Về sảnh", Vector2(50, 590), Vector2(215, 58), host.to_title)
	button("Chơi lại 1-10" if complete else "Tiếp tục · 1-%02d" % host.progress.unlocked(), Vector2(930, 590), Vector2(300, 58), func(): host.prepare_stage(host.progress.unlocked()), host.progress.read_only)
func prepare(id: int) -> void:
	var stage := Campaign.stage(id)
	text("1-%02d · %s" % [id, stage.title], Vector2(50, 92), Vector2(1180, 42), 32, Color("edce92"))
	var enemy_count := 0
	for wave in stage.waves: enemy_count += 1 if wave.has("boss_hp") else wave.enemies.size()
	var summary := "%d đợt · %d địch" % [stage.waves.size(), enemy_count]
	if id in [5, 10]: summary += " · Boss %d HP" % (750 if id == 5 else 1500)
	var record: Dictionary = host.progress.data.records.get(str(id), {})
	if not record.is_empty(): summary += " · Kỷ lục %.1fs · Thắng %d lần" % [record.best_time, record.wins]
	text(summary, Vector2(50, 141), Vector2(1180, 32), 22)
	var first: bool = not id in host.progress.data.cleared
	var rewards := Campaign.reward(id, first)
	text("Thắng: +%d vàng · +%d XP%s" % [rewards.gold, rewards.xp, " (gồm thưởng vượt lần đầu)" if first else " (thưởng chơi lại)"], Vector2(50, 178), Vector2(1180, 32), 21, Color("94cfbd"))
	var roster: Array[int] = host.progress.formation()
	for i in range(5):
		var hero: Dictionary = host.progress.hero_stats(i)
		var selected: bool = i in roster
		var order := "Vị trí %d" % (roster.find(i) + 1) if selected else "Dự bị"
		var slot := i
		var x := 50 + i * 238
		var card := button("%s · %s\nCấp %d · %s\n%d HP · Đánh %d\n%s\n%s" % [hero.name, hero.role, hero.level, order, int(hero.hp), int(hero.damage), hero.skill, "Giữ vị trí đầu" if i == 0 else ("Chạm để bỏ" if selected else "Chạm để thêm")], Vector2(x, 235), Vector2(224, 192), func(): host.select_companion(slot), i == 0)
		var style: StyleBoxFlat = card.get_theme_stylebox("disabled" if i == 0 else "normal").duplicate()
		style.border_color = Color(hero.color) if selected else Color("3b5362")
		style.bg_color = Color("183344") if selected else Color("101f2c")
		card.add_theme_stylebox_override("disabled" if i == 0 else "normal", style)
		if i == 0: card.add_theme_color_override("font_disabled_color", Color(hero.color))
		if i > 0 and selected:
			button("Lên trước", Vector2(x, 437), Vector2(107, 48), func(): host.move_companion(slot, -1), roster.find(i) <= 1)
			button("Ra sau", Vector2(x + 117, 437), Vector2(107, 48), func(): host.move_companion(slot, 1), roster.find(i) == roster.size() - 1)
	var names: PackedStringArray = []
	for index in roster: names.append(Party.HEROES[index].name)
	text("Đội %d/5: %s" % [roster.size(), " → ".join(names)], Vector2(50, 506), Vector2(1180, 36), 23)
	var auto := CheckButton.new()
	auto.text = "Tự dùng kỹ năng"
	auto.position = Vector2(350, 595)
	auto.size = Vector2(280, 48)
	auto.button_pressed = host.auto_skills
	auto.add_theme_font_size_override("font_size", 22)
	auto.toggled.connect(func(value): host.set_auto_mode(value))
	add_child(auto)
	notice = text(host.progress.last_error, Vector2(50, 550), Vector2(820, 35), 18, Color("ffb6a5"))
	button("Nâng tướng", Vector2(655, 590), Vector2(250, 58), func(): host.open_growth("prepare"))
	button("Chọn ải khác", Vector2(50, 590), Vector2(260, 58), host.open_stages)
	button("Bắt đầu · 1-%02d" % id, Vector2(930, 580), Vector2(300, 68), func(): host.start_campaign(id), host.progress.read_only)
func result(receipt: Dictionary) -> void:
	var stage := Campaign.stage(host.selected_stage)
	var won: bool = host.battle.state == "won"
	text(("CHIẾN THẮNG" if won else "THẤT BẠI") + " · 1-%02d" % host.selected_stage, Vector2(70, 100), Vector2(1140, 48), 38, Color("edce92") if won else Color("e9a8a1"))
	text(stage.title, Vector2(70, 154), Vector2(1140, 36), 25)
	var living: int = host.battle.heroes.filter(func(a): return a.hp > 0).size()
	text("%.1f giây · Hạ %d địch · Còn sống %d/%d tướng" % [host.battle.elapsed, host.battle.kills, living, host.battle.heroes.size()], Vector2(70, 204), Vector2(1140, 36), 23)
	if not receipt.get("ok", false):
		text("Chưa lưu được kết quả; phần thưởng chưa được cộng.\n" + str(receipt.get("error", "Hãy thử lại.")), Vector2(70, 290), Vector2(1100, 100), 24, Color("ffb6a5"))
		button("Về sảnh · bỏ kết quả", Vector2(70, 540), Vector2(350, 68), host.to_title)
		button("Thử lưu lại", Vector2(850, 540), Vector2(360, 68), host.show_campaign_result)
		return
	if won:
		var first: bool = receipt.first
		text("THƯỞNG TRẬN\n+%d vàng\n+%d XP hành trình" % [stage.gold, stage.xp], Vector2(90, 285), Vector2(350, 140), 25)
		text("VƯỢT LẦN ĐẦU\n+%d vàng\n+%d XP hành trình" % [stage.first_gold if first else 0, stage.first_xp if first else 0], Vector2(470, 285), Vector2(350, 140), 25, Color("edce92") if first else Color("8296a6"))
		text("TỔNG NHẬN\n+%d vàng\n+%d XP hành trình" % [receipt.gold, receipt.xp], Vector2(860, 285), Vector2(350, 140), 25, Color("94cfbd"))
		var note := "Đã nhận thưởng vượt lần đầu." if first else "Thưởng vượt lần đầu đã nhận ở lần trước."
		if host.progress.data.cleared.size() == 10: note = "Đã hoàn thành Chương I! Có thể chơi lại các ải."
		text(note, Vector2(70, 457), Vector2(1140, 36), 23, Color("94cfbd"))
	else:
		text("Chưa vượt ải · Không mất vàng hoặc XP.\nThử đổi đội hình hoặc bật tự dùng kỹ năng.", Vector2(70, 292), Vector2(1140, 95), 25)
	text("Đã lưu tiến trình", Vector2(70, 514), Vector2(1140, 34), 20, Color("94cfbd"))
	button("Chọn ải", Vector2(70, 580), Vector2(250, 66), host.open_stages)
	button("Chơi lại", Vector2(345, 580), Vector2(250, 66), func(): host.start_campaign(host.selected_stage))
	if won and host.selected_stage < 10:
		button("Ải tiếp theo", Vector2(860, 580), Vector2(350, 66), func(): host.prepare_stage(host.selected_stage + 1))
	else:
		button("Chuẩn bị đội", Vector2(860, 580), Vector2(350, 66), func(): host.prepare_stage(host.selected_stage))

func growth(index: int, origin: String) -> void:
	text("TƯỚNG · NÂNG CẤP", Vector2(50, 92), Vector2(1180, 42), 32, Color("edce92"))
	for i in range(5):
		var hero: Dictionary = host.progress.hero_stats(i)
		var selected := i
		var selector := button("%s · Cấp %d" % [hero.name, hero.level], Vector2(50 + i * 238, 153), Vector2(224, 60), func(): host.open_growth(origin, selected))
		if i == index:
			var style: StyleBoxFlat = selector.get_theme_stylebox("normal").duplicate()
			style.border_color = Color(hero.color)
			selector.add_theme_stylebox_override("normal", style)
	var quote: Dictionary = host.progress.upgrade_quote(index)
	var before: Dictionary = quote.before
	var after: Dictionary = quote.after
	var portrait: Node2D = load("res://game/hero_art.gd").new() if index == 0 else load("res://game/companion_art.gd").new()
	if index > 0: portrait.configure(before.id)
	portrait.position = Vector2(290, 540)
	portrait.scale = Vector2(1.25, 1.25)
	portrait.preview = true
	add_child(portrait)
	text("%s · %s" % [before.name, before.role], Vector2(80, 600), Vector2(440, 34), 25, Color(before.color))
	text(before.name.to_upper() + " · " + before.role, Vector2(570, 245), Vector2(640, 42), 30, Color(before.color))
	text("Cấp %d / %d" % [quote.level, Party.MAX_LEVEL], Vector2(570, 290), Vector2(640, 35), 24)
	text("HP: %d" % int(before.hp) + ("  →  %d" % int(after.hp) if not quote.maxed else ""), Vector2(570, 335), Vector2(640, 38), 28)
	text("Đòn thường: %d" % int(before.damage) + ("  →  %d" % int(after.damage) if not quote.maxed else ""), Vector2(570, 382), Vector2(640, 38), 28)
	var effects := {"area": "Gây %d sát thương cho toàn bộ địch.", "single": "Gây %d sát thương cho một địch.", "shield": "Tạo lá chắn %d cho đồng đội sống.", "heal": "Hồi %d HP cho đồng đội sống."}
	var effect: String = effects[before.kind] % int(before.power)
	text("%s · Hồi %.0fs\n%s\nChỉ HP và đòn thường tăng khi nâng cấp." % [before.skill, before.cooldown, effect], Vector2(570, 422), Vector2(640, 75), 18)
	var detail := "Đã đạt cấp tối đa."
	if not quote.maxed:
		detail = "Chi phí: %d vàng + %d XP hành trình" % [quote.cost.gold, quote.cost.xp]
	text(detail, Vector2(570, 500), Vector2(640, 32), 23, Color("edce92"))
	var old_level: int = quote.level
	button("Đã đạt cấp %d" % Party.MAX_LEVEL if quote.maxed else "Nâng lên cấp %d" % quote.next_level, Vector2(570, 543), Vector2(640, 58), func(): host.upgrade_selected(index, old_level), quote.maxed or not quote.affordable or host.progress.read_only)
	var status := ""
	if host.progress.read_only: status = "Tiến trình đang khóa; chưa thể nâng cấp."
	elif not quote.maxed and not quote.affordable:
		var missing_gold := maxi(0, int(quote.cost.gold - host.progress.data.gold))
		var missing_xp := maxi(0, int(quote.cost.xp - host.progress.data.xp))
		var pieces: PackedStringArray = []
		if missing_gold > 0: pieces.append("%d vàng" % missing_gold)
		if missing_xp > 0: pieces.append("%d XP" % missing_xp)
		status = "Cần thêm " + " và ".join(pieces) + "."
	notice = text(status, Vector2(570, 612), Vector2(640, 32), 19, Color("ffb6a5"))
	button("Về chuẩn bị đội" if origin == "prepare" else "Về sảnh", Vector2(940, 650), Vector2(290, 50), host.close_growth)
