extends SceneTree
const Progress=preload("res://game/campaign_progress.gd")
const RPG=preload("res://game/rpg_data.gd")
const Party=preload("res://game/party_data.gd")
const BattleModel=preload("res://game/battle.gd")
class FailingProgress extends Progress:
	var fail:=false
	func commit(c:Dictionary)->bool:
		if fail:return false
		return super.commit(c)
func _initialize()->void:
	var folder:="user://rpg-%d"%Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for version in [1,2,3]:
		var path:=folder+"/legacy%d.json"%version
		var p:=Progress.new(path)
		var old:=p.defaults()
		old.version=version
		old.erase("rpg")
		if version<3:old.erase("owned_equipment");old.erase("equipment")
		if version<2:old.erase("hero_levels")
		old.gold=123
		var source:=JSON.stringify(old)
		var file:=FileAccess.open(path,FileAccess.WRITE)
		file.store_string(source);file.close()
		assert(p.load_game() and p.data.gold==123 and p.data.rpg.inventory.is_empty())
		assert(FileAccess.get_file_as_string(path)==source)
		assert(p.set_auto(true))
		assert(FileAccess.get_file_as_string(path+".v%d.bak"%version)==source)
	var p:=FailingProgress.new(folder+"/new.json")
	assert(p.load_game())
	assert(p.begin_activity("gold")==-1)
	for stage in range(1,31):
		var run_id:=p.begin_run(stage)
		assert(run_id>0)
		var receipt:=p.finish_run(run_id,true,10.0,5)
		assert(receipt.ok and receipt.loot.uid>0)
		assert(not p.finish_run(run_id,true,10,5).ok)
	assert(p.unlocked()==30 and p.data.cleared.size()==30 and p.data.rpg.inventory.size()==30)
	assert(p.claim_goal("first") and not p.claim_goal("first"))
	assert(p.claim_weekly() and not p.claim_weekly())
	var count:int=p.data.rpg.inventory.size()
	for i in range(2):
		var id:=p.begin_run(1)
		assert(p.finish_run(id,true,5.0,5).ok)
	assert(p.sweep(1,3).ok and p.data.rpg.inventory.size()==count+5)
	assert(not p.sweep(2,1).ok)
	var uid:=int(p.data.rpg.inventory[0].uid)
	assert(p.equip_loot(0,uid))
	assert(not p.equip_loot(1,uid) and not p.dismantle_loot(uid))
	var before:=p.hero_stats(0)
	p.data.rpg.dust=1000
	p.data.gold=10000
	assert(p.enhance_loot(uid,0) and not p.enhance_loot(uid,0))
	var after:=p.hero_stats(0)
	assert(after.hp>=before.hp and after.damage>=before.damage)
	assert(p.unequip_loot(0,RPG.ITEMS[p.data.rpg.inventory[0].base].slot) and p.dismantle_loot(uid))
	assert(RPG.find_item(p.data.rpg,uid).is_empty())
	p.data.rpg.pity=19
	p.data.rpg.tickets=1
	assert(p.set_wishlist(5))
	var draw:=p.summon(1)
	assert(draw.ok and draw.results[0].hero==5 and draw.results[0].full and p.data.rpg.recruited[5] and p.data.rpg.pity==0)
	assert(p.set_formation([0,5,2,3,4]))
	assert(p.upgrade_hero(5,1).ok and p.hero_level(5)==2)
	assert(p.train_skill(5,1) and not p.train_skill(5,1))
	p.data.rpg.shards[5]=30
	assert(p.ascend(5) and p.data.rpg.ascension[5]==1)
	for mode in ["gold","material","tower","challenge"]:
		var run:=p.begin_activity(mode)
		assert(run>0)
		assert(p.finish_run(run,true,12.0,4).ok)
		assert(not p.finish_run(run,true,12,4).ok)
	assert(p.data.rpg.tower==1)
	assert(p.begin_activity("missing")==-1)
	var saved:=p.data.duplicate(true)
	p.fail=true
	assert(not p.enhance_loot(int(p.data.rpg.inventory[0].uid),0))
	assert(not p.summon(1).ok and not p.train_skill(5,2))
	assert(p.data==saved)
	p.fail=false
	var reload:=Progress.new(p.path)
	assert(reload.load_game() and reload.data==saved)
	var broken:=saved.duplicate(true)
	broken.rpg.inventory[0].base="missing"
	assert(not p.valid(broken))
	broken=saved.duplicate(true)
	broken.rpg.slots[0].weapon=99999
	assert(not p.valid(broken))
	broken=saved.duplicate(true)
	broken.rpg.pity=20
	assert(not p.valid(broken))
	var capped:=Progress.new(folder+"/capped.json")
	for i in range(500): RPG.grant_item(capped.data.rpg,"ember_sword")
	var dust_before:int=capped.data.rpg.dust
	var overflow:=RPG.grant_item(capped.data.rpg,"ember_mail")
	assert(overflow.uid==0 and capped.data.rpg.inventory.size()==500 and capped.data.rpg.dust==dust_before+5)
	assert(capped.commit(capped.data))
	capped.read_only=true
	assert(not capped.equip_loot(0,1) and not capped.summon(1).ok)
	# More advanced chapters require progression; max-level party can finish all30.
	for stage in range(11,31):
		var b:=BattleModel.new()
		var config:=preload("res://game/campaign_data.gd").stage(stage)
		config.tactics=true
		b.start(5,[0,5,2,3,4],config,[20,20,20,20,20,20,20,20])
		for frame in range(24000):
			for slot in range(5):b.skill(slot)
			b.tick(1.0/60)
			if b.state!="playing":break
		assert(b.state=="won","Advanced chapter failed at%d"%stage)
	print("PASS: migrations1/2/3, 30-stage rewards/dedup, goals/weekly, sweep, loot/equip/enhance/dismantle, pity/recruit/train/ascend, modes, save failure/reload/validation and chapters2/3 winnable")
	quit()
