extends RefCounted
## Original chapter data. No third-party content, economy or network dependencies.
const MAX_STAGE := 30
const CHAPTERS = ["Phế tích Ngân Nguyệt", "Lò rèn Tro Hồng", "Thành trì Bình Minh"]
const TITLES = ["Cổng phế tích", "Lối rừng bạc", "Cầu đá cổ", "Sân vọng nguyệt", "Kỵ sĩ canh cổng", "Hành lang đổ nát", "Vườn u ảnh", "Điện trăng khuyết", "Bậc thềm cuối", "Ngai Nguyệt Thực"]
const COUNTS = [[2, 2], [2, 3], [2, 3, 3], [3, 3, 4], [3, 3], [3, 4, 4], [4, 4, 4], [4, 4, 5], [4, 5, 5], [4, 5, 5]]
const HP = [50, 62, 74, 86, 95, 108, 122, 138, 154, 170]
const DAMAGE = [0.7, 0.8, 0.9, 1.0, 1.05, 1.1, 1.15, 1.2, 1.3, 1.45]
static func stage(id: int) -> Dictionary:
	assert(id >= 1 and id <= MAX_STAGE)
	var local_id := (id - 1) % 10 + 1
	var chapter := int((id - 1) / 10)
	var waves: Array[Dictionary] = []
	for w in range(COUNTS[local_id - 1].size()):
		var kinds: Array[String] = []
		for i in range(COUNTS[local_id - 1][w]):
			var kind := "ranged" if id > 1 and (i + w) % 3 == 2 else "melee"
			if chapter > 0 and i == 0: kind = "armored"
			if chapter > 0 and i == 2: kind = "healer"
			if chapter == 2 and i == 1: kind = "assassin"
			kinds.append(kind)
		waves.append({"enemies": kinds, "hp": float(HP[local_id - 1] + chapter * 115 + w * 6)})
	if local_id in [5, 10]:
		waves.append({"boss_hp": (750.0 if local_id == 5 else 1500.0) + chapter * 800.0})
	return {"id": id, "title": TITLES[local_id - 1] if chapter == 0 else ("Tro Hồng" if chapter == 1 else "Bình Minh") + " · " + str(local_id), "waves": waves, "damage_scale": DAMAGE[local_id - 1] + chapter * 0.5, "gold": 20 + id * 10, "xp": 8 + id * 4, "first_gold": 80 + id * 20, "first_xp": 30 + id * 10}
static func reward(id: int, first: bool) -> Dictionary:
	var s := stage(id)
	return {"gold": s.gold + (s.first_gold if first else 0), "xp": s.xp + (s.first_xp if first else 0)}

static func label(id: int) -> String:
	return "%d-%02d" % [int((id-1)/10)+1,(id-1)%10+1]
