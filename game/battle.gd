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

func start(party_size: int = 1) -> void:
	heroes.clear()
	for i in range(clampi(party_size, 1, 5)):
		heroes.append(Party.create(i))
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
	if wave == 4:
		serial += 1
		enemies.append(Boss.create(serial))
	else:
		for i in range(wave + 1):
			serial += 1
			enemies.append({"id": serial, "x": 820.0 + i * 105.0, "hp": 55.0 + wave * 12.0, "max_hp": 55.0 + wave * 12.0, "ranged": i % 2 == 1, "timer": 0.8 + i * 0.25, "windup": 0.0, "target": ""})
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
	match actor.kind:
		"area":
			for i in range(enemies.size()):
				hit(i, actor.power)
		"single": hit(target_index(actor.x), actor.power)
		"heal", "shield":
			for ally in heroes:
				if ally.hp <= 0:
					continue
				if actor.kind == "heal":
					ally.hp = minf(ally.max_hp, ally.hp + actor.power)
				else:
					ally.shield = maxf(ally.shield, actor.power)
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
					hit(i, actor.damage)
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
		if wave == 4:
			state = "won"
			cue.emit("win")
			return
		intermission += dt
		if intermission >= 1.2:
			intermission = 0
			spawn_wave()
		return
	for actor in heroes:
		tick_actor(actor, dt)
	for enemy in enemies:
		if enemy.hp <= 0:
			continue
		var victim := living_target(enemy.x)
		if victim.is_empty():
			break
		if enemy.get("boss", false):
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
				damage_hero(victim, event.damage)
			continue
		var attack_range := 330.0 if enemy.ranged else 75.0
		if enemy.windup > 0:
			enemy.windup -= dt
			if enemy.windup <= 0:
				# Lock the victim at windup; never silently redirect a committed hit.
				for ally in heroes:
					if ally.id == enemy.get("target", victim.id) and ally.hp > 0 and absf(enemy.x - ally.x) <= attack_range + 20:
						damage_hero(ally, 7.0 if enemy.ranged else 10.0)
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
