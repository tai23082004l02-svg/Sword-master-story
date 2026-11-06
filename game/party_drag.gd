extends Node
## One pointer owns a gesture. Native touch and mouse share logical UI coordinates.
const NONE := -2
const MOUSE := -1
const DRAG_DISTANCE := 16.0
var panel: Control
var host
var cards: Dictionary = {}
var roster: Array[int] = []
var styles: Dictionary = {}
var pointer := NONE
var source := -1
var press_position := Vector2.ZERO
var grab_offset := Vector2.ZERO
var moved := false
var dragging := false
var preview: Button
var original_modulate := Color.WHITE

func configure(owner_panel: Control, controller, widgets: Dictionary, selected: Array[int]) -> void:
	panel = owner_panel
	host = controller
	cards = widgets
	roster = selected.duplicate()
	for id in cards:
		styles[id] = {"normal": cards[id].get_theme_stylebox("normal"), "hover": cards[id].get_theme_stylebox("hover")}

func local_position(point: Vector2) -> Vector2:
	return panel.get_global_transform_with_canvas().affine_inverse() * point

func _input(event: InputEvent) -> void:
	if not is_instance_valid(panel) or not panel.is_visible_in_tree() or host.screen != "prepare": return
	if event is InputEventKey and pointer != NONE:
		if event.pressed and event.keycode == KEY_ESCAPE: cancel()
		get_viewport().set_input_as_handled()
		return
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		# Card buttons ignore mouse presses themselves; avoid a second tap from
		# Android's synthesized mouse, while still allowing other UI buttons.
		if pointer != NONE: get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenTouch:
		if pointer != NONE and pointer != event.index:
			get_viewport().set_input_as_handled()
			return
		if event.pressed:
			begin_pointer(event.index, local_position(event.position))
		elif pointer == event.index:
			finish_pointer(local_position(event.position), event.canceled)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if pointer != NONE:
			if event.index == pointer: move_pointer(local_position(event.position))
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if pointer >= 0:
			get_viewport().set_input_as_handled()
			return
		if event.pressed: begin_pointer(MOUSE, local_position(event.position))
		elif pointer == MOUSE:
			finish_pointer(local_position(event.position))
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and pointer != NONE:
		if pointer == MOUSE: move_pointer(local_position(event.position))
		get_viewport().set_input_as_handled()

func begin_pointer(id: int, point: Vector2) -> void:
	if pointer != NONE or host.progress.read_only: return
	for hero in cards:
		var card: Button = cards[hero]
		if not card.get_rect().has_point(point): continue
		get_viewport().set_input_as_handled()
		if hero == 0: return
		pointer = id
		source = hero
		press_position = point
		grab_offset = point - card.position
		original_modulate = card.modulate
		moved = false
		dragging = false
		return

func target_at(point: Vector2) -> int:
	if cards[0].get_rect().has_point(point): return -1
	var nearest := -1
	var distance := INF
	for id in roster:
		if id == 0 or id == source: continue
		var card: Button = cards[id]
		if not card.get_rect().grow(12).has_point(point): continue
		var d := point.distance_squared_to(card.get_rect().get_center())
		if d < distance:
			nearest = id
			distance = d
	return nearest

func move_pointer(point: Vector2) -> void:
	if pointer == NONE: return
	if point.distance_to(press_position) >= DRAG_DISTANCE: moved = true
	if not moved or not source in roster: return
	if not dragging:
		dragging = true
		var card: Button = cards[source]
		preview = Button.new()
		preview.text = card.text
		preview.size = card.size
		preview.disabled = true
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.focus_mode = Control.FOCUS_NONE
		preview.z_index = 20
		preview.add_theme_font_size_override("font_size", 20)
		preview.add_theme_color_override("font_disabled_color", Color("f0e5c9"))
		var preview_style: StyleBoxFlat = styles[source].normal.duplicate()
		preview_style.bg_color = Color("193846")
		preview.add_theme_stylebox_override("disabled", preview_style)
		panel.add_child(preview)
		card.modulate.a = 0.35
	preview.position = point - grab_offset + Vector2(0, -18)
	highlight(target_at(point))

func highlight(target: int) -> void:
	for id in cards:
		if not is_instance_valid(cards[id]): continue
		cards[id].add_theme_stylebox_override("normal", styles[id].normal)
		cards[id].add_theme_stylebox_override("hover", styles[id].hover)
	if target < 1: return
	var accent: StyleBoxFlat = styles[target].normal.duplicate()
	accent.border_color = Color("ffe0a0")
	accent.set_border_width_all(3)
	cards[target].add_theme_stylebox_override("normal", accent)
	cards[target].add_theme_stylebox_override("hover", accent)

func finish_pointer(point: Vector2, canceled := false) -> void:
	if not canceled: move_pointer(point)
	var hero := source
	var drop := target_at(point) if dragging else -1
	var tap := not moved and not canceled
	var reorder := dragging and drop > 0 and not canceled
	cancel()
	if reorder: host.reorder_companion(hero, drop)
	elif tap: host.select_companion(hero)

func cancel() -> void:
	if source >= 0 and cards.has(source) and is_instance_valid(cards[source]):
		cards[source].modulate = original_modulate
	highlight(-1)
	if is_instance_valid(preview):
		preview.visible = false
		preview.queue_free()
	preview = null
	pointer = NONE
	source = -1
	moved = false
	dragging = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: cancel()

func _exit_tree() -> void:
	cancel()
