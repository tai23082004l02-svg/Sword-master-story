extends SceneTree
const Campaign = preload("res://game/campaign_data.gd")
const Model = preload("res://game/battle.gd")
func _initialize() -> void:
	for id in range(1, 11):
		var stage := Campaign.stage(id)
		var b := Model.new()
		b.start(5, [0, 4, 2, 1, 3], stage)
		var expected := 0
		for wave in stage.waves: expected += 1 if wave.has("boss_hp") else wave.enemies.size()
		var saw_boss := false
		for frame in range(18000):
			for slot in range(5): b.skill(slot)
			if b.boss_wave(): saw_boss = true
			b.tick(1.0 / 60)
			if b.state != "playing": break
		assert(b.state == "won", "Default party must be able to clear stage %d with active skills" % id)
		assert(b.kills == expected and b.wave == stage.waves.size())
		assert(saw_boss == (id in [5, 10]))
		assert(b.heroes[1].id == "sol" and b.heroes[3].id == "brann")
		print("Stage %d: %d enemies, %.1fs, %d survivors" % [id, b.kills, b.elapsed, b.heroes.filter(func(a): return a.hp > 0).size()])
	print("PASS: ten configured stages, distinct wave layouts, bosses 5/10, reordered roster, all stages winnable with skills")
	quit()
