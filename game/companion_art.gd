extends Node2D
## Original geometric placeholders, intentionally distinct from Aether's finished sprite.
var actor: Dictionary = {}
var frozen := false
var clock := 0.0
func _process(dt: float) -> void:
	if not frozen:
		clock += dt
	queue_redraw()
func _draw() -> void:
	if actor.is_empty():
		return
	var tint := Color(actor.color)
	var dead: bool = actor.hp <= 0
	modulate.a = 0.25 if dead else 1.0
	var bob := sin(clock * 4) * 2
	var body := PackedVector2Array([Vector2(-20, -55), Vector2(-28, -8), Vector2(24, -8), Vector2(16, -55)])
	draw_colored_polygon(body, tint.darkened(0.55))
	draw_circle(Vector2(0, -70 + bob), 13, tint.lightened(0.2))
	draw_line(Vector2(-9, -8), Vector2(-13, 0), tint, 5)
	draw_line(Vector2(10, -8), Vector2(15, 0), tint, 5)
	var reach := 12.0 if actor.windup > 0 or actor.visual > 0 else 0.0
	match actor.id:
		"brann":
			draw_rect(Rect2(12 + reach, -54, 24, 39), tint)
			draw_line(Vector2(24 + reach, -48), Vector2(24 + reach, -22), Color.WHITE, 2)
		"lyra":
			draw_arc(Vector2(20 + reach, -42), 24, -1.4, 1.4, 20, tint, 3)
			draw_line(Vector2(24 + reach, -65), Vector2(24 + reach, -19), tint, 1)
		"nyx", "sol":
			draw_line(Vector2(22, -7), Vector2(25 + reach, -76), tint, 4)
			draw_circle(Vector2(25 + reach, -80), 8, tint)
	if actor.visual > 0:
		draw_arc(Vector2(0, -40), 48, 0, TAU, 36, Color(tint, 0.8), 3)
	if actor.shield > 0 and not dead:
		draw_arc(Vector2(0, -40), 42, -1.8, 1.8, 24, Color("e5b76d"), 2)
	draw_rect(Rect2(-28, -104, 56, 5), Color("492e3b"))
	draw_rect(Rect2(-28, -104, 56 * maxf(0, actor.hp / actor.max_hp), 5), tint)
	draw_string(ThemeDB.fallback_font, Vector2(-28, -112), actor.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, tint)
