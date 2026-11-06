class_name Battle
extends RefCounted

const Boss = preload("res://game/boss_brain.gd")
const Party = preload("res://game/party_data.gd")
signal cue(event: String)
var state := "idle"
var wave := 0
var heroes: Array[Dictionary] = []
# Leader aliases retain the solo prototype API and its regression checks.
var hero_hp: float:
	get: return heroes[0].hp if not heroes.is_empty() else 220.0
	set(value): heroes[0].hp = value
var hero_x: float:
	get: return heroes[0].x if not heroes.is_empty() else 240.0
	set(value): heroes[0].x = value
var cooldown: float:
	get: return heroes[0].cooldown_left if not heroes.is_empty() else 0.0
	set(value): heroes[0].cooldown_left = value
var hero_timer: float:
	get: return heroes[0].timer if not heroes.is_empty() else 0.0
var windup: float:
	get: return heroes[0].windup if not heroes.is_empty() else 0.0
var enemies: Array[Dictionary] = []
var elapsed := 0.0
var intermission := 0.0
var serial := 0
var effects: Array[Dictionary] = []
var kills := 0
var stage_config: Dictionary = {}
var wave_limit: int:
	get: return stage_config.waves.size() if not stage_config.is_empty() else 4
func boss_wave() -> bool:
	return stage_config.waves[wave - 1].has("boss_hp") if not stage_config.is_empty() else wave == 4

func start(party_size: int = 1, roster: Array = [], stage: Dictionary = {}, levels: Array = [], equipment: Array = [], snapshots: Array = []) -> void:
	stage_config = stage.duplicate(true)
	heroes.clear()
	var selected: Array = roster.duplicate() if not roster.is_empty() else range(clampi(party_size, 1, 5))
	assert(selected.size() >= 1 and selected.size() <= 5 and selected[0] == 0)
	var used: Array = []
	for i in range(selected.size()):
		assert(selected[i] >= 0 and selected[i] < Party.HEROES.size() and not selected[i] in used)
		used.append(selected[i])
		var level: int = int(levels[selected[i]]) if selected[i] < levels.size() else 1
		var actor := Party.create(selected[i], level)
		if selected[i] < equipment.size():
			preload("res://game/equipment_data.gd").apply(actor, equipment[selected[i]])
			actor.max_hp = actor.hp
		if selected[i] < snapshots.size():
			for key in ["hp","damage","power","cooldown","set_bonus"]:
				actor[key] = snapshots[selected[i]].get(key,actor.get(key,""))
			actor.max_hp = actor.hp
		actor.x = 240.0 - i * 42.0
		heroes.append(actor)
	state = "playing"
	wave = 0
	enemies.clear()
	effects.clear()
	elapsed = 0.0
	intermission = 0.0
	kills = 0
	serial = 0
	spawn_wave()

func spawn_wave() -> void:
	wave += 1
	for i in range(heroes.size()):
		heroes[i].x = 240.0 - i * 42.0
		heroes[i].windup = 0.0
		heroes[i].target = -1
	if boss_wave():
		serial += 1
		var boss := Boss.create(serial)
		if not stage_config.is_empty():
			boss.hp = stage_config.waves[wave - 1].boss_hp
			boss.max_hp = boss.hp
		boss.variant = int((int(stage_config.get("id",1))-1)/10)
		boss.damage_scale = stage_config.get("damage_scale", 1.0)
		enemies.append(boss)
	else:
		var config: Dictionary = stage_config.waves[wave - 1] if not stage_config.is_empty() else {}
		var count: int = config.enemies.size() if not config.is_empty() else wave + 1
		for i in range(count):
			serial += 1
			var hp: float = config.get("hp", 55.0 + wave * 12.0)
			var kind: String = config.enemies[i] if not config.is_empty() else ("ranged" if i%2 == 1 else "melee")
			var ranged: bool = kind in ["ranged","healer"]
			enemies.append({"kind":kind,"heal_timer":4.0,"burn":0.0,"burn_tick":0.5,"broken":0.0,"id": serial, "x": 820.0 + i * 105.0, "hp": hp, "max_hp": hp, "ranged": ranged, "timer": 0.8 + i * 0.25, "windup": 0.0, "target": "", "damage_scale": stage_config.get("damage_scale", 1.0)})
	cue.emit("wave")

func target_index(origin: float = -1.0) -> int:
	var result := -1
	var distance := INF
	for i in range(enemies.size()):
		var d: float = absf(enemies[i].x - (hero_x if origin < 0 else origin))
		if enemies[i].hp > 0 and d < distance:
			distance = d
			result = i
	return result

func hit(index: int, amount: float) -> void:
	if index < 0 or index >= enemies.size() or enemies[index].hp <= 0:
		return
	if enemies[index].get("kind","") == "armored" and enemies[index].get("broken",0.0) <= 0: amount *= 0.65
	enemies[index].hp -= amount
	effects.append({"x": enemies[index].x, "text": str(int(amount)), "ttl": 0.65, "skill": amount > 30})
	cue.emit("hit")
	if enemies[index].hp <= 0:
		kills += 1

func skill(slot: int = 0) -> bool:
	if state != "playing" or slot < 0 or slot >= heroes.size() or intermission > 0 or target_index() < 0:
		return false
	var actor := heroes[slot]
	if actor.hp <= 0 or actor.cooldown_left > 0:
		return false
	actor.cooldown_left = actor.cooldown
	actor.visual = 0.48
	if stage_config.get("tactics",false):
		if actor.id == "iris": enemies[target_index(actor.x)].broken = 6.0
		if actor.id == "nyx":
			for enemy in enemies: enemy.burn = 3.0

	match actor.kind:
		"area":
			for i in range(enemies.size()):
				hit(i, actor.power * (1.2 if actor.id == "aether" and enemies[i].get("broken",0.0) > 0 else 1.0))
		"single": hit(target_index(actor.x), actor.power)
		"heal", "shield":
			for ally in heroes:
				if ally.hp <= 0:
					continue
				if actor.kind == "heal":
					ally.hp = minf(ally.max_hp, ally.hp + actor.power)
				else:
					ally.shield = maxf(ally.shield, actor.power)
				if stage_config.get("tactics",false) and actor.id == "rune": ally.hp = minf(ally.max_hp,ally.hp+20)
				if stage_config.get("tactics",false) and actor.id == "sol": ally.cooldown_left *= 0.8
	cue.emit("skill")
	return true

func living_target(x: float) -> Dictionary:
	var chosen: Dictionary = {}
	var distance := INF
	for actor in heroes:
		var d: float = absf(actor.x - x)
		if actor.hp > 0 and d < distance:
			chosen = actor
			distance = d
	return chosen

func damage_hero(actor: Dictionary, amount: float) -> void:
	if stage_config.get("tactics",false) and actor.id == "brann" and actor.hp < actor.max_hp*0.5: amount *= 0.8
	var absorbed := minf(actor.shield, amount)
	actor.shield -= absorbed
	actor.hp = maxf(0, actor.hp - amount + absorbed)
	effects.append({"x": actor.x, "text": "-%d" % int(amount - absorbed), "ttl": 0.6, "skill": false})

func tick_actor(actor: Dictionary, dt: float) -> void:
	if actor.hp <= 0:
		actor.windup = 0.0
		return
	var target := target_index(actor.x)
	if target < 0:
		return
	if actor.windup > 0:
		actor.windup -= dt
		if actor.windup <= 0:
			for i in range(enemies.size()):
				if enemies[i].id == actor.target and absf(enemies[i].x - actor.x) < actor.range + 25:
					var damage: float = actor.damage
					if stage_config.get("tactics",false) and actor.id == "lyra" and enemies[i].get("burn",0.0)>0: damage *= 1.15
					hit(i, damage)
					if stage_config.get("tactics",false) and actor.id == "vera":
						var weakest: Dictionary = {}
						for ally in heroes:
							if ally.hp > 0 and (weakest.is_empty() or ally.hp/ally.max_hp < weakest.hp/weakest.max_hp): weakest = ally
						if not weakest.is_empty(): weakest.hp = minf(weakest.max_hp,weakest.hp+4)
					break
			actor.target = -1
			actor.timer = actor.recovery
	else:
		actor.timer = maxf(0, actor.timer - dt)
		if absf(enemies[target].x - actor.x) > actor.range:
			actor.x = move_toward(actor.x, enemies[target].x, 145 * dt)
		elif actor.timer <= 0:
			actor.windup = 0.18
			actor.target = enemies[target].id

func tick(dt: float) -> void:
	if state != "playing":
		return
	elapsed += dt
	for actor in heroes:
		actor.cooldown_left = maxf(0, actor.cooldown_left - dt)
		actor.visual = maxf(0, actor.visual - dt)
	for effect in effects:
		effect.ttl -= dt
	effects = effects.filter(func(e): return e.ttl > 0)
	if living_target(0).is_empty():
		state = "lost"
		cue.emit("lose")
		return
	enemies = enemies.filter(func(e): return e.hp > 0)
	if enemies.is_empty():
		for actor in heroes:
			actor.windup = 0.0
			actor.target = -1
		if wave == wave_limit:
			state = "won"
			cue.emit("win")
			return
		intermission += dt
		if intermission >= 1.2:
			intermission = 0
			spawn_wave()
		return
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		enemy.broken = maxf(0,float(enemy.get("broken",0.0))-dt)
		if enemy.get("burn",0.0)>0 and enemy.hp>0:
			enemy.burn = maxf(0,float(enemy.burn)-dt)
			enemy.burn_tick = float(enemy.get("burn_tick",0.5))-dt
			if enemy.burn_tick <= 0:
				enemy.burn_tick = 0.5
				hit(i,4.0)
	for actor in heroes:
		tick_actor(actor, dt)
	for enemy in enemies:
		if enemy.hp <= 0:
			continue
		var victim := living_target(enemy.x)
		if enemy.get("kind","") == "assassin" and enemy.windup <= 0:
			for ally in heroes:
				if ally.hp > 0 and ally.x < victim.x: victim = ally
		if enemy.get("kind","") == "healer":
			enemy.heal_timer -= dt
			if enemy.heal_timer <= 0:
				enemy.heal_timer = 4.0
				for friend in enemies:
					if friend.hp>0: friend.hp = minf(friend.max_hp,friend.hp+friend.max_hp*0.08)
		if victim.is_empty():
			break
		if enemy.get("boss", false):
			if enemy.get("variant",0)==2 and enemy.move_index%3==1 and enemy.windup<=0:
				for ally in heroes:
					if ally.hp>0 and ally.x<victim.x: victim=ally
			var was_winding: bool = enemy.windup > 0
			if was_winding and enemy.has("target"):
				for ally in heroes:
					if ally.id == enemy.target:
						victim = ally
						break
			var event := Boss.tick(enemy, dt, victim.x)
			if not was_winding and enemy.windup > 0:
				enemy.target = victim.id
			if event.phase_changed:
				cue.emit("skill")
			if event.damage > 0 and victim.hp > 0:
				if event.get("all",false):
					for ally in heroes:
						if ally.hp>0: damage_hero(ally,event.damage*enemy.get("damage_scale",1.0))
				else: damage_hero(victim, event.damage * enemy.get("damage_scale", 1.0))
			continue
		var attack_range := 330.0 if enemy.ranged else 75.0
		if enemy.windup > 0:
			enemy.windup -= dt
			if enemy.windup <= 0:
				# Lock the victim at windup; never silently redirect a committed hit.
				for ally in heroes:
					if ally.id == enemy.get("target", victim.id) and ally.hp > 0 and absf(enemy.x - ally.x) <= attack_range + 20:
						damage_hero(ally, (7.0 if enemy.ranged else 10.0) * enemy.get("damage_scale", 1.0))
						break
				enemy.timer = 1.8
		else:
			enemy.timer = maxf(0, enemy.timer - dt)
			if absf(enemy.x - victim.x) > attack_range:
				enemy.x = move_toward(enemy.x, victim.x, 65 * dt)
			elif enemy.timer <= 0:
				enemy.windup = 0.45
				enemy.target = victim.id
	if living_target(0).is_empty():
		state = "lost"
		for actor in heroes:
			actor.windup = 0.0
		cue.emit("lose")
