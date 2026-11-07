extends RefCounted
## Transactional local progression. Audio settings remain in their original file.
const Campaign = preload("res://game/campaign_data.gd")
const Party = preload("res://game/party_data.gd")
const Equipment = preload("res://game/equipment_data.gd")
const RPG = preload("res://game/rpg_data.gd")
const SCHEMA_VERSION := 4
var path: String
var data: Dictionary
var last_error := ""
var recovered := false
var read_only := false
func _init(save_path: String = "user://campaign.json") -> void:
	path = save_path
	data = defaults()
func defaults() -> Dictionary:
	return {"version": SCHEMA_VERSION, "rpg": RPG.defaults(), "owned_equipment": [], "equipment": Equipment.empty_slots(), "hero_levels": [1, 1, 1, 1, 1], "gold": 0, "xp": 0, "cleared": [], "records": {}, "formation": [0, 1, 2, 3, 4], "auto_skills": false, "serial": 0, "last_claimed": 0, "pending": {}}
func whole(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value == floorf(value) and value >= low and value <= high
func valid(candidate: Variant) -> bool:
	if not candidate is Dictionary: return false
	var required: Array = defaults().keys()
	required.erase("hero_levels")
	required.erase("owned_equipment")
	required.erase("equipment")
	required.erase("rpg")
	if not candidate.has_all(required) or not whole(candidate.version, 1, SCHEMA_VERSION): return false
	if candidate.version >= 2:
		if not candidate.get("hero_levels") is Array or candidate.hero_levels.size() != 5: return false
		for level in candidate.hero_levels:
			if not whole(level, 1, Party.MAX_LEVEL): return false
	if candidate.version >= 3:
		if not candidate.get("owned_equipment") is Array or not candidate.get("equipment") is Array or candidate.equipment.size() != 5: return false
		var owned: Array = []
		for id in candidate.owned_equipment:
			if not id is String or not Equipment.ITEMS.has(id) or id in owned: return false
			owned.append(id)
		var used_items: Array = []
		for slots in candidate.equipment:
			if not slots is Dictionary or slots.size() != 2 or not slots.has_all(["weapon", "armor"]): return false
			for slot in ["weapon", "armor"]:
				var id: Variant = slots[slot]
				if not id is String: return false
				if id == "": continue
				if not id in owned or id in used_items or Equipment.ITEMS[id].slot != slot: return false
				used_items.append(id)
	if candidate.version >= 4 and not RPG.valid(candidate.get("rpg")): return false
	for key in ["gold", "xp", "serial", "last_claimed"]:
		if not whole(candidate[key], 0, 9007199254740991): return false
	if candidate.last_claimed > candidate.serial or not candidate.auto_skills is bool: return false
	if not candidate.cleared is Array or candidate.cleared.size() > Campaign.MAX_STAGE or not candidate.records is Dictionary: return false
	for i in range(candidate.cleared.size()):
		if not whole(candidate.cleared[i], i + 1, i + 1): return false
		var key := str(i + 1)
		if not candidate.records.has(key) or not candidate.records[key] is Dictionary: return false
		var record: Dictionary = candidate.records[key]
		if not record.has_all(["wins", "best_time"]): return false
		if not whole(record.wins, 1, 9007199254740991): return false
		if not (record.best_time is float or record.best_time is int) or not is_finite(float(record.best_time)) or record.best_time < 0: return false
	if candidate.records.size() != candidate.cleared.size(): return false
	if not candidate.formation is Array or candidate.formation.is_empty() or candidate.formation.size() > 5 or candidate.formation[0] != 0: return false
	var seen: Array[int] = []
	for value in candidate.formation:
		if not whole(value, 0, RPG.HERO_COUNT-1) or int(value) in seen: return false
		if value >= 5 and (candidate.version < 4 or not candidate.rpg.recruited[int(value)]): return false
		seen.append(int(value))
	if not candidate.pending is Dictionary: return false
	if not candidate.pending.is_empty():
		if not candidate.pending.has_all(["id", "stage"]): return false
		if not whole(candidate.pending.id, 1, int(candidate.serial)) or candidate.pending.id != candidate.serial or candidate.pending.id <= candidate.last_claimed: return false
		if not whole(candidate.pending.stage, 1, mini(Campaign.MAX_STAGE, candidate.cleared.size() + 1)): return false
		if candidate.pending.get("mode", "campaign") not in ["campaign","gold","material","tower","challenge"]: return false
		if candidate.pending.get("mode", "campaign") != "campaign" and not whole(candidate.pending.get("floor", 1),1,30): return false
		if candidate.pending.has("rotation_week") and not whole(candidate.pending.rotation_week,0,9007199254740991): return false
	return true
func normalize(candidate: Dictionary) -> Dictionary:
	var result := candidate.duplicate(true)
	if int(result.version) == 1:
		result.hero_levels = [1, 1, 1, 1, 1]
	if int(result.version) < 3:
		result.owned_equipment = []
		result.equipment = Equipment.empty_slots()
	if int(result.version) < 4: result.rpg = RPG.defaults()
	result.rpg = RPG.normalize(result.rpg)
	result.version = SCHEMA_VERSION
	var levels: Array = []
	for level in result.hero_levels: levels.append(int(level))
	result.hero_levels = levels
	for key in ["version", "gold", "xp", "serial", "last_claimed"]:
		result[key] = int(result[key])
	var roster: Array = []
	for value in result.formation: roster.append(int(value))
	result.formation = roster
	var cleared: Array = []
	for value in result.cleared: cleared.append(int(value))
	result.cleared = cleared
	for key in result.records:
		result.records[key].wins = int(result.records[key].wins)
		result.records[key].best_time = float(result.records[key].best_time)
	if not result.pending.is_empty():
		result.pending.id = int(result.pending.id)
		result.pending.stage = int(result.pending.stage)
		if result.pending.has("floor"): result.pending.floor = int(result.pending.floor)
		if result.pending.has("rotation_week"): result.pending.rotation_week = int(result.pending.rotation_week)
	return result
func parse_file(file_path: String) -> Variant:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null: return null
	var content := file.get_as_text()
	file.close()
	var parser := JSON.new()
	return parser.data if parser.parse(content) == OK else null
func read_file(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path): return {}
	var parsed: Variant = parse_file(file_path)
	return normalize(parsed) if valid(parsed) else {}
func load_game() -> bool:
	last_error = ""
	recovered = false
	read_only = false
	var primary := read_file(path)
	if not primary.is_empty():
		data = primary
		return true
	# A newer schema is kept intact, even if an older backup can be read.
	if FileAccess.file_exists(path):
		var raw: Variant = parse_file(path)
		if raw is Dictionary and not whole(raw.get("version", 1), 1, SCHEMA_VERSION):
			read_only = true
			last_error = "Tiến trình thuộc phiên bản khác. Cần cập nhật game để mở."
			return false
	var backup := read_file(path + ".bak")
	if not backup.is_empty():
		data = backup
		recovered = true
		return true
	if FileAccess.file_exists(path) or FileAccess.file_exists(path + ".bak"):
		read_only = true
		last_error = "Không đọc được tiến trình. Dữ liệu cũ được giữ nguyên."
		return false
	data = defaults()
	return true
func commit(candidate: Dictionary) -> bool:
	if read_only or not valid(candidate):
		if last_error.is_empty(): last_error = "Không thể lưu tiến trình lúc này."
		return false
	candidate = normalize(candidate)
	RPG.visit(candidate.rpg)
	var absolute := ProjectSettings.globalize_path(path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir()) != OK:
		last_error = "Không tạo được nơi lưu. Chưa thay đổi tiến trình."
		return false
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "Không ghi được tiến trình. Hãy thử lưu lại."
		return false
	var serialized := JSON.stringify(candidate, "  ")
	file.store_string(serialized)
	file.flush()
	var written := file.get_error() == OK
	file.close()
	var verified := read_file(temporary)
	if not written or verified.is_empty() or FileAccess.get_file_as_string(temporary) != serialized:
		last_error = "Chưa ghi đủ tiến trình. Hãy thử lưu lại."
		return false
	if FileAccess.file_exists(path) and read_file(path).is_empty():
		var preserved := absolute + ".damaged-%d-%d" % [int(Time.get_unix_time_from_system()), Time.get_ticks_usec()]
		if DirAccess.copy_absolute(absolute, preserved) != OK:
			last_error = "Không giữ được bản dữ liệu cũ. Hãy thử lại."
			return false
	# Keep each supported pre-migration schema once, including recovered backups.
	for source in [path, path + ".bak"]:
		if read_file(source).is_empty(): continue
		var old: Variant = parse_file(source)
		var version := int(old.get("version", SCHEMA_VERSION))
		var preserved := absolute + ".v%d.bak" % version
		if version < SCHEMA_VERSION and not FileAccess.file_exists(preserved):
			if DirAccess.copy_absolute(ProjectSettings.globalize_path(source), preserved) != OK:
				last_error = "Chưa giữ được bản tiến trình cũ. Hãy thử lại."
				return false
	if not read_file(path).is_empty():
		if DirAccess.copy_absolute(absolute, absolute + ".bak") != OK:
			last_error = "Không tạo được bản dự phòng. Hãy thử lưu lại."
			return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), absolute) != OK:
		last_error = "Không hoàn tất được việc lưu. Hãy thử lại."
		return false
	data = verified
	last_error = ""
	return true
func unlocked() -> int:
	return mini(Campaign.MAX_STAGE, data.cleared.size() + 1)
func formation() -> Array[int]:
	var result: Array[int] = []
	for value in data.formation: result.append(int(value))
	return result
func set_formation(roster: Array) -> bool:
	var candidate := data.duplicate(true)
	candidate.formation = roster.duplicate()
	return commit(candidate)
func set_auto(value: bool) -> bool:
	var candidate := data.duplicate(true)
	candidate.auto_skills = value
	return commit(candidate)
func begin_run(stage_id: int) -> int:
	if stage_id < 1 or stage_id > unlocked(): return -1
	var candidate := data.duplicate(true)
	candidate.serial += 1
	var key:=str(stage_id)
	candidate.rpg.stage_attempts[key]=int(candidate.rpg.stage_attempts.get(key,0))+1
	candidate.pending = {"id": candidate.serial, "stage": stage_id}
	return int(candidate.serial) if commit(candidate) else -1
func finish_run(run_id: int, won: bool, elapsed: float, survivors: int) -> Dictionary:
	if data.pending.is_empty() or data.pending.id != run_id or run_id <= data.last_claimed or not is_finite(elapsed) or elapsed < 0:
		return {"ok": false, "error": "Trận này đã kết thúc hoặc không còn hợp lệ."}
	var candidate := data.duplicate(true)
	var id := int(candidate.pending.stage)
	var mode: String = candidate.pending.get("mode", "campaign")
	if mode != "campaign": return finish_activity(candidate, won, elapsed, survivors)
	var first: bool = won and not id in candidate.cleared
	var reward := Campaign.reward(id, first) if won else {"gold": 0, "xp": 0}
	if won:
		candidate.gold += reward.gold
		candidate.xp += reward.xp
		if first: candidate.cleared.append(id)
		var key := str(id)
		var previous: Dictionary = candidate.records.get(key, {"wins": 0, "best_time": elapsed})
		candidate.records[key] = {"wins": previous.wins + 1, "best_time": minf(previous.best_time, elapsed)}
	var loot: Dictionary = {}
	var dust := 0
	RPG.visit(candidate.rpg)
	candidate.rpg.stats.runs += 1
	if not won:
		var key:=str(id)
		candidate.rpg.stage_losses[key]=int(candidate.rpg.stage_losses.get(key,0))+1
	if won:
		candidate.rpg.stats.wins += 1
		candidate.rpg.sweep_tokens += 1
		candidate.rpg.weekly_wins += 1
		if first:
			candidate.rpg.gems += 100
			candidate.rpg.tickets += 1
		dust = 2
		candidate.rpg.dust += dust
		candidate.rpg.shards[(id-1) % RPG.HERO_COUNT] += 2
		loot = RPG.grant_item(candidate.rpg, RPG.drop_base(id,int(candidate.records[str(id)].wins)))
		if loot.uid == 0: dust += 5
	candidate.last_claimed = run_id
	candidate.pending = {}
	if not commit(candidate): return {"ok": false, "error": last_error}
	return {"ok": true, "won": won, "stage": id, "first": first, "gold": reward.gold, "xp": reward.xp, "elapsed": elapsed, "survivors": survivors, "loot":loot, "mode":"campaign", "gems":100 if first else 0, "tickets":1 if first else 0, "dust":dust, "sweep_tokens":1 if won else 0, "shard_hero":(id-1)%RPG.HERO_COUNT, "shards":2 if won else 0}
func abandon_run(run_id: int) -> bool:
	if data.pending.is_empty() or data.pending.id != run_id: return true
	var candidate := data.duplicate(true)
	candidate.pending = {}
	return commit(candidate)

func levels(include_recruits: bool = false) -> Array[int]:
	var result: Array[int] = []
	for level in data.hero_levels: result.append(int(level))
	if include_recruits:
		for level in data.rpg.extra_levels: result.append(int(level))
	return result

func hero_stats(index: int) -> Dictionary:
	return upgraded_stats(index, hero_level(index))

func upgrade_quote(index: int) -> Dictionary:
	if index < 0 or index >= RPG.HERO_COUNT: return {}
	var current := hero_level(index)
	var cost := Party.upgrade_cost(current)
	var maxed := current >= Party.MAX_LEVEL
	return {"level": current, "next_level": mini(Party.MAX_LEVEL, current + 1), "before": hero_stats(index), "after": upgraded_stats(index, mini(Party.MAX_LEVEL, current + 1)), "cost": cost, "maxed": maxed, "affordable": not maxed and data.gold >= cost.gold and data.xp >= cost.xp}

func upgrade_hero(index: int, expected_level: int = -1) -> Dictionary:
	if read_only: return {"ok": false, "error": last_error}
	if index < 0 or index >= RPG.HERO_COUNT or not data.rpg.recruited[index]: return {"ok": false, "error": "Tướng chưa được mở."}
	var quote := upgrade_quote(index)
	if expected_level >= 0 and quote.level != expected_level:
		return {"ok": false, "error": "Cấp tướng đã thay đổi. Hãy xem lại chi phí mới."}
	if quote.maxed: return {"ok": false, "error": "Tướng đã đạt cấp tối đa."}
	if not quote.affordable: return {"ok": false, "error": "Chưa đủ vàng hoặc XP để nâng cấp."}
	var candidate := data.duplicate(true)
	candidate.gold -= quote.cost.gold
	candidate.xp -= quote.cost.xp
	if index < 5: candidate.hero_levels[index] += 1
	else: candidate.rpg.extra_levels[index-5] += 1
	candidate.rpg.stats.upgrades += 1
	if not commit(candidate): return {"ok": false, "error": last_error}
	return {"ok": true, "level": hero_level(index), "gold": quote.cost.gold, "xp": quote.cost.xp}

func item_owner(id: String) -> int:
	for i in range(5):
		if id in data.equipment[i].values(): return i
	return -1

func buy_equipment(id: String) -> bool:
	if not Equipment.ITEMS.has(id) or id in data.owned_equipment:
		last_error = "Trang bị không hợp lệ hoặc đã sở hữu."
		return false
	var price: int = Equipment.ITEMS[id].gold
	if data.gold < price:
		last_error = "Chưa đủ vàng để mua trang bị."
		return false
	var candidate := data.duplicate(true)
	candidate.gold -= price
	candidate.owned_equipment.append(id)
	return commit(candidate)

func equip_item(index: int, slot: String, id: String) -> bool:
	if index < 0 or index >= 5 or slot not in ["weapon", "armor"]:
		last_error = "Ô trang bị không hợp lệ."
		return false
	if id != "":
		if not Equipment.ITEMS.has(id) or not id in data.owned_equipment or Equipment.ITEMS[id].slot != slot:
			last_error = "Chưa sở hữu trang bị phù hợp."
			return false
		var owner := item_owner(id)
		if owner >= 0 and owner != index:
			last_error = "Hãy tháo trang bị ở tướng đang dùng trước."
			return false
	var candidate := data.duplicate(true)
	candidate.equipment[index][slot] = id
	if id != "": candidate.rpg.slots[index][slot] = 0
	return commit(candidate)

func hero_level(index: int) -> int:
	return int(data.hero_levels[index]) if index < 5 else int(data.rpg.extra_levels[index-5])

func upgraded_stats(index: int, level: int) -> Dictionary:
	var actor := Party.stats(index, level)
	if index < 5: Equipment.apply(actor, data.equipment[index])
	var sets: Array = []
	for slot in ["weapon","armor"]:
		var item := RPG.find_item(data.rpg, int(data.rpg.slots[index][slot]))
		if item.is_empty(): continue
		var base: Dictionary = RPG.ITEMS[item.base]
		actor.hp += base.hp * (1.0 + int(item.rank) * 0.15)
		actor.damage += base.damage * (1.0 + int(item.rank) * 0.15)
		sets.append(base.set)
	actor.hp = ceilf(actor.hp * (1.0 + int(data.rpg.ascension[index]) * 0.05))
	actor.damage = ceilf(actor.damage * (1.0 + int(data.rpg.ascension[index]) * 0.05))
	actor.power *= 1.0 + (int(data.rpg.skill_levels[index])-1)*0.15
	actor.set_bonus = sets[0] if sets.size() == 2 and sets[0] == sets[1] else ""
	if actor.set_bonus == "ember": actor.damage = ceilf(actor.damage*1.1)
	if actor.set_bonus == "bastion": actor.hp = ceilf(actor.hp*1.15)
	if actor.set_bonus == "dawn": actor.cooldown *= 0.9
	return actor

func item_user(uid: int) -> int:
	for i in range(RPG.HERO_COUNT):
		if uid in data.rpg.slots[i].values(): return i
	return -1

func equip_loot(index: int, uid: int) -> bool:
	var item := RPG.find_item(data.rpg,uid)
	if index < 0 or index >= RPG.HERO_COUNT or not data.rpg.recruited[index] or item.is_empty(): return fail_action("Tướng hoặc trang bị không hợp lệ.")
	var owner := item_user(uid)
	if owner >= 0 and owner != index: return fail_action("Tháo món ở tướng đang dùng trước.")
	var c := data.duplicate(true)
	c.rpg.slots[index][RPG.ITEMS[item.base].slot] = uid
	if index < 5: c.equipment[index][RPG.ITEMS[item.base].slot] = ""
	return commit(c)

func unequip_loot(index: int, slot: String) -> bool:
	if index < 0 or index >= RPG.HERO_COUNT or slot not in ["weapon","armor"]: return fail_action("Ô không hợp lệ.")
	var c := data.duplicate(true)
	c.rpg.slots[index][slot] = 0
	return commit(c)

func enhance_loot(uid: int, expected_rank: int) -> bool:
	var item := RPG.find_item(data.rpg,uid)
	if item.is_empty() or int(item.rank) != expected_rank or expected_rank >= 10: return fail_action("Món đã thay đổi hoặc đạt+10.")
	var gold := 40*(expected_rank+1)
	var dust := 3*(expected_rank+1)
	if data.gold < gold or data.rpg.dust < dust: return fail_action("Cần %d vàng và %d bụi." % [gold,dust])
	var c := data.duplicate(true)
	RPG.find_item(c.rpg,uid).rank += 1
	c.gold -= gold
	c.rpg.dust -= dust
	c.rpg.stats.enhance += 1
	return commit(c)

func dismantle_loot(uid: int) -> bool:
	var item := RPG.find_item(data.rpg,uid)
	if item.is_empty() or item_user(uid) >= 0: return fail_action("Tháo món trước khi phân giải.")
	var c := data.duplicate(true)
	var index: int = c.rpg.inventory.find(RPG.find_item(c.rpg,uid))
	c.rpg.inventory.remove_at(index)
	c.rpg.dust += 5 + int(item.rank)*3
	return commit(c)

func fail_action(message: String) -> bool:
	last_error = message
	return false

func set_wishlist(index: int) -> bool:
	if index < 0 or index >= RPG.HERO_COUNT: return false
	var c := data.duplicate(true)
	c.rpg.wishlist = index
	return commit(c)

func summon(count: int) -> Dictionary:
	if count not in [1,10]: return {"ok":false,"error":"Số lượt không hợp lệ."}
	var c := data.duplicate(true)
	var tickets := mini(int(c.rpg.tickets),count)
	var cost := (count-tickets)*100
	if c.rpg.gems < cost or read_only: return {"ok":false,"error":"Chưa đủ vé/tinh thạch hoặc tiến trình đang khóa."}
	c.rpg.tickets -= tickets
	c.rpg.gems -= cost
	var results: Array = []
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(count):
		c.rpg.pity += 1
		var full: bool = c.rpg.pity >= 20 or rng.randf() < 0.05
		var hero: int = int(c.rpg.wishlist) if c.rpg.pity >= 20 else rng.randi_range(0,RPG.HERO_COUNT-1)
		var amount := 30 if full else 5
		c.rpg.shards[hero] += amount
		if full: c.rpg.pity = 0
		var unlocked_now: bool = not c.rpg.recruited[hero] and c.rpg.shards[hero] >= 30
		if unlocked_now:
			c.rpg.recruited[hero] = true
			c.rpg.shards[hero] -= 30
		results.append({"hero":hero,"shards":amount,"new":unlocked_now,"full":full})
	c.rpg.stats.summons += count
	if not commit(c): return {"ok":false,"error":last_error}
	return {"ok":true,"results":results}

func train_skill(index: int, expected: int) -> bool:
	if index < 0 or index >= RPG.HERO_COUNT or not data.rpg.recruited[index] or int(data.rpg.skill_levels[index]) != expected or expected >= 5: return fail_action("Kỹ năng đã thay đổi, chưa mở hoặc đạt tối đa.")
	if data.gold < expected*100 or data.rpg.dust < expected*10: return fail_action("Cần %d vàng và %d bụi." % [expected*100,expected*10])
	var c := data.duplicate(true)
	c.rpg.skill_levels[index] += 1
	c.gold -= expected*100
	c.rpg.dust -= expected*10
	return commit(c)

func ascend(index: int) -> bool:
	if index < 0 or index >= RPG.HERO_COUNT or not data.rpg.recruited[index] or data.rpg.ascension[index] >= 5: return fail_action("Chưa mở tướng hoặc đã đạt 5 bậc.")
	var cost := (int(data.rpg.ascension[index])+1)*30
	if data.rpg.shards[index] < cost: return fail_action("Cần %d mảnh tướng." % cost)
	var c := data.duplicate(true)
	c.rpg.shards[index] -= cost
	c.rpg.ascension[index] += 1
	return commit(c)

func goal_value(goal: Dictionary) -> int:
	return data.cleared.size() if goal.kind == "clear" else int(data.rpg.stats.get(goal.kind,0))

func claim_goal(id: String) -> bool:
	for goal in RPG.GOALS:
		if goal.id != id: continue
		if id in data.rpg.goals or goal_value(goal) < goal.target: return fail_action("Chưa hoàn thành hoặc đã nhận.")
		var c := data.duplicate(true)
		c.rpg.goals.append(id)
		c.gold += goal.gold
		c.rpg.gems += goal.gems
		return commit(c)
	return false

func claim_weekly() -> bool:
	var c := data.duplicate(true)
	RPG.visit(c.rpg)
	if c.rpg.weekly_claimed or c.rpg.weekly_wins < 10: return fail_action("Tuần này cần thắng 10 trận; thưởng chỉ nhận một lần.")
	c.rpg.weekly_claimed = true
	c.rpg.gems += 300
	c.rpg.tickets += 3
	return commit(c)

func begin_activity(mode: String) -> int:
	if mode not in ["gold","material","tower","challenge"] or data.cleared.size() < 5: return -1
	if mode == "tower" and data.rpg.tower >= 30: return -1
	var c := data.duplicate(true)
	c.serial += 1
	c.pending = {"id":c.serial,"stage":1,"mode":mode,"floor":int(c.rpg.tower)+1 if mode == "tower" else 1}
	if mode == "challenge": c.pending.rotation_week = RPG.week_now()
	return int(c.serial) if commit(c) else -1

func activity_stage(mode: String, floor_value: int = 1) -> Dictionary:
	var stage_id := clampi(floor_value if mode == "tower" else unlocked(),1,30)
	var stage := Campaign.stage(stage_id).duplicate(true)
	stage.title = {"gold":"Hầm vàng","material":"Hầm nguyên liệu","tower":"Tháp · Tầng %d" % floor_value,"challenge":"Thử thách tuần"}.get(mode,"")
	if mode == "gold": stage.waves = [{"enemies":["armored","melee","ranged"],"hp":100.0+stage_id*6}]
	if mode == "material": stage.waves = [{"enemies":["healer","ranged","armored"],"hp":120.0+stage_id*6}]
	if mode == "challenge":
		var kinds := [["healer","armored","ranged"],["assassin","assassin","melee"],["armored","healer","healer"]]
		var rotation: int = int(data.pending.get("rotation_week",RPG.week_now())) if data.pending.get("mode","")=="challenge" else RPG.week_now()
		stage.waves = [{"enemies":kinds[rotation%3],"hp":200.0+stage_id*6}]
	stage.tactics = true
	return stage

func finish_activity(c: Dictionary, won: bool, elapsed: float, survivors: int) -> Dictionary:
	var mode: String = c.pending.mode
	var floor_value := int(c.pending.floor)
	var rotation := int(c.pending.get("rotation_week",RPG.week_now()))
	var shard_hero := rotation%RPG.HERO_COUNT
	var dust := 0
	var gems := 0
	var shards := 0
	var gold := 0
	var xp := 0
	var loot: Dictionary = {}
	RPG.visit(c.rpg)
	c.rpg.stats.runs += 1
	if won:
		c.rpg.stats.wins += 1
		c.rpg.sweep_tokens += 1
		c.rpg.weekly_wins += 1
		c.rpg.mode_records[mode] = int(c.rpg.mode_records.get(mode,0))+1
		gold = 120 if mode == "gold" else 35
		xp = 40
		dust = 15 if mode == "material" else 3
		c.rpg.dust += dust
		if mode == "tower":
			c.rpg.tower = floor_value
			gems = 50
			c.rpg.gems += gems
		if mode == "challenge":
			shards = 5
			c.rpg.shards[shard_hero] += shards
		loot = RPG.grant_item(c.rpg,RPG.drop_base(maxi(1,c.cleared.size()),int(c.rpg.mode_records[mode])))
		if loot.uid == 0: dust += 5
		c.gold += gold
		c.xp += xp
	c.last_claimed = c.pending.id
	c.pending = {}
	if not commit(c): return {"ok":false,"error":last_error}
	return {"ok":true,"mode":mode,"won":won,"gold":gold,"xp":xp,"loot":loot,"elapsed":elapsed,"survivors":survivors,"floor":floor_value,"dust":dust,"gems":gems,"shards":shards,"shard_hero":shard_hero,"sweep_tokens":1 if won else 0}

func sweep(id: int, count: int) -> Dictionary:
	if not id in data.cleared or count < 1 or count > 10: return {"ok":false,"error":"Chỉ quét ải đã vượt,1–10 lượt."}
	var record: Dictionary = data.records[str(id)]
	if record.wins < 3: return {"ok":false,"error":"Thắng ải 3 lần để mở quét."}
	var c := data.duplicate(true)
	# Sweep tickets are earned on manual wins; manual replays remain unlimited.
	if c.rpg.sweep_tokens < count: return {"ok":false,"error":"Cần %d vé quét. Mỗi trận thắng đánh tay nhận 1 vé quét." % count}
	c.rpg.sweep_tokens -= count
	var reward := Campaign.reward(id,false)
	var previous_size: int = c.rpg.inventory.size()
	for i in range(count):
		c.records[str(id)].wins += 1
		RPG.grant_item(c.rpg,RPG.drop_base(id,int(c.records[str(id)].wins)))
	c.gold += reward.gold*count
	c.xp += reward.xp*count
	c.rpg.dust += count*2
	c.rpg.stats.sweeps += count
	if not commit(c): return {"ok":false,"error":last_error}
	return {"ok":true,"gold":reward.gold*count,"xp":reward.xp*count,"count":count,"items":c.rpg.inventory.size()-previous_size,"dust":count*2+(count-c.rpg.inventory.size()+previous_size)*5}

func recruit(index: int) -> bool:
	if index<5 or index>=RPG.HERO_COUNT or data.rpg.recruited[index] or data.rpg.shards[index]<30: return fail_action("Cần 30 mảnh để mở tướng chưa có.")
	var c:=data.duplicate(true)
	c.rpg.shards[index]-=30
	c.rpg.recruited[index]=true
	return commit(c)
