extends SceneTree
const Progress = preload("res://game/campaign_progress.gd")
const Equipment = preload("res://game/equipment_data.gd")
const Battle = preload("res://game/battle.gd")
class FailingProgress extends Progress:
	var fail := false
	func commit(candidate: Dictionary) -> bool:
		if fail: return false
		return super.commit(candidate)
func _initialize() -> void:
	var folder := "user://equipment-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for version in [1, 2]:
		var path := folder + "/v%d.json" % version
		var legacy := Progress.new().defaults()
		legacy.version = version
		legacy.erase("owned_equipment")
		legacy.erase("equipment")
		if version == 1: legacy.erase("hero_levels")
		else: legacy.hero_levels = [3, 2, 1, 1, 1]
		legacy.gold = 2000
		legacy.xp = 99
		var original := JSON.stringify(legacy)
		var file := FileAccess.open(path, FileAccess.WRITE)
		file.store_string(original)
		file.close()
		var p := FailingProgress.new(path)
		assert(p.load_game() and p.data.version == Progress.SCHEMA_VERSION)
		assert(FileAccess.get_file_as_string(path) == original)
		assert(p.buy_equipment("iron_blade"))
		assert(FileAccess.get_file_as_string(path + ".v%d.bak" % version) == original)
		assert(p.data.gold == 1920 and p.data.xp == 99)
		assert(not p.buy_equipment("iron_blade") and not p.buy_equipment("missing"))
		assert(not p.equip_item(0, "armor", "iron_blade"))
		assert(not p.equip_item(0, "weapon", "moon_blade"))
		var before := p.hero_stats(0)
		assert(p.equip_item(0, "weapon", "iron_blade"))
		assert(p.hero_stats(0).damage == before.damage + 4)
		assert(not p.equip_item(1, "weapon", "iron_blade"))
		assert(p.buy_equipment("linen_armor") and p.equip_item(0, "armor", "linen_armor"))
		assert(p.hero_stats(0).hp == before.hp + 35)
		assert(p.upgrade_quote(0).after.damage >= p.hero_stats(0).damage)
		var b := Battle.new()
		b.start(2, [0, 3], {}, p.levels(), p.data.equipment.duplicate(true))
		assert(b.heroes[0].max_hp == before.hp + 35 and b.heroes[0].damage == before.damage + 4)
		assert(p.equip_item(0, "weapon", "") and p.equip_item(3, "weapon", "iron_blade"))
		assert(b.heroes[0].damage == before.damage + 4)
		b.start(2, [0, 3], {}, p.levels(), p.data.equipment)
		assert(b.heroes[1].damage == p.hero_stats(3).damage)
		var saved := p.data.duplicate(true)
		p.fail = true
		assert(not p.buy_equipment("moon_blade") and not p.equip_item(0, "armor", ""))
		assert(p.data == saved)
		p.fail = false
		assert(p.equip_item(0, "armor", ""))
		var reloaded := Progress.new(path)
		assert(reloaded.load_game() and reloaded.data == p.data)
		var broken := p.data.duplicate(true)
		broken.equipment[0].weapon = "iron_blade"
		assert(not p.valid(broken))
		broken = p.data.duplicate(true)
		broken.equipment[0].erase("armor")
		assert(not p.valid(broken))
		p.data.gold = 0
		assert(not p.buy_equipment("dawn_blade"))
		p.read_only = true
		assert(not p.equip_item(3, "weapon", ""))
	print("PASS: equipment migration 1/2, backups, buy/equip/transfer, stats, snapshots, validation, storage failure and reload")
	quit()
