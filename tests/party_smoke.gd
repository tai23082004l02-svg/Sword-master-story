extends SceneTree
const Model = preload("res://game/battle.gd")
func _initialize() -> void:
	var b = Model.new()
	b.start(5)
	assert(b.heroes.size() == 5)
	assert(b.skill(1))
	assert(b.heroes.all(func(a): return a.shield == 35))
	b.damage_hero(b.heroes[0], 45)
	assert(b.hero_hp == 210 and b.heroes[0].shield == 0)
	assert(b.skill(4) and b.hero_hp == 220)
	b.heroes[0].hp = 0
	assert(not b.skill(0))
	b.heroes[2].hp = 70
	b.heroes[4].cooldown_left = 0
	assert(b.skill(4))
	assert(b.hero_hp == 0 and b.heroes[2].hp == 125)
	var before: float = b.enemies[0].hp
	assert(b.skill(2))
	assert(b.enemies[0].hp == before - 85 and b.enemies[1].hp == 67)
	b.tick(0.1)
	assert(b.state == "playing", "Leader death must not defeat surviving team")
	b.state = "paused"
	var snapshot: Array = b.heroes.duplicate(true)
	b.tick(1)
	assert(b.heroes == snapshot and not b.skill(3))
	b.state = "playing"
	for a in b.heroes:
		a.hp = 0
	b.enemies.clear()
	b.wave = 4
	b.tick(0.01)
	assert(b.state == "lost", "Team defeat takes precedence")
	for size in range(1, 6):
		b.start(size)
		for frame in range(18000):
			for slot in range(size):
				b.skill(slot)
			b.tick(1.0 / 60)
			if b.state != "playing":
				break
		assert(b.state == "won" and b.kills == 10)
		assert(b.heroes.size() == size)
		print("Party %d wins in %.1fs" % [size, b.elapsed])
	b.start(5)
	assert(b.heroes.all(func(a): return a.hp == a.max_hp and a.shield == 0 and a.cooldown_left == 0))
	# An enemy cannot redirect a committed attack after its target dies.
	var e: Dictionary = b.enemies[0]
	e.x = b.heroes[1].x
	e.target = "aether"
	e.windup = 0.01
	b.hero_hp = 0
	var hp: float = b.heroes[1].hp
	b.tick(0.02)
	assert(b.heroes[1].hp == hp)
	b.start(5)
	b.wave = 3
	b.enemies.clear()
	b.spawn_wave()
	var boss: Dictionary = b.enemies[0]
	boss.x = b.hero_x + 20
	boss.timer = 0
	b.tick(0.01)
	assert(boss.target == "aether" and boss.windup > 0)
	b.hero_hp = 0
	var ally_hp: float = b.heroes[1].hp
	for i in range(60):
		b.tick(0.01)
	assert(b.heroes[1].hp == ally_hp)
	print("PASS: roster, independent cooldowns, shields, capped healing, no resurrection, targeting, pause, defeat, all party sizes and reset")
	quit()
