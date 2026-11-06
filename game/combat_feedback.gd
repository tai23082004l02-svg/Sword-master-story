extends Node2D
var model: RefCounted
func _draw() -> void:
	if model == null:
		return
	for effect in model.effects:
		draw_string(ThemeDB.fallback_font, Vector2(effect.x - 15, 335 - (0.65 - effect.ttl) * 50), effect.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color("ffe49b") if effect.skill else Color.WHITE)
