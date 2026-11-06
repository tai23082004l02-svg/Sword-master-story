extends RefCounted
## Transactional local progression. Audio settings remain in their original file.
const Campaign = preload("res://game/campaign_data.gd")
var path: String
var data: Dictionary
var last_error := ""
var recovered := false
var read_only := false
func _init(save_path: String = "user://campaign.json") -> void:
	path = save_path
	data = defaults()
func defaults() -> Dictionary:
	return {"version": 1, "gold": 0, "xp": 0, "cleared": [], "records": {}, "formation": [0, 1, 2, 3, 4], "auto_skills": false, "serial": 0, "last_claimed": 0, "pending": {}}
func whole(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value == floorf(value) and value >= low and value <= high
func valid(candidate: Variant) -> bool:
	if not candidate is Dictionary or not candidate.has_all(defaults().keys()): return false
	if not whole(candidate.version, 1, 1): return false
	for key in ["gold", "xp", "serial", "last_claimed"]:
		if not whole(candidate[key], 0, 9007199254740991): return false
	if candidate.last_claimed > candidate.serial or not candidate.auto_skills is bool: return false
	if not candidate.cleared is Array or candidate.cleared.size() > 10 or not candidate.records is Dictionary: return false
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
		if not whole(value, 0, 4) or int(value) in seen: return false
		seen.append(int(value))
	if not candidate.pending is Dictionary: return false
	if not candidate.pending.is_empty():
		if not candidate.pending.has_all(["id", "stage"]): return false
		if not whole(candidate.pending.id, 1, int(candidate.serial)) or candidate.pending.id != candidate.serial or candidate.pending.id <= candidate.last_claimed: return false
		if not whole(candidate.pending.stage, 1, mini(10, candidate.cleared.size() + 1)): return false
	return true
func normalize(candidate: Dictionary) -> Dictionary:
	var result := candidate.duplicate(true)
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
		if raw is Dictionary and raw.get("version", 1) != 1:
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
	return mini(10, data.cleared.size() + 1)
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
	candidate.pending = {"id": candidate.serial, "stage": stage_id}
	return int(candidate.serial) if commit(candidate) else -1
func finish_run(run_id: int, won: bool, elapsed: float, survivors: int) -> Dictionary:
	if data.pending.is_empty() or data.pending.id != run_id or run_id <= data.last_claimed or not is_finite(elapsed) or elapsed < 0:
		return {"ok": false, "error": "Trận này đã kết thúc hoặc không còn hợp lệ."}
	var candidate := data.duplicate(true)
	var id := int(candidate.pending.stage)
	var first: bool = won and not id in candidate.cleared
	var reward := Campaign.reward(id, first) if won else {"gold": 0, "xp": 0}
	if won:
		candidate.gold += reward.gold
		candidate.xp += reward.xp
		if first: candidate.cleared.append(id)
		var key := str(id)
		var previous: Dictionary = candidate.records.get(key, {"wins": 0, "best_time": elapsed})
		candidate.records[key] = {"wins": previous.wins + 1, "best_time": minf(previous.best_time, elapsed)}
	candidate.last_claimed = run_id
	candidate.pending = {}
	if not commit(candidate): return {"ok": false, "error": last_error}
	return {"ok": true, "won": won, "stage": id, "first": first, "gold": reward.gold, "xp": reward.xp, "elapsed": elapsed, "survivors": survivors}
func abandon_run(run_id: int) -> bool:
	if data.pending.is_empty() or data.pending.id != run_id: return true
	var candidate := data.duplicate(true)
	candidate.pending = {}
	return commit(candidate)
