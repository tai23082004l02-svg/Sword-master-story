extends SceneTree
const Progress=preload("res://game/campaign_progress.gd")
func _initialize()->void:call_deferred("run")
func find_button(node:Node,prefix:String)->Button:
	for child in node.get_children():
		if child is Button and child.text.begins_with(prefix):return child
		var found:=find_button(child,prefix)
		if found!=null:return found
	return null
func run()->void:
	var p:=Progress.new("user://rpg-scene-%d.json"%Time.get_ticks_usec())
	p.data.gold=10000
	p.data.xp=10000
	p.data.rpg.dust=1000
	for i in range(1,6):
		var id:=p.begin_run(i)
		assert(p.finish_run(id,true,1,5).ok)
	for hero in range(5):assert(p.upgrade_hero(hero,1).ok)
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.progress=p
	root.add_child(scene)
	await process_frame
	assert(scene.screen=="title" and find_button(scene.campaign_panel,"Túi đồ")!=null)
	find_button(scene.campaign_panel,"Túi đồ").pressed.emit()
	await process_frame
	assert(scene.screen=="rpg" and scene.rpg_section=="inventory")
	find_button(scene.campaign_panel,"Mặc").pressed.emit()
	await process_frame
	assert(p.item_user(int(p.data.rpg.inventory[0].uid))==0)
	find_button(scene.campaign_panel,"+").pressed.emit()
	await process_frame
	assert(p.data.rpg.inventory[0].rank==1)
	find_button(scene.campaign_panel,"Tháo").pressed.emit()
	await process_frame
	assert(p.item_user(int(p.data.rpg.inventory[0].uid))==-1)
	scene.open_rpg("heroes",5)
	await process_frame
	assert(not p.data.rpg.recruited[5])
	scene.start_trial(5)
	await process_frame
	assert(scene.screen=="battle" and not scene.campaign_active and scene.battle.heroes[1].id=="iris")
	assert(scene.companion_views[0].character_id=="nyx")
	scene.begin()
	assert(scene.battle.heroes[1].id=="iris")
	scene.to_title()
	scene.open_rpg("summon")
	p.data.rpg.pity=19
	assert(p.set_wishlist(5))
	scene.rpg_summon(1)
	await process_frame
	assert(p.data.rpg.recruited[5])
	for child in scene.ui.get_children():
		if child is AcceptDialog:child.hide()
	await process_frame
	scene.open_rpg("heroes",5)
	find_button(scene.campaign_panel,"Nâng 1 cấp").pressed.emit()
	await process_frame
	assert(p.hero_level(5)==2)
	scene.prepare_stage(6)
	scene.select_companion(1)
	scene.select_companion(5)
	await process_frame
	assert(p.formation()==[0,2,3,4,5])
	scene.auto_skills=true
	scene.open_rpg("dungeons")
	scene.start_activity("gold")
	await process_frame
	assert(scene.activity_mode=="gold" and scene.battle.heroes[4].id=="iris")
	for i in range(24000):
		scene._process(1.0/60)
		if scene.screen=="result":break
	assert(scene.screen=="result" and scene.receipt.ok and scene.receipt.won)
	assert(scene.receipt.mode=="gold" and find_button(scene.campaign_panel,"Đánh tiếp")!=null)
	scene.open_rpg("goals")
	assert(find_button(scene.campaign_panel,"Nhận")!=null)
	scene.rpg_goal("first")
	assert("first" in p.data.rpg.goals)
	scene.open_rpg("stats")
	await process_frame
	assert(scene.rpg_section=="stats")
	scene.to_title()
	for voice in scene.audio.voices:voice.stop()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("PASS: lobby navigation, inventory equip/enhance/unequip, locked-hero trial, pity unlock, recruited-hero growth/formation, activity battle/reward, goals and local stats")
	quit()
