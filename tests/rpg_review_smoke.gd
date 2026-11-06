extends SceneTree
const Progress=preload("res://game/campaign_progress.gd")
const RPG=preload("res://game/rpg_data.gd")
class FailingProgress extends Progress:
	var fail:=false
	func commit(candidate:Dictionary)->bool:
		if fail:
			last_error="Giả lập lỗi lưu: chưa thay đổi tiến trình."
			return false
		return super.commit(candidate)
func _initialize()->void:call_deferred("run")
func find_button(node:Node,prefix:String)->Button:
	for child in node.get_children():
		if child is Button and child.text.begins_with(prefix):return child
		var found:=find_button(child,prefix)
		if found!=null:return found
	return null
func labels(node:Node)->String:
	var output:=""
	for child in node.get_children():
		if child is Label:output+=child.text+"\n"
		output+=labels(child)
	return output
func run()->void:
	var p:=FailingProgress.new("user://review-%d.json"%Time.get_ticks_usec())
	for i in range(1,6):
		var id:=p.begin_run(i)
		assert(p.finish_run(id,true,10,5).ok)
	var token:=p.begin_activity("challenge")
	assert(p.data.pending.rotation_week==RPG.week_now())
	# Simulate a persisted battle started in the preceding rotation.
	var candidate:=p.data.duplicate(true)
	candidate.pending.rotation_week=RPG.week_now()-1
	assert(p.commit(candidate))
	var persisted:=Progress.new(p.path)
	assert(persisted.load_game() and persisted.data.pending.rotation_week==RPG.week_now()-1)
	var rotation:int=p.data.pending.rotation_week
	var config:=p.activity_stage("challenge")
	var kinds:=[ ["healer","armored","ranged"],["assassin","assassin","melee"],["armored","healer","healer"] ]
	assert(config.waves[0].enemies==kinds[rotation%3])
	var hero:=rotation%8
	var before:int=p.data.rpg.shards[hero]
	var result:=p.finish_run(token,true,10,5)
	assert(result.ok and result.shards==5 and result.shard_hero==hero and p.data.rpg.shards[hero]==before+5)
	assert(result.dust==3 and result.sweep_tokens==1)
	assert(not p.finish_run(token,true,10,5).ok)
	# Optional rotation metadata is validated; older pending saves remain accepted.
	candidate=p.data.duplicate(true)
	candidate.serial+=1
	candidate.pending={"id":candidate.serial,"stage":1,"mode":"challenge","floor":1,"rotation_week":"bad"}
	assert(not p.valid(candidate))
	candidate.pending.erase("rotation_week")
	assert(p.valid(candidate))
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.progress=p
	root.add_child(scene)
	await process_frame
	scene.start_campaign(1)
	await process_frame
	scene.toggle_pause()
	var snapshot:=p.data.duplicate(true)
	p.fail=true
	scene.to_title()
	assert(scene.screen=="paused" and scene.campaign_active and p.data==snapshot)
	assert(p.last_error in labels(scene.menu))
	scene.open_stages()
	assert(scene.screen=="paused" and scene.campaign_active and p.data==snapshot)
	scene.open_rpg("goals")
	assert(scene.screen=="paused" and scene.campaign_active and p.data==snapshot)
	var previous:bool=scene.auto_skills
	scene.set_auto_mode(not previous)
	assert(scene.auto_skills==previous and p.data.auto_skills==previous)
	scene.resume()
	scene.set_auto_mode(not previous)
	scene._process(0)
	assert(scene.auto_skills==previous and p.last_error in scene.status.text)
	p.fail=false
	scene.to_title()
	assert(scene.screen=="title" and p.data.pending.is_empty())
	# Final tower reward is fully shown and no unusable next-floor button remains.
	p.data.rpg.tower=29
	assert(p.commit(p.data))
	scene.start_activity("tower")
	scene.battle.state="won"
	scene.battle.elapsed=10
	scene.show_campaign_result()
	await process_frame
	assert(scene.receipt.ok and scene.receipt.gems==50 and p.data.rpg.tower==30)
	assert("50 tinh thạch" in labels(scene.campaign_panel))
	assert("3 bụi" in labels(scene.campaign_panel))
	assert(find_button(scene.campaign_panel,"Đã hoàn thành tháp").disabled)
	scene.to_title()
	scene.start_activity("material")
	scene.battle.state="won"
	scene.battle.elapsed=10
	scene.show_campaign_result()
	assert(scene.receipt.dust==15 and "15 bụi" in labels(scene.campaign_panel))
	scene.to_title()
	scene.audio.stop_all()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("PASS: weekly rotation/reward snapshot, old pending compatibility/validation, failed-save navigation/auto rollback, complete activity rewards and final tower UI")
	quit()
