extends RefCounted
## Original prototype roster and independent actor state.
const MAX_LEVEL := 20
const HEROES = [
	{"id": "aether", "name": "Aether", "role": "Kiếm sĩ", "hp": 220.0, "damage": 22.0, "range": 85.0, "recovery": 0.48, "color": "91dcf0", "skill": "Kiếm khí", "kind": "area", "power": 48.0, "cooldown": 6.0},
	{"id": "brann", "name": "Brann", "role": "Hộ vệ", "hp": 320.0, "damage": 13.0, "range": 80.0, "recovery": 0.85, "color": "e5b76d", "skill": "Hộ thuẫn", "kind": "shield", "power": 35.0, "cooldown": 10.0},
	{"id": "lyra", "name": "Lyra", "role": "Cung thủ", "hp": 145.0, "damage": 17.0, "range": 310.0, "recovery": 0.8, "color": "8fe1a4", "skill": "Xuyên tinh", "kind": "single", "power": 85.0, "cooldown": 8.0},
	{"id": "nyx", "name": "Nyx", "role": "Pháp sư", "hp": 130.0, "damage": 15.0, "range": 280.0, "recovery": 1.0, "color": "c397f4", "skill": "Tinh hỏa", "kind": "area", "power": 38.0, "cooldown": 9.0},
	{"id": "sol", "name": "Sol", "role": "Trị liệu", "hp": 155.0, "damage": 8.0, "range": 260.0, "recovery": 1.1, "color": "ffe79a", "skill": "Bình minh", "kind": "heal", "power": 55.0, "cooldown": 10.0},
	{"id":"iris","name":"Iris","role":"Phá giáp","hp":180.0,"damage":19.0,"range":290.0,"recovery":0.9,"color":"a9e7ff","skill":"Băng toái","kind":"single","power":70.0,"cooldown":9.0},
	{"id":"rune","name":"Rune","role":"Hộ pháp","hp":280.0,"damage":11.0,"range":85.0,"recovery":0.9,"color":"ffa7c9","skill":"Thánh ấn","kind":"shield","power":40.0,"cooldown":11.0},
	{"id":"vera","name":"Vera","role":"Dưỡng sinh","hp":160.0,"damage":10.0,"range":280.0,"recovery":1.0,"color":"b4ef92","skill":"Sinh mạch","kind":"heal","power":45.0,"cooldown":9.0}
]

static func stats(index: int, level: int = 1) -> Dictionary:
	assert(index >= 0 and index < HEROES.size())
	var actor: Dictionary = HEROES[index].duplicate(true)
	actor.level = clampi(level, 1, MAX_LEVEL)
	var percent: int = 100 + (actor.level - 1) * 10
	# Integer ceiling avoids floating-point drift at exact HP boundaries.
	actor.hp = float((int(actor.hp) * percent + 99) / 100)
	actor.damage = float((int(actor.damage) * percent + 99) / 100)
	return actor

static func upgrade_cost(level: int) -> Dictionary:
	if level < 1 or level >= MAX_LEVEL: return {}
	return {"gold": 30 + (level - 1) * 20, "xp": level * 10}

static func create(index: int, level: int = 1) -> Dictionary:
	var actor := stats(index, level)
	actor.merge({"max_hp": actor.hp, "x": 240.0 - index * 42.0, "timer": 0.0, "windup": 0.0, "target": -1, "cooldown_left": 0.0, "shield": 0.0, "visual": 0.0})
	return actor
