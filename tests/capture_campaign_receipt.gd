extends SceneTree
const Progress = preload("res://game/campaign_progress.gd")
const RPG = preload("res://game/rpg_data.gd")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var p := Progress.new("user://capture-receipt-%d.json" % Time.get_ticks_usec())
	for i in range(500): RPG.grant_item(p.data.rpg, "ember_sword")
	assert(p.commit(p.data))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.progress = p
	root.add_child(scene)
	await process_frame
	scene.start_campaign(1)
	scene.battle.state = "won"
	scene.battle.elapsed = 12
	scene.show_campaign_result()
	assert(scene.receipt.ok and scene.receipt.dust == 7)
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://docs/screenshots/campaign_reward_full_inventory.png") == OK)
	scene.audio.stop_all()
	scene.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("PASS: rendered campaign full-inventory reward from separate fixture save")
	quit()
