extends RefCounted
## Original offline progression catalogue and validation.
const MAX_STAGE := 30
const HERO_COUNT := 8
const ITEMS = {
	"ember_sword": {"name":"Kiếm tro hồng", "slot":"weapon", "damage":6, "hp":0, "set":"ember", "chapter":1},
	"ember_mail": {"name":"Giáp tro hồng", "slot":"armor", "damage":0, "hp":45, "set":"ember", "chapter":1},
	"bastion_sword": {"name":"Kiếm thành trì", "slot":"weapon", "damage":10, "hp":0, "set":"bastion", "chapter":2},
	"bastion_mail": {"name":"Giáp thành trì", "slot":"armor", "damage":0, "hp":95, "set":"bastion", "chapter":2},
	"dawn_staff": {"name":"Trượng bình minh", "slot":"weapon", "damage":14, "hp":0, "set":"dawn", "chapter":3},
	"dawn_robe": {"name":"Áo bình minh", "slot":"armor", "damage":0, "hp":130, "set":"dawn", "chapter":3}
}
const PASSIVES = ["Kiếm khí gây thêm 20% lên mục tiêu bị phá giáp.", "Dưới 50% HP nhận giảm 20% sát thương.", "Đánh thường thêm 15% lên địch bị thiêu đốt.", "Tinh hỏa thiêu đốt địch 3 giây.", "Trị liệu xóa 20% hồi chiêu của đồng đội.", "Phá giáp mục tiêu 6 giây bằng kỹ năng.", "Hộ thuẫn hồi thêm 20 HP cho đồng đội.", "Đòn thường hồi 4 HP cho đồng đội yếu nhất."]
const GOALS = [
	{"id":"first", "name":"Bước đầu · Vượt 1 ải", "kind":"clear", "target":1, "gold":100, "gems":100},
	{"id":"five", "name":"Cổng hầm · Vượt 5 ải", "kind":"clear", "target":5, "gold":180, "gems":200},
	{"id":"ten", "name":"Chương II · Vượt 10 ải", "kind":"clear", "target":10, "gold":300, "gems":300},
	{"id":"twenty", "name":"Chương III · Vượt 20 ải", "kind":"clear", "target":20, "gold":500, "gems":400},
	{"id":"smith", "name":"Thợ rèn · Cường hóa 3 lần", "kind":"enhance", "target":3, "gold":200, "gems":150},
	{"id":"collector", "name":"Nhà sưu tầm · Triệu hồi 10 lần", "kind":"summons", "target":10, "gold":300, "gems":200}
]
static func defaults() -> Dictionary:
	var slots: Array = []
	for i in range(HERO_COUNT): slots.append({"weapon":0, "armor":0})
	return {"inventory":[], "next_uid":1, "slots":slots, "dust":0, "gems":600, "tickets":0, "sweep_tokens":5, "pity":0, "wishlist":5, "shards":[0,0,0,0,0,0,0,0], "recruited":[true,true,true,true,true,false,false,false], "extra_levels":[1,1,1], "skill_levels":[1,1,1,1,1,1,1,1], "ascension":[0,0,0,0,0,0,0,0], "tower":0, "mode_records":{}, "stage_attempts":{}, "stage_losses":{}, "goals":[], "week":0, "weekly_wins":0, "weekly_claimed":false, "stats":{"runs":0,"wins":0,"enhance":0,"summons":0,"sweeps":0,"upgrades":0}, "active_days":[]}
static func integer(v: Variant, lo: int, hi: int) -> bool:
	return (v is int or v is float) and is_finite(float(v)) and floorf(v) == v and v >= lo and v <= hi
static func valid(r: Variant) -> bool:
	if not r is Dictionary or not r.has_all(defaults().keys()): return false
	for key in ["dust","gems","tickets","sweep_tokens","week","weekly_wins"]:
		if not integer(r[key],0,9007199254740991): return false
	if not integer(r.next_uid,1,9007199254740991) or not integer(r.pity,0,19) or not integer(r.wishlist,0,7) or not integer(r.tower,0,30) or not r.weekly_claimed is bool: return false
	for key in ["shards","recruited","skill_levels","ascension","slots"]:
		if not r[key] is Array or r[key].size() != HERO_COUNT: return false
	if not r.extra_levels is Array or r.extra_levels.size() != 3: return false
	for l in r.extra_levels:
		if not integer(l,1,20): return false
	for i in range(HERO_COUNT):
		if not integer(r.shards[i],0,9007199254740991) or not r.recruited[i] is bool or (i < 5 and not r.recruited[i]): return false
		if not integer(r.skill_levels[i],1,5) or not integer(r.ascension[i],0,5): return false
	if not r.inventory is Array or r.inventory.size() > 500: return false
	var ids: Array = []
	for item in r.inventory:
		if not item is Dictionary or not item.has_all(["uid","base","rank"]): return false
		if not integer(item.uid,1,int(r.next_uid)-1) or int(item.uid) in ids or not ITEMS.has(item.base) or not integer(item.rank,0,10): return false
		ids.append(int(item.uid))
	var equipped: Array = []
	for slots in r.slots:
		if not slots is Dictionary or slots.size() != 2 or not slots.has_all(["weapon","armor"]): return false
		for slot in ["weapon","armor"]:
			if not integer(slots[slot],0,int(r.next_uid)-1): return false
			if slots[slot] == 0: continue
			if not int(slots[slot]) in ids or int(slots[slot]) in equipped: return false
			var item: Dictionary = find_item(r,int(slots[slot]))
			if ITEMS[item.base].slot != slot: return false
			equipped.append(int(slots[slot]))
	for key in ["stage_attempts","stage_losses"]:
		if not r[key] is Dictionary: return false
		for stage in r[key]:
			if not stage is String or not stage.is_valid_int() or int(stage)<1 or int(stage)>30 or not integer(r[key][stage],0,9007199254740991): return false
	if not r.mode_records is Dictionary: return false
	for key in r.mode_records:
		if key not in ["gold","material","tower","challenge"] or not integer(r.mode_records[key],0,9007199254740991): return false
	if not r.stats is Dictionary or not r.stats.has_all(defaults().stats.keys()): return false
	for value in r.stats.values():
		if not integer(value,0,9007199254740991): return false
	if not r.goals is Array or r.goals.size() > GOALS.size(): return false
	var seen: Array = []
	for id in r.goals:
		if not id is String or id in seen or not GOALS.any(func(g): return g.id == id): return false
		seen.append(id)
	if not r.active_days is Array or r.active_days.size() > 90: return false
	var prior := -1
	for day in r.active_days:
		if not integer(day,0,9007199254740991) or day <= prior: return false
		prior = int(day)
	return true
static func find_item(r: Dictionary, uid: int) -> Dictionary:
	for item in r.inventory:
		if int(item.uid) == uid: return item
	return {}
static func grant_item(r: Dictionary, base: String) -> Dictionary:
	if r.inventory.size() >= 500:
		r.dust += 5
		return {"name":"Kho đầy: chuyển thành 5 bụi", "uid":0}
	var item := {"uid":int(r.next_uid),"base":base,"rank":0}
	r.next_uid += 1
	r.inventory.append(item)
	return {"name":ITEMS[base].name,"uid":item.uid}
static func chapter(id: int) -> int:
	return mini(3, 1 + int((id-1)/10))
static func drop_base(id: int, wins: int) -> String:
	var keys := ["ember_sword","ember_mail","bastion_sword","bastion_mail","dawn_staff","dawn_robe"]
	return keys[(chapter(id)-1)*2 + ((wins+id) % 2)]
static func week_now() -> int:
	return int((int(Time.get_unix_time_from_system()) / 86400 + 3) / 7)
static func visit(r: Dictionary) -> void:
	var day := int(Time.get_unix_time_from_system()) / 86400
	if r.active_days.is_empty() or day > r.active_days.back():
		r.active_days.append(day)
		if r.active_days.size() > 90: r.active_days.pop_front()
	var week := week_now()
	if week > r.week:
		r.week = week
		r.weekly_wins = 0
		r.weekly_claimed = false

static func normalize(r: Dictionary) -> Dictionary:
	for key in ["next_uid","dust","gems","tickets","sweep_tokens","pity","wishlist","tower","week","weekly_wins"]: r[key]=int(r[key])
	for key in ["shards","extra_levels","skill_levels","ascension","active_days"]:
		for i in range(r[key].size()): r[key][i]=int(r[key][i])
	for item in r.inventory:
		item.uid=int(item.uid)
		item.rank=int(item.rank)
	for slots in r.slots:
		slots.weapon=int(slots.weapon)
		slots.armor=int(slots.armor)
	for key in r.stats: r.stats[key]=int(r.stats[key])
	for key in r.mode_records: r.mode_records[key]=int(r.mode_records[key])
	for collection in ["stage_attempts","stage_losses"]:
		for key in r[collection]: r[collection][key]=int(r[collection][key])
	return r
