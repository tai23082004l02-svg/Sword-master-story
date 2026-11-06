extends RefCounted
## Original fixed catalogue; one copy of each item per profile.
const ITEMS = {
	"iron_blade": {"name": "Kiếm sắt", "slot": "weapon", "hp": 0, "damage": 4, "gold": 80},
	"moon_blade": {"name": "Kiếm nguyệt", "slot": "weapon", "hp": 0, "damage": 9, "gold": 240},
	"dawn_blade": {"name": "Kiếm bình minh", "slot": "weapon", "hp": 0, "damage": 16, "gold": 520},
	"linen_armor": {"name": "Giáp vải", "slot": "armor", "hp": 35, "damage": 0, "gold": 80},
	"moon_armor": {"name": "Giáp nguyệt", "slot": "armor", "hp": 80, "damage": 0, "gold": 240},
	"dawn_armor": {"name": "Giáp bình minh", "slot": "armor", "hp": 140, "damage": 0, "gold": 520}
}
static func empty_slots() -> Array:
	return [{"weapon": "", "armor": ""}, {"weapon": "", "armor": ""}, {"weapon": "", "armor": ""}, {"weapon": "", "armor": ""}, {"weapon": "", "armor": ""}]
static func apply(actor: Dictionary, slots: Dictionary) -> Dictionary:
	for id in slots.values():
		if ITEMS.has(id):
			actor.hp += ITEMS[id].hp
			actor.damage += ITEMS[id].damage
	return actor
