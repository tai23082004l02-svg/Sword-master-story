extends Node2D
## Rigid cutout rig: textures follow real Bone2D hierarchies; no atlas sampling.
var bones: Dictionary = {}
var parts: Dictionary = {}
var player: AnimationPlayer
var skeleton: Skeleton2D
var show_bones := false
var exploded := false
var debug_layer: Node2D

func _ready() -> void:
	if not has_node("Skeleton2D"):
		build()
	skeleton = get_node("Skeleton2D")
	player = get_node("AnimationPlayer")
	collect(skeleton)
	if not has_node("BoneOverlay"):
		debug_layer = Node2D.new()
		debug_layer.name = "BoneOverlay"
		debug_layer.z_index = 100
		add_child(debug_layer)
	else:
		debug_layer = get_node("BoneOverlay")
	if not debug_layer.draw.is_connected(_draw_debug):
		debug_layer.draw.connect(_draw_debug)
	player.play("idle")

func collect(node: Node) -> void:
	if node is Bone2D:
		bones[str(node.name)] = node
	if node is Sprite2D:
		parts[str(node.name)] = node
	for child in node.get_children():
		collect(child)

func bone(label: String, parent: Node2D, pos: Vector2, length: float) -> Bone2D:
	var b := Bone2D.new()
	b.name = label
	b.position = pos
	b.set_autocalculate_length_and_angle(false)
	b.length = length
	b.rest = b.transform
	parent.add_child(b)
	bones[label] = b
	return b

func part(id: String, parent: Bone2D, center: Vector2, dimensions: Vector2, depth: int = 0) -> void:
	var sprite := Sprite2D.new()
	sprite.name = id
	sprite.texture = load("res://assets/aether_rig/parts/%s.png" % id)
	sprite.position = center
	sprite.scale = dimensions / sprite.texture.get_size()
	sprite.z_index = depth
	sprite.set_meta("assembled_position", center)
	parent.add_child(sprite)
	parts[id] = sprite

func build() -> void:
	skeleton = Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	add_child(skeleton)
	var pelvis := bone("Pelvis", skeleton, Vector2(0, -105), 25)
	part("pelvis", pelvis, Vector2(0, 5), Vector2(60, 49), 1)
	var spine := bone("Spine", pelvis, Vector2(0, -25), 53)
	part("torso", spine, Vector2(0, -29), Vector2(65, 80), 2)
	var neck := bone("Neck", spine, Vector2(4, -53), 30)
	part("head", neck, Vector2(7, -26), Vector2(60, 64), 4)
	var hair := bone("Hair", neck, Vector2(-10, -42), 30)
	part("hair_back", hair, Vector2(-10, 17), Vector2(41, 48), 0)
	part("hair_front", neck, Vector2(12, -43), Vector2(45, 35), 5)
	var cape := bone("CapeUpper", spine, Vector2(-21, -47), 37)
	part("cape_upper", cape, Vector2(-12, 21), Vector2(58, 54), -8)
	var middle := bone("CapeMiddle", cape, Vector2(-6, 35), 45)
	part("cape_middle", middle, Vector2(-12, 30), Vector2(69, 68), -8)
	var lower := bone("CapeLower", middle, Vector2(-5, 46), 45)
	part("cape_lower", lower, Vector2(-12, 28), Vector2(72, 69), -8)
	for side in ["back", "front"]:
		var front: bool = side == "front"
		var upper := bone("Arm%s" % side.capitalize(), spine, Vector2(16 if front else -28, -45), 36)
		var forearm := bone("Forearm%s" % side.capitalize(), upper, Vector2(0, 35), 33)
		var hand := bone("Hand%s" % side.capitalize(), forearm, Vector2(0, 33), 14)
		var depth := 6 if front else -3
		part("arm_%s_upper" % side, upper, Vector2(0, 18), Vector2(28, 46), depth)
		part("arm_%s_lower" % side, forearm, Vector2(0, 15), Vector2(26, 39), depth)
		part("hand_%s" % side, hand, Vector2(4, 2), Vector2(26, 20), depth + 1)
		part("pauldron_%s" % side, upper, Vector2(0, 3), Vector2(33, 30), depth + 1 if front else 3)
		var thigh := bone("Thigh%s" % side.capitalize(), pelvis, Vector2(11 if front else -13, 1), 44)
		var shin := bone("Shin%s" % side.capitalize(), thigh, Vector2(0, 44), 43)
		var foot := bone("Foot%s" % side.capitalize(), shin, Vector2(0, 43), 22)
		part("leg_%s_upper" % side, thigh, Vector2(0, 24), Vector2(32, 52), 0 if front else -4)
		part("leg_%s_lower" % side, shin, Vector2(0, 22), Vector2(25, 51), 0 if front else -4)
		part("boot_%s" % side, foot, Vector2(9, 10), Vector2(37, 27), 1 if front else -4)
	var sword := bone("Sword", bones.HandFront, Vector2(11, 2), 130)
	part("sword", sword, Vector2(0, -60), Vector2(47, 146), 6)
	part("belt", pelvis, Vector2(2, 14), Vector2(48, 39), 3)
	player = AnimationPlayer.new()
	player.name = "AnimationPlayer"
	add_child(player)
	var library := AnimationLibrary.new()
	player.add_animation_library("", library)
	for clip in ["idle", "run", "attack", "skill", "hurt", "death"]:
		var animation := Animation.new()
		animation.length = {"idle": 1.6, "run": 0.7, "attack": 0.66, "skill": 0.9, "hurt": 0.4, "death": 0.8}[clip]
		animation.loop_mode = Animation.LOOP_NONE if clip == "death" else Animation.LOOP_LINEAR
		for b in bones.values():
			var angles := [0.0, 0.0, 0.0, 0.0, 0.0]
			match clip:
				"idle":
					if str(b.name).begins_with("Cape") or b.name == &"Hair":
						angles = [-3, 0, 4, 0, -3]
					elif b.name == &"ArmFront": angles = [-9, -11, -9, -7, -9]
					elif b.name == &"Sword": angles = [140, 142, 140, 138, 140]
					elif b.name == &"ThighBack": angles = [10, 10, 10, 10, 10]
					elif b.name == &"ThighFront": angles = [-5, -5, -5, -5, -5]
				"run":
					if b.name in [&"ThighFront", &"ArmBack"]: angles = [-32, 0, 32, 0, -32]
					if b.name in [&"ThighBack", &"ArmFront"]: angles = [32, 0, -32, 0, 32]
					if b.name == &"ShinFront": angles = [8, 48, 12, 0, 8]
					if b.name == &"ShinBack": angles = [12, 0, 8, 48, 12]
					if str(b.name).begins_with("Cape"): angles = [18, 24, 28, 24, 18]
					if b.name == &"Spine": angles = [-8, -10, -8, -6, -8]
				"attack":
					if b.name == &"ArmFront": angles = [-15, -140, -95, -45, -15]
					if b.name == &"ForearmFront": angles = [-10, -35, 35, 15, -10]
					if b.name == &"Sword": angles = [0, -35, 110, 65, 0]
					if b.name == &"Spine": angles = [0, 10, -14, -7, 0]
				"skill":
					if b.name == &"ArmFront": angles = [-10, -155, -170, -80, -10]
					if b.name == &"Sword": angles = [0, 150, 170, 90, 0]
					if str(b.name).begins_with("Cape"): angles = [0, 14, 26, 12, 0]
				"hurt":
					if b.name == &"Spine": angles = [0, 18, 14, 5, 0]
					if b.name == &"Neck": angles = [0, -12, -8, 0, 0]
				"death":
					if b.name == &"Pelvis": angles = [0, 20, 55, 80, 86]
					if b.name == &"ArmFront": angles = [0, 10, 25, 35, 40]
			var track := animation.add_track(Animation.TYPE_VALUE)
			animation.track_set_path(track, NodePath(str(get_path_to(b)) + ":rotation"))
			for i in range(5):
				animation.track_insert_key(track, animation.length * i / 4.0, deg_to_rad(angles[i]))
		var root_track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(root_track, NodePath("Skeleton2D/Pelvis:position"))
		for i in range(5):
			var y: float = -105 + ([0, -4, 0, -4, 0][i] if clip == "run" else [0, -1, -2, -1, 0][i])
			if clip == "death": y = lerpf(-105, -28, i / 4.0)
			animation.track_insert_key(root_track, animation.length * i / 4.0, Vector2(0, y))
		library.add_animation(clip, animation)

func set_clip(clip: String) -> void:
	player.play(clip)
	player.seek(0, true)

func set_exploded(value: bool) -> void:
	exploded = value
	var i := 0
	for sprite in parts.values():
		var base: Vector2 = sprite.get_meta("assembled_position")
		sprite.position = base + Vector2((-1 if i % 2 == 0 else 1) * 24, (i % 3 - 1) * 12) if value else base
		i += 1

func _process(_dt: float) -> void:
	if is_instance_valid(debug_layer):
		debug_layer.queue_redraw()

func _draw_debug() -> void:
	if not show_bones:
		return
	for b in bones.values():
		var origin := to_local(b.global_position)
		debug_layer.draw_circle(origin, 2.5, Color("ffcf68"))
		if b.get_parent() is Bone2D:
			debug_layer.draw_line(to_local(b.get_parent().global_position), origin, Color("76f3e3"), 1.2)
