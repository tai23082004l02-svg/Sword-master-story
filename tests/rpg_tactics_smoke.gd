extends SceneTree
const Model=preload("res://game/battle.gd")
const Campaign=preload("res://game/campaign_data.gd")
const Progress=preload("res://game/campaign_progress.gd")
const RPG=preload("res://game/rpg_data.gd")
func _initialize()->void:
	var stage:=Campaign.stage(11)
	stage.tactics=true
	var b:=Model.new()
	b.start(5,[0,5,2,3,4],stage,[1,1,1,1,1,1,1,1])
	assert(b.enemies[0].kind=="armored")
	var hp:float=b.enemies[0].hp
	b.hit(0,100)
	assert(is_equal_approx(hp-b.enemies[0].hp,65))
	b.enemies[0].hp=hp
	assert(b.skill(1) and b.enemies[0].broken==6.0)
	b.enemies[0].hp=hp
	b.hit(0,100)
	assert(is_equal_approx(hp-b.enemies[0].hp,100))
	b.enemies[0].hp=hp
	assert(b.skill(3) and b.enemies.all(func(e):return e.get("burn",0)>0))
	b.enemies[0].hp=hp
	assert(b.skill(0))
	assert(is_equal_approx(hp-b.enemies[0].hp,57.6))
	b.start(2,[0,6],stage,[1,1,1,1,1,1,1,1])
	b.heroes[0].hp-=40
	assert(b.skill(1) and b.heroes[0].shield==40 and b.heroes[0].hp==200)
	b.start(2,[0,7],stage,[1,1,1,1,1,1,1,1])
	b.heroes[0].hp-=40
	b.heroes[1].x=b.enemies[0].x
	b.heroes[1].windup=0.01
	b.heroes[1].target=b.enemies[0].id
	b.tick_actor(b.heroes[1],0.02)
	assert(b.heroes[0].hp==184)
	# Healer restores living allies; assassin telegraphs on the rear hero.
	stage.waves=[{"enemies":["healer","assassin","armored"],"hp":200.0}]
	b.start(2,[0,4],stage)
	b.enemies[0].heal_timer=0
	b.enemies[2].hp=100
	b.enemies[1].x=b.heroes[1].x+50
	b.enemies[1].timer=0
	b.tick(0.01)
	assert(b.enemies[2].hp>100 and b.enemies[1].target=="sol")
	# Set bonuses and upgrades are identical in profile and battle snapshots.
	var p:=Progress.new("user://tactics-%d.json"%Time.get_ticks_usec())
	var one:=RPG.grant_item(p.data.rpg,"ember_sword")
	var two:=RPG.grant_item(p.data.rpg,"ember_mail")
	assert(p.equip_loot(0,one.uid) and p.equip_loot(0,two.uid))
	assert(p.hero_stats(0).set_bonus=="ember" and p.hero_stats(0).damage==31)
	var snapshots:Array=[]
	for i in range(8):snapshots.append(p.hero_stats(i).duplicate(true))
	b.start(1,[0],stage,p.levels(true),p.data.equipment,snapshots)
	assert(b.hero_hp==p.hero_stats(0).hp and b.heroes[0].damage==p.hero_stats(0).damage)
	var before:float=b.heroes[0].damage
	assert(p.unequip_loot(0,"weapon"))
	assert(b.heroes[0].damage==before)
	# Side modes are real battles, including the final tower floor.
	for mode in ["gold","material","tower","challenge"]:
		b.start(5,[0,5,2,3,4],p.activity_stage(mode,30),[20,20,20,20,20,20,20,20])
		for frame in range(24000):
			for slot in range(5):b.skill(slot)
			b.tick(1.0/60)
			if b.state!="playing":break
		assert(b.state=="won",mode+" must be winnable")
	print("PASS: armor/break, burning/Aether combo, Rune/Vera passives, healer/assassin, sets/snapshots and four side modes including tower30")
	quit()
