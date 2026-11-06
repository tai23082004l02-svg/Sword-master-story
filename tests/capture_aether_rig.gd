extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func capture(path: String) -> void:
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path) == OK)
func run() -> void:
	var lab = load("res://scenes/aether_rig_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	lab.rig.player.pause()
	lab.rig.player.seek(0, true)
	await process_frame
	await capture("res://docs/screenshots/aether_rig_idle.png")
	lab.rig.show_bones = true
	await process_frame
	await capture("res://docs/screenshots/aether_rig_bones.png")
	lab.rig.set_clip("attack")
	lab.rig.player.pause()
	lab.rig.player.seek(0.33, true)
	await process_frame
	await capture("res://docs/screenshots/aether_rig_attack.png")
	lab.rig.set_clip("idle")
	lab.rig.player.pause()
	lab.rig.player.seek(0, true)
	lab.rig.set_exploded(true)
	await process_frame
	await capture("res://docs/screenshots/aether_rig_parts.png")
	lab.queue_free()
	await process_frame
	quit()
