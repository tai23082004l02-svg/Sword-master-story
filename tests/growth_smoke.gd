extends SceneTree
const Progress = preload("res://game/campaign_progress.gd")
const Party = preload("res://game/party_data.gd")
const Model = preload("res://game/battle.gd")
class FailingProgress extends Progress:
	var fail := false
	func commit(candidate: Dictionary) -> bool:
		if fail:
			last_error = "Simulated storage failure"
			return false
		return super.commit(candidate)
func write(path: String, value: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	assert(f != null)
	f.store_string(value)
	f.close()
func _initialize() -> void:
	var folder := "user://growth-model-%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	var path := folder + "/profile.json"
	var p := Progress.new(path)
	var legacy := p.defaults()
	legacy.erase("hero_levels")
	legacy.version = 1
	legacy.gold = 2650
	legacy.xp = 1150
	legacy.cleared = [1, 2]
	legacy.records = {"1": {"wins": 3, "best_time": 4.75}, "2": {"wins": 1, "best_time": 7.125}}
	legacy.formation = [0, 4, 1]
	legacy.auto_skills = true
	legacy.serial = 7
	legacy.last_claimed = 6
	legacy.pending = {"id": 7, "stage": 3}
	var original := JSON.stringify(legacy, "  ")
	write(path, original)
	assert(p.load_game() and p.data.version == Progress.SCHEMA_VERSION and p.levels() == [1, 1, 1, 1, 1])
	assert(FileAccess.get_file_as_string(path) == original, "Load must not rewrite a legacy file")
	var quote := p.upgrade_quote(0)
	assert(quote.before.hp == 220 and quote.after.hp == 242 and quote.after.damage == 25)
	assert(quote.cost == {"gold": 30, "xp": 10} and quote.affordable)
	assert(p.upgrade_hero(0, 1).ok)
	assert(p.levels() == [2, 1, 1, 1, 1] and p.data.gold == 2620 and p.data.xp == 1140)
	assert(p.data.cleared == [1, 2] and p.data.records == legacy.records and p.formation() == [0, 4, 1])
	assert(p.data.pending == legacy.pending and p.data.serial == 7 and p.data.auto_skills)
	assert(FileAccess.get_file_as_string(path + ".v1.bak") == original)
	var before := p.data.duplicate(true)
	assert(not p.upgrade_hero(0, 1).ok and p.data == before, "Stale/double-click quote must not spend again")
	assert(not p.upgrade_hero(-1).ok and not p.upgrade_hero(5).ok and p.data == before)
	var loaded := Progress.new(path)
	assert(loaded.load_game() and loaded.data == p.data)
	# Both currencies are required; exact cost can reduce the wallet to zero.
	var wallet := loaded.defaults()
	wallet.gold = 29
	wallet.xp = 10
	assert(loaded.commit(wallet))
	before = loaded.data.duplicate(true)
	assert(not loaded.upgrade_hero(0).ok and loaded.data == before)
	wallet.gold = 30
	wallet.xp = 9
	assert(loaded.commit(wallet))
	before = loaded.data.duplicate(true)
	assert(not loaded.upgrade_hero(0).ok and loaded.data == before)
	wallet.xp = 10
	assert(loaded.commit(wallet) and loaded.upgrade_hero(0, 1).ok)
	assert(loaded.data.gold == 0 and loaded.data.xp == 0)
	# A failed write must not change the level, wallet or file; retry costs once.
	var failing := FailingProgress.new(folder + "/failure.json")
	wallet = failing.defaults()
	wallet.gold = 10000
	wallet.xp = 10000
	assert(failing.commit(wallet))
	before = failing.data.duplicate(true)
	var file_before := FileAccess.get_file_as_string(failing.path)
	failing.fail = true
	assert(not failing.upgrade_hero(3, 1).ok and failing.data == before)
	assert(FileAccess.get_file_as_string(failing.path) == file_before)
	failing.fail = false
	assert(failing.upgrade_hero(3, 1).ok and failing.levels() == [1, 1, 1, 2, 1])
	# Cap and independent hero growth, with known total cost 1 -> 20.
	var cap := Progress.new(folder + "/cap.json")
	wallet = cap.defaults()
	wallet.gold = 10000
	wallet.xp = 10000
	assert(cap.commit(wallet))
	for level in range(1, 20): assert(cap.upgrade_hero(0, level).ok)
	assert(cap.data.gold == 6010 and cap.data.xp == 8100)
	assert(cap.levels() == [20, 1, 1, 1, 1] and cap.hero_stats(0).hp == 638 and cap.hero_stats(0).damage == 64)
	before = cap.data.duplicate(true)
	assert(cap.upgrade_quote(0).maxed and not cap.upgrade_quote(0).affordable)
	assert(not cap.upgrade_hero(0, 20).ok and cap.data == before)
	# Current schema rejects bad levels; later schema remains write-locked.
	for bad in [[0, 1, 1, 1, 1], [21, 1, 1, 1, 1], [1, 1], [1.5, 1, 1, 1, 1], ["1", 1, 1, 1, 1]]:
		wallet = cap.defaults()
		wallet.hero_levels = bad
		assert(not cap.valid(wallet))
	# A legacy backup used for recovery must also get a permanent migration copy.
	var recovery := Progress.new(folder + "/recovery.json")
	write(recovery.path, "{broken")
	write(recovery.path + ".bak", original)
	assert(recovery.load_game() and recovery.recovered)
	assert(recovery.upgrade_hero(4, 1).ok)
	assert(recovery.set_auto(false) and FileAccess.get_file_as_string(recovery.path + ".v1.bak") == original)
	# Battle receives a per-ID snapshot, including a reordered party.
	var b := Model.new()
	var levels := [2, 7, 4, 10, 3]
	b.start(5, [0, 4, 2, 1, 3], {}, levels)
	assert(b.heroes[0].max_hp == 242 and b.heroes[0].damage == 25 and b.heroes[0].power == 48)
	assert(b.heroes[1].id == "sol" and b.heroes[1].level == 3 and b.heroes[1].max_hp == 186)
	assert(b.heroes[2].id == "lyra" and b.heroes[2].level == 4 and b.heroes[2].damage == 23)
	levels[0] = 10
	assert(b.heroes[0].level == 2, "An active battle must not change when saved levels change")
	b.enemies[0].hp = 1000
	b.enemies[0].x = b.hero_x + 5
	b.heroes[0].windup = 0.01
	b.heroes[0].target = b.enemies[0].id
	b.tick(0.02)
	assert(b.enemies[0].hp == 975, "Upgraded normal attack must use upgraded damage")
	b.start(5, [0, 4, 2, 1, 3], {}, levels)
	assert(b.heroes[0].level == 10 and b.heroes[0].max_hp == 418)
	print("PASS: v1 migration and backup, exact costs, independent levels/cap, stale quote, insufficient currencies, failed save/retry, recovery migration and battle snapshots")
	quit()
