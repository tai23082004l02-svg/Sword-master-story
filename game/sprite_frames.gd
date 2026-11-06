extends RefCounted
## Explicit texture resources keep every independent PNG available in exports.
const BANKS = {
	"aether": preload("res://assets/frames/aether/frames.tres"),
	"brann": preload("res://assets/frames/brann/frames.tres"),
	"lyra": preload("res://assets/frames/lyra/frames.tres"),
	"nyx": preload("res://assets/frames/nyx/frames.tres"),
	"sol": preload("res://assets/frames/sol/frames.tres"),
	"hollows": preload("res://assets/frames/hollows/frames.tres"),
	"eclipse": preload("res://assets/frames/eclipse/frames.tres")
}
static func texture(id: String, index: int) -> Texture2D:
	return BANKS[id].get_frame_texture("frames", index)
static func offset(id: String, index: int) -> Vector2:
	return BANKS[id].get_meta("draw_offsets")[index]
static func draw_frame(canvas: CanvasItem, id: String, index: int, tint := Color.WHITE) -> void:
	canvas.draw_texture(texture(id, index), offset(id, index), tint)
