class_name Battle
extends RefCounted

const Boss = preload("res://game/boss_brain.gd")

signal cue(event: String)
var state := "idle"
var wave := 0
var hero_hp := 220.0
var hero_x := 240.0
var enemies: Array[Dictionary] = []
var cooldown := 0.0
var hero_timer := 0.0
var windup := 0.0
var pending_target := -1
var elapsed := 0.0
var intermission := 0.0
var serial := 0
var effects: Array[Dictionary] = []
var kills := 0

func start() -> void:
	state = "playing"
	wave = 0
	hero_hp = 220.0
	hero_x = 240.0
	enemies.clear()
	effects.clear()
	cooldown = 0.0
	hero_timer = 0.0
	windup = 0.0
	pending_target = -1
	elapsed = 0.0
	intermission = 0.0
	kills = 0
	spawn_wave()

func spawn_wave() -> void:
	wave += 1
	hero_x = 240.0
	if wave == 4:
		serial += 1
		enemies.append(Boss.create(serial))
		cue.emit("wave")
		return
	for i in range(wave + 1):
		serial += 1
		var ranged := i % 2 == 1
		enemies.append({"id": serial, "x": 820.0 + i * 105.0, "hp": 55.0 + wave * 12.0, "max_hp": 55.0 + wave * 12.0, "ranged": ranged, "timer": 0.8 + i * 0.25, "windup": 0.0})
	cue.emit("wave")

func target_index() -> int:
	var result := -1
	var distance := INF
	for i in range(enemies.size()):
		var d: float = absf(enemies[i].x - hero_x)
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

func skill() -> bool:
	if state != "playing" or cooldown > 0 or enemies.is_empty() or intermission > 0:
		return false
	cooldown = 6.0
	for i in range(enemies.size()):
		hit(i, 48.0)
	cue.emit("skill")
	return true

func tick(dt: float) -> void:
	if state != "playing":
		return
	elapsed += dt
	cooldown = maxf(0, cooldown - dt)
	for effect in effects:
		effect.ttl -= dt
	effects = effects.filter(func(e): return e.ttl > 0)
	enemies = enemies.filter(func(e): return e.hp > 0)
	if enemies.is_empty():
		windup = 0
		pending_target = -1
		if wave == 4:
			state = "won"
			cue.emit("win")
			return
		intermission += dt
		if intermission >= 1.2:
			intermission = 0
			spawn_wave()
		return
	var target := target_index()
	if target < 0:
		return
	if windup > 0:
		windup -= dt
		if windup <= 0:
			for i in range(enemies.size()):
				if enemies[i].id == pending_target and absf(enemies[i].x - hero_x) < 110:
					hit(i, 22)
					break
			pending_target = -1
			hero_timer = 0.48
	else:
		hero_timer = maxf(0, hero_timer - dt)
		if absf(enemies[target].x - hero_x) > 85:
			hero_x = move_toward(hero_x, enemies[target].x, 145 * dt)
		elif hero_timer <= 0:
			windup = 0.18
			pending_target = enemies[target].id
	for enemy in enemies:
		if enemy.hp <= 0:
			continue
		if enemy.get("boss", false):
			var event := Boss.tick(enemy, dt, hero_x)
			if event.phase_changed:
				cue.emit("skill")
			if event.damage > 0:
				hero_hp = maxf(0, hero_hp - event.damage)
				effects.append({"x": hero_x, "text": "-%d" % int(event.damage), "ttl": 0.6, "skill": false})
			continue
		var attack_range := 330.0 if enemy.ranged else 75.0
		if enemy.windup > 0:
			enemy.windup -= dt
			if enemy.windup <= 0 and absf(enemy.x - hero_x) <= attack_range + 20:
				hero_hp = maxf(0, hero_hp - (7.0 if enemy.ranged else 10.0))
				effects.append({"x": hero_x, "text": "-7" if enemy.ranged else "-10", "ttl": 0.6, "skill": false})
				enemy.timer = 1.8
		else:
			enemy.timer = maxf(0, enemy.timer - dt)
			if absf(enemy.x - hero_x) > attack_range:
				enemy.x = move_toward(enemy.x, hero_x, 65 * dt)
			elif enemy.timer <= 0:
				enemy.windup = 0.45
	if hero_hp <= 0:
		state = "lost"
		windup = 0
		cue.emit("lose")
