extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func own_children(node: Node, owner: Node) -> void:
	for child in node.get_children():
		child.owner = owner
		own_children(child, owner)
func run() -> void:
	var rig = load("res://game/aether_rig.gd").new()
	rig.name = "AetherRig"
	root.add_child(rig)
	await process_frame
	rig.player.stop()
	own_children(rig, rig)
	var packed := PackedScene.new()
	assert(packed.pack(rig) == OK)
	assert(ResourceSaver.save(packed, "res://scenes/aether_rig.tscn") == OK)
	rig.queue_free()
	await process_frame
	print("PASS: saved editable Skeleton2D / Bone2D / AnimationPlayer scene")
	quit()
