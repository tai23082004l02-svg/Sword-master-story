extends SceneTree

const Model = preload("res://game/battle.gd")
func _initialize() -> void:
	var b = Model.new()
	b.start()
	assert(b.wave == 1 and b.enemies.size() == 2)
	assert(b.skill())
	assert(not b.skill())
	b.state = "paused"
	var timer: float = b.cooldown
	b.tick(1)
	assert(b.cooldown == timer)
	b.state = "playing"
	for i in range(18000):
		b.skill()
		b.tick(1.0 / 60)
		if b.state != "playing":
			break
	assert(b.state == "won", "Active skill run must win")
	assert(b.kills == 10 and b.wave == 4)
	var hp: float = b.hero_hp
	b.tick(5)
	assert(b.hero_hp == hp)
	b.start()
	assert(b.hero_hp == 220 and b.wave == 1 and b.kills == 0)
	b.hero_hp = 1
	b.enemies[0].x = b.hero_x + 10
	b.enemies[0].windup = 0.01
	b.tick(0.02)
	assert(b.state == "lost")
	assert(not b.skill())
	print("PASS: waves, win, defeat, cooldown, pause, restart, terminal state")
	quit()
