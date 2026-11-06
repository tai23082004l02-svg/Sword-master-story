extends SceneTree
## Requires OpenGL/display. Verify actual GPU output, not only shader text.
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	RenderingServer.set_default_clear_color(Color(0.12, 0.16, 0.2, 1))
	for path in ["res://game/hero_art.gd", "res://game/enemy_art.gd", "res://game/boss_art.gd", "brann", "lyra", "nyx", "sol"]:
		var companion: bool = not path.begins_with("res://")
		var sprite = load("res://game/companion_art.gd" if companion else path).new()
		if companion:
			sprite.configure(path)
		sprite.position = Vector2(128, 224)
		root.add_child(sprite)
		sprite.set_process(false)
		for i in range(3):
			await process_frame
		await RenderingServer.frame_post_draw
		var rendered := root.get_texture().get_image()
		var source: Image = (sprite.sheet if companion else sprite.SHEET).get_image()
		var background := rendered.get_pixel(400, 300)
		var checked := 0
		for y in range(256):
			for x in range(256):
				var alpha := source.get_pixel(x, y).a
				if alpha > 0.04 and alpha < 0.075:
					var actual := rendered.get_pixel(x, y)
					assert(absf(actual.r - background.r) < 0.005)
					assert(absf(actual.g - background.g) < 0.005)
					assert(absf(actual.b - background.b) < 0.005)
					checked += 1
		assert(checked > 50)
		sprite.queue_free()
		await process_frame
	print("PASS: low-alpha residue renders fully transparent on all five heroes, enemy and boss sheets")
	quit()
