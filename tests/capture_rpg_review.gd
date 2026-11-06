extends SceneTree
const Progress=preload("res://game/campaign_progress.gd")
func _initialize()->void:call_deferred("run")
func capture(name_value:String)->void:
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://docs/screenshots/"+name_value+".png")==OK)
func run()->void:
	var profile:=Progress.new("user://capture-review-%d.json"%Time.get_ticks_usec())
	for i in range(1,6):
		var id:=profile.begin_run(i)
		assert(profile.finish_run(id,true,10,5).ok)
	profile.data.rpg.tower=29
	assert(profile.commit(profile.data))
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.progress=profile
	root.add_child(scene)
	await process_frame
	for mode in ["tower","challenge"]:
		scene.start_activity(mode)
		scene.battle.state="won"
		scene.battle.elapsed=12
		scene.show_campaign_result()
		assert(scene.receipt.ok)
		await capture("rpg_reward_"+mode)
		scene.to_title()
	scene.audio.stop_all()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	await create_timer(0.15).timeout
	print("PASS: rendered tower and weekly challenge reward UI with separate fixture save")
	quit()
