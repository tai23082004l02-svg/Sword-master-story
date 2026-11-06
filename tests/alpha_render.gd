extends SceneTree
## Real GPU guard test for independent frames, including their actual draw offsets.
const Frames = preload("res://game/sprite_frames.gd")
class Probe extends Node2D:
	var character := "aether"
	var index := 0
	func _draw() -> void:
		Frames.draw_frame(self, character, index)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	RenderingServer.set_default_clear_color(Color(0.12, 0.16, 0.2, 1))
	var probe := Probe.new()
	probe.position = Vector2(256, 272)
	var cleanup := ShaderMaterial.new()
	cleanup.shader = preload("res://game/shaders/sprite_alpha.gdshader")
	probe.material = cleanup
	root.add_child(probe)
	for id in Frames.BANKS:
		for index in range(24):
			probe.character = id
			probe.index = index
			probe.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			var rendered := root.get_texture().get_image()
			var background := rendered.get_pixel(1200, 700)
			var texture := Frames.texture(id, index)
			var base := Vector2i(probe.position + Frames.offset(id, index))
			var width := texture.get_width()
			var height := texture.get_height()
			for point in [Vector2i(2, 2), Vector2i(width - 3, 2), Vector2i(2, height - 3), Vector2i(width - 3, height - 3), Vector2i(width / 2, 2), Vector2i(width / 2, height - 3), Vector2i(2, height / 2), Vector2i(width - 3, height / 2)]:
				var pixel := rendered.get_pixelv(base + point)
				assert(absf(pixel.r - background.r) < 0.005 and absf(pixel.g - background.g) < 0.005 and absf(pixel.b - background.b) < 0.005)
	probe.queue_free()
	await process_frame
	print("PASS: 168 rendered standalone frames have transparent edges; no neighboring texture bleed")
	quit()
