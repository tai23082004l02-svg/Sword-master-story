extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var rig = load("res://scenes/aether_rig.tscn").instantiate()
	root.add_child(rig)
	await process_frame
	assert(rig.skeleton is Skeleton2D and rig.player is AnimationPlayer)
	assert(rig.parts.size() == 24 and rig.bones.size() == 20)
	for p in rig.parts.values():
		assert(p.get_parent() is Bone2D)
		assert(p.texture.resource_path.begins_with("res://assets/aether_rig/parts/"))
		var image: Image = p.texture.get_image()
		assert(image.get_used_rect().has_area())
		assert(p.owner == rig, "Parts must be editable in packed scene")
	for b in rig.bones.values():
		assert(b.owner == rig and b.rest.is_finite())
	for clip in ["idle", "run", "attack", "skill", "hurt", "death"]:
		assert(rig.player.has_animation(clip))
		rig.set_clip(clip)
		rig.player.pause()
		for t in [0.0, 0.25, 0.5, 0.75, 1.0]:
			rig.player.seek(rig.player.get_animation(clip).length * t, true)
			for b in rig.bones.values():
				assert(b.global_transform.is_finite())
	rig.set_clip("run")
	rig.player.pause()
	rig.player.seek(0, true)
	var before: Transform2D = rig.parts.boot_front.global_transform
	rig.player.seek(0.35, true)
	assert(rig.parts.boot_front.global_transform != before, "Actual bone hierarchy must move attached pixels")
	var at_pause: Transform2D = rig.parts.sword.global_transform
	await create_timer(0.05).timeout
	assert(rig.parts.sword.global_transform == at_pause)
	var positions: Dictionary = {}
	for id in rig.parts: positions[id] = rig.parts[id].position
	rig.set_exploded(true)
	assert(rig.parts.torso.position != positions.torso)
	rig.set_exploded(false)
	for id in rig.parts: assert(rig.parts[id].position == positions[id])
	rig.queue_free()
	await process_frame
	var lab = load("res://scenes/aether_rig_lab.tscn").instantiate()
	root.add_child(lab)
	await process_frame
	assert(lab.rig.parts.size() == 24)
	assert(lab.rig.z_index > 8, "Back layers must remain above lab background")
	lab.queue_free()
	await process_frame
	print("PASS: 24 independent textures, 20 editable bones, six clips, attached motion, pause, explode/reassemble and lab")
	quit()
