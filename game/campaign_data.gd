extends RefCounted
## Original chapter data. No third-party content, economy or network dependencies.
const TITLES = ["Cổng phế tích", "Lối rừng bạc", "Cầu đá cổ", "Sân vọng nguyệt", "Kỵ sĩ canh cổng", "Hành lang đổ nát", "Vườn u ảnh", "Điện trăng khuyết", "Bậc thềm cuối", "Ngai Nguyệt Thực"]
const COUNTS = [[2, 2], [2, 3], [2, 3, 3], [3, 3, 4], [3, 3], [3, 4, 4], [4, 4, 4], [4, 4, 5], [4, 5, 5], [4, 5, 5]]
const HP = [50, 62, 74, 86, 95, 108, 122, 138, 154, 170]
const DAMAGE = [0.7, 0.8, 0.9, 1.0, 1.05, 1.1, 1.15, 1.2, 1.3, 1.45]
static func stage(id: int) -> Dictionary:
	assert(id >= 1 and id <= 10)
	var waves: Array[Dictionary] = []
	for w in range(COUNTS[id - 1].size()):
		var kinds: Array[String] = []
		for i in range(COUNTS[id - 1][w]):
			kinds.append("ranged" if id > 1 and (i + w) % 3 == 2 else "melee")
		waves.append({"enemies": kinds, "hp": float(HP[id - 1] + w * 6)})
	if id in [5, 10]:
		waves.append({"boss_hp": 750.0 if id == 5 else 1500.0})
	return {"id": id, "title": TITLES[id - 1], "waves": waves, "damage_scale": DAMAGE[id - 1], "gold": 20 + id * 10, "xp": 8 + id * 4, "first_gold": 80 + id * 20, "first_xp": 30 + id * 10}
static func reward(id: int, first: bool) -> Dictionary:
	var s := stage(id)
	return {"gold": s.gold + (s.first_gold if first else 0), "xp": s.xp + (s.first_xp if first else 0)}
