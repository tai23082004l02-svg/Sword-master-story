class_name BossBrain
extends RefCounted
## Predictable auto-combat pattern. No vulnerability, damage multipliers or skill windows.
const MOVES = [
	{"name": "Chém đại kiếm", "kind": "slash", "damage": 9.0, "range": 155.0, "windup": 0.55, "rest": 1.65},
	{"name": "Sóng nguyệt thực", "kind": "wave", "damage": 12.0, "range": 1000.0, "windup": 0.8, "rest": 1.9},
	{"name": "Phán quyết bóng đêm", "kind": "heavy", "damage": 17.0, "range": 180.0, "windup": 1.1, "rest": 2.0}
]

static func create(id: int) -> Dictionary:
	return {"id": id, "boss": true, "x": 1000.0, "hp": 600.0, "max_hp": 600.0, "ranged": false, "timer": 1.2, "windup": 0.0, "windup_total": 0.55, "rest_total": 1.2, "phase": 1, "phase_flash": 0.0, "move_index": 0, "attack_kind": "slash", "attack_name": "", "last_attack": "", "impact": 0.0}

static func tick(enemy: Dictionary, dt: float, hero_x: float) -> Dictionary:
	var event := {"damage": 0.0, "phase_changed": false}
	enemy.impact = maxf(0, enemy.impact - dt)
	enemy.phase_flash = maxf(0, enemy.phase_flash - dt)
	if enemy.hp <= 0:
		return event
	if enemy.phase == 1 and enemy.hp <= enemy.max_hp * 0.5:
		enemy.phase = 2
		enemy.phase_flash = 0.75
		event.phase_changed = true
	var move: Dictionary = MOVES[enemy.move_index % MOVES.size()]
	if enemy.windup > 0:
		enemy.windup -= dt
		if enemy.windup <= 0:
			if absf(enemy.x - hero_x) <= move.range:
				event.damage = move.damage + (2.0 if enemy.phase == 2 else 0.0)
			enemy.last_attack = move.kind
			enemy.impact = 0.25
			enemy.rest_total = move.rest * (0.8 if enemy.phase == 2 else 1.0)
			enemy.timer = enemy.rest_total
			enemy.move_index += 1
		return event
	enemy.timer = maxf(0, enemy.timer - dt)
	if absf(enemy.x - hero_x) > 125:
		enemy.x = move_toward(enemy.x, hero_x, 48 * dt)
	elif enemy.timer <= 0:
		enemy.attack_kind = move.kind
		enemy.attack_name = move.name
		enemy.windup_total = move.windup
		enemy.windup = move.windup
	return event
