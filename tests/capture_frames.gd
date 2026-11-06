extends SceneTree
const Frames = preload("res://game/sprite_frames.gd")
class Audit extends Node2D:
	var character := "aether"
	func _draw() -> void:
		for i in range(24):
			draw_set_transform(Vector2(i % 6 * 208 + 104, i / 6 * 172 + 146), 0, Vector2(0.5, 0.5))
			Frames.draw_frame(self, character, i)
			draw_set_transform(Vector2.ZERO)
			draw_string(ThemeDB.fallback_font, Vector2(i % 6 * 208 + 10, i / 6 * 172 + 164), "%s · %02d" % [character, i], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color.WHITE)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	RenderingServer.set_default_clear_color(Color("152a38"))
	var audit := Audit.new()
	var shader := ShaderMaterial.new()
	shader.shader = preload("res://game/shaders/sprite_alpha.gdshader")
	audit.material = shader
	root.add_child(audit)
	for id in Frames.BANKS:
		audit.character = id
		audit.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://docs/screenshots/frames_%s.png" % id) == OK)
	audit.queue_free()
	await process_frame
	quit()
