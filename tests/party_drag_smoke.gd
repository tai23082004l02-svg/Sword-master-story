extends SceneTree
const Progress = preload("res://game/campaign_progress.gd")
class FailingProgress extends Progress:
	var fail := false
	func commit(candidate: Dictionary) -> bool:
		if fail:
			last_error = "Simulated storage failure"
			return false
		return super.commit(candidate)
func _initialize() -> void:
	call_deferred("run")
func center(scene: Node, id: int) -> Vector2:
	var panel = scene.campaign_panel
	var driver = panel.get_node("PartyDrag")
	return panel.get_global_transform_with_canvas() * driver.cards[id].get_rect().get_center()
func mouse(point: Vector2, pressed: bool, device: int = 0) -> void:
	var e := InputEventMouseButton.new()
	e.device = device
	e.position = point
	e.global_position = point
	e.button_index = MOUSE_BUTTON_LEFT
	e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	e.pressed = pressed
	root.push_input(e, true)
	await process_frame
func motion(point: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = point
	e.global_position = point
	e.button_mask = MOUSE_BUTTON_MASK_LEFT
	root.push_input(e, true)
	await process_frame
func touch(point: Vector2, pressed: bool, index := 0, canceled := false) -> void:
	var e := InputEventScreenTouch.new()
	e.position = point
	e.index = index
	e.pressed = pressed
	e.canceled = canceled
	root.push_input(e, true)
	await process_frame
func swipe(point: Vector2, index := 0) -> void:
	var e := InputEventScreenDrag.new()
	e.position = point
	e.index = index
	root.push_input(e, true)
	await process_frame
func drag_mouse(scene: Node, source: int, target: int) -> void:
	var from := center(scene, source)
	var to := center(scene, target)
	await mouse(from, true)
	await motion(to)
	assert(scene.campaign_panel.get_node("PartyDrag").dragging)
	await mouse(to, false)
func run() -> void:
	var path := "user://drag-%d/profile.json" % Time.get_ticks_usec()
	var storage := FailingProgress.new(path)
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.progress = storage
	root.add_child(scene)
	await process_frame
	scene.open_stages()
	scene.prepare_stage(1)
	await process_frame
	# Actual mouse press/motion/release; move, don't swap.
	var before: Dictionary = storage.data.duplicate(true)
	await drag_mouse(scene, 1, 4)
	assert(storage.formation() == [0, 2, 3, 4, 1])
	var driver = scene.campaign_panel.get_node("PartyDrag")
	assert(driver.cards[1].position.y > driver.cards[4].position.y or (driver.cards[1].position.y == driver.cards[4].position.y and driver.cards[1].position.x > driver.cards[4].position.x))
	assert(storage.data.gold == before.gold and storage.data.xp == before.xp and storage.data.hero_levels == before.hero_levels)
	# Actual native touch with synthetic mouse events must not remove the hero.
	var from := center(scene, 1)
	var to := center(scene, 2)
	await touch(from, true)
	await mouse(from, true, InputEvent.DEVICE_ID_EMULATION)
	await swipe(to)
	assert(scene.campaign_panel.get_node("PartyDrag").dragging)
	await touch(to, false)
	await mouse(to, false, InputEvent.DEVICE_ID_EMULATION)
	assert(storage.formation() == [0, 1, 2, 3, 4])
	# Dropping on Aether or outside cancels. Moving Aether is also prohibited.
	before = storage.data.duplicate(true)
	await drag_mouse(scene, 1, 0)
	assert(storage.data == before)
	from = center(scene, 1)
	await mouse(from, true)
	await motion(Vector2(1250, 510))
	await mouse(Vector2(1250, 510), false)
	assert(storage.data == before)
	await mouse(center(scene, 0), true)
	await motion(center(scene, 4))
	await mouse(center(scene, 4), false)
	assert(storage.data == before)
	# Short tap toggles once; reserve movement is not mistaken for an add.
	await touch(center(scene, 3), true)
	await touch(center(scene, 3) + Vector2(2, 2), false)
	assert(storage.formation() == [0, 1, 2, 4])
	from = center(scene, 3)
	to = center(scene, 1)
	await touch(from, true)
	await swipe(to)
	await touch(to, false)
	assert(storage.formation() == [0, 1, 2, 4])
	await touch(center(scene, 3), true)
	await touch(center(scene, 3), false)
	assert(storage.formation() == [0, 1, 2, 4, 3])
	# Focus loss and Android's canceled touch don't save or toggle.
	before = storage.data.duplicate(true)
	from = center(scene, 1)
	to = center(scene, 3)
	await touch(from, true)
	await swipe(to)
	scene.campaign_panel.get_node("PartyDrag")._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	await touch(to, false)
	assert(storage.data == before)
	await touch(from, true)
	await touch(from, false, 0, true)
	assert(storage.data == before)
	# Second finger cannot start a battle while the first finger is dragging.
	from = center(scene, 1)
	to = center(scene, 3)
	await touch(from, true)
	await swipe(to)
	await touch(Vector2(1100, 620), true, 1)
	await touch(Vector2(1100, 620), false, 1)
	assert(scene.screen == "prepare" and storage.data == before)
	await touch(to, false)
	assert(storage.formation() == [0, 2, 4, 3, 1])
	# Transforming the UI exercises viewport->local conversion used by stretch.
	scene.ui.get_parent().transform = Transform2D(Vector2(0.8, 0), Vector2(0, 0.8), Vector2(35, 20))
	await process_frame
	await drag_mouse(scene, 1, 2)
	assert(storage.formation() == [0, 1, 2, 4, 3])
	# Failed persistence leaves both data and visual order intact and ends drag.
	before = storage.data.duplicate(true)
	storage.fail = true
	await drag_mouse(scene, 1, 3)
	assert(storage.data == before)
	driver = scene.campaign_panel.get_node("PartyDrag")
	assert(not driver.dragging and driver.preview == null and driver.cards[1].modulate.a == 1)
	assert(driver.cards[1].position.x < driver.cards[2].position.x)
	storage.fail = false
	var reloaded := Progress.new(path)
	assert(reloaded.load_game() and reloaded.formation() == storage.formation())
	scene.start_campaign(1)
	await process_frame
	assert(scene.battle.heroes[1].id == "brann" and scene.battle.heroes[4].id == "nyx")
	for voice in scene.audio.voices: voice.stop()
	await create_timer(0.15).timeout
	scene.queue_free()
	await process_frame
	print("PASS: actual mouse/touch drag, synthetic mouse dedup, insert order, pinned leader, invalid drop, taps/reserve, cancel/focus, multi-touch, scaled canvas, save failure/reload and battle roster")
	quit()
