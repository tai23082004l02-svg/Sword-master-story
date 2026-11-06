extends SceneTree
const Progress = preload("res://game/campaign_progress.gd")
const Campaign = preload("res://game/campaign_data.gd")
class FailingProgress extends Progress:
	var fail := false
	func commit(candidate: Dictionary) -> bool:
		if fail:
			last_error = "Simulated storage failure"
			return false
		return super.commit(candidate)
func write(path: String, value: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(value)
	f.close()
func _initialize() -> void:
	var directory := "user://campaign-save-test-%d" % Time.get_ticks_usec()
	assert(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) == OK)
	var path := directory + "/progress.json"
	var p := Progress.new(path)
	assert(p.load_game() and not FileAccess.file_exists(path))
	assert(p.unlocked() == 1 and p.begin_run(2) == -1)
	assert(p.set_formation([0, 4, 2, 1, 3]))
	var before := p.data.duplicate(true)
	assert(not p.set_formation([0, 1, 1]) and p.data == before)
	assert(not p.set_formation([]) and not p.set_formation([1, 0]))
	assert(p.set_auto(true))
	var id := p.begin_run(1)
	assert(id > 0 and p.data.gold == 0)
	var interrupted := Progress.new(path)
	assert(interrupted.load_game() and interrupted.unlocked() == 1 and interrupted.data.gold == 0)
	assert(interrupted.formation() == [0, 4, 2, 1, 3] and interrupted.data.auto_skills)
	assert(p.abandon_run(id) and p.data.gold == 0)
	id = p.begin_run(1)
	var lost := p.finish_run(id, false, 10, 0)
	assert(lost.ok and lost.gold == 0 and p.unlocked() == 1)
	id = p.begin_run(1)
	var won := p.finish_run(id, true, 20, 5)
	assert(won.ok and won.first and won.gold == Campaign.reward(1, true).gold and p.unlocked() == 2)
	before = p.data.duplicate(true)
	assert(not p.finish_run(id, true, 20, 5).ok and p.data == before)
	assert(p.begin_run(3) == -1)
	id = p.begin_run(1)
	var repeat := p.finish_run(id, true, 30, 4)
	assert(repeat.ok and not repeat.first and repeat.gold == Campaign.reward(1, false).gold)
	assert(p.data.records["1"].wins == 2 and p.data.records["1"].best_time == 20)
	var reloaded := Progress.new(path)
	assert(reloaded.load_game() and reloaded.data == p.data and not FileAccess.file_exists(path + ".tmp"))
	id = reloaded.begin_run(1)
	var after_restart := reloaded.finish_run(id, true, 25, 5)
	assert(after_restart.ok and not after_restart.first and after_restart.gold == Campaign.reward(1, false).gold)
	assert(reloaded.data.cleared == [1])
	# A failed result commit keeps the wallet, unlocks and pending token intact.
	var failing := FailingProgress.new(path)
	assert(failing.load_game())
	id = failing.begin_run(2)
	before = failing.data.duplicate(true)
	failing.fail = true
	assert(not failing.finish_run(id, true, 12, 5).ok and failing.data == before)
	failing.fail = false
	assert(failing.finish_run(id, true, 12, 5).ok and failing.unlocked() == 3)
	assert(not failing.finish_run(id, true, 12, 5).ok)
	for stage in range(3, 11):
		id = failing.begin_run(stage)
		assert(failing.finish_run(id, true, 20 + stage, 3).ok)
	assert(failing.data.cleared.size() == 10 and failing.unlocked() == 10)
	assert(failing.data.gold == 2710 and failing.data.xp == 1174, "Full chapter plus two repeat stage1 rewards")
	# Corrupt primary: recover the last validated backup and preserve damaged bytes.
	assert(failing.set_auto(false))
	var backup := failing.read_file(path + ".bak")
	write(path, "{broken")
	var recover := Progress.new(path)
	assert(recover.load_game() and recover.recovered and recover.data == backup)
	assert(recover.set_auto(false))
	assert(recover.read_file(path + ".bak") == backup)
	var preserved := false
	for name in DirAccess.get_files_at(directory):
		if name.begins_with("progress.json.damaged-"): preserved = true
	assert(preserved)
	write(path, "{still-broken")
	write(path + ".bak", "{bad-backup")
	var broken := Progress.new(path)
	assert(not broken.load_game() and broken.read_only)
	assert(not broken.set_auto(true) and FileAccess.get_file_as_string(path) == "{still-broken")
	write(path, JSON.stringify({"version": 2}))
	write(path + ".bak", JSON.stringify(backup))
	var future := Progress.new(path)
	assert(not future.load_game() and future.read_only and not future.set_auto(true))
	assert(JSON.parse_string(FileAccess.get_file_as_string(path)).version == 2)
	print("PASS: first/repeat rewards, locks, duplicate claims, defeat/abandon, restart, full chapter, failed commit/retry, backup recovery, damaged-file preservation and future schema")
	quit()
