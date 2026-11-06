extends SceneTree
const Model = preload("res://game/battle.gd")
const Brain = preload("res://game/boss_brain.gd")
func _initialize() -> void:
	var transition = Model.new()
	transition.start()
	transition.wave = 3
	transition.enemies.clear()
	transition.hero_hp = 123
	transition.tick(1.21)
	assert(transition.state == "playing" and transition.wave == 4)
	assert(transition.enemies.size() == 1 and transition.enemies[0].boss)
	assert(transition.hero_hp == 123)
	var boss := Brain.create(100)
	var names: Dictionary = {}
	for i in range(10000):
		var event := Brain.tick(boss, 1.0/60, 900)
		if event.damage > 0:
			names[boss.last_attack] = true
		if names.size() == 3:
			break
	assert(names.size() == 3)
	boss.hp = 300
	assert(Brain.tick(boss, 0.01, 900).phase_changed)
	assert(boss.phase == 2)
	assert(not Brain.tick(boss, 0.01, 900).phase_changed)
	for state in ["rest", "windup", "phase2"]:
		var b = Model.new()
		b.start()
		b.wave = 3
		b.enemies.clear()
		b.spawn_wave()
		if state == "windup":
			b.enemies[0].windup = 0.5
		elif state == "phase2":
			b.enemies[0].hp = 280
			b.enemies[0].phase = 2
		var before: float = b.enemies[0].hp
		assert(b.skill())
		assert(b.enemies[0].hp == before - 48, "Skill damage is constant in every boss state")
		b.state = "paused"
		var timer: float = b.enemies[0].timer
		b.tick(1)
		assert(b.enemies[0].timer == timer)
		b.state = "playing"
		b.enemies[0].hp = 1
		b.hit(0, 22)
		b.tick(0.01)
		assert(b.state == "won")
	print("PASS: three boss moves, phase threshold once, constant skill damage, pause, boss victory")
	quit()
