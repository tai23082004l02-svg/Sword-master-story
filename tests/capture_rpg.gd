extends SceneTree
const Progress=preload("res://game/campaign_progress.gd")
const RPG=preload("res://game/rpg_data.gd")
func _initialize() -> void:call_deferred("run")
func capture(name_value: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://docs/screenshots/rpg_"+name_value+".png")==OK)
func run() -> void:
	var profile:=Progress.new("user://capture-rpg-%d.json" % Time.get_ticks_usec())
	profile.data.gold=5000
	profile.data.xp=5000
	profile.data.rpg.dust=200
	profile.data.rpg.recruited=[true,true,true,true,true,true,true,true]
	for i in range(8):RPG.grant_item(profile.data.rpg,RPG.ITEMS.keys()[i%RPG.ITEMS.size()])
	assert(profile.commit(profile.data))
	var scene=load("res://scenes/main.tscn").instantiate()
	scene.progress=profile
	root.add_child(scene)
	await capture("lobby")
	for section in ["heroes","inventory","summon","dungeons","goals"]:
		scene.open_rpg(section)
		await capture(section)
	scene.open_stages()
	await capture("stages")
	scene.prepare_stage(1)
	await capture("prepare")
	scene.open_rpg("heroes",5)
	scene.start_trial(5)
	await capture("trial")
	scene.to_title()
	for i in range(1,15):
		var token:=profile.begin_run(i)
		assert(profile.finish_run(token,true,12,5).ok)
	profile.data.hero_levels=[20,20,20,20,20]
	assert(profile.commit(profile.data))
	scene.auto_skills=true
	scene.start_campaign(15)
	for i in range(18000):
		scene._process(1.0/60)
		if scene.battle.boss_wave() and not scene.battle.enemies.is_empty():
			await capture("boss_chapter2")
			break
		if i%120==0:await process_frame
	scene.to_title()
	for voice in scene.audio.voices:voice.stop()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	print("PASS: captured RPG screens, trial and chapter2 boss from Godot OpenGL")
	quit()
