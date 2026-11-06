extends SceneTree
## Run with a real display driver, never --headless. Screenshots are actual Godot frames.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.begin()
	for i in range(210):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/moon_ruins_battle.png")
	scene.to_title()
	await process_frame
	scene.show_character()
	for i in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/aether_viewer.png")
	scene.queue_free()
	await create_timer(0.2).timeout
	quit()
