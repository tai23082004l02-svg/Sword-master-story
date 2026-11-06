extends Node2D
## Cosmetic state only. The Battle model owns HP, range and damage timing.
const Frames = preload("res://game/sprite_frames.gd")
var ranged := false
var phase := "walk"
var clock := 0.0
var death_time := 0.0
var hurt_time := 0.0
var previous_hp := -1.0
var previous_x := 0.0
var previous_windup := 0.0
var cast_time := 0.0
var target_x := 0.0

func _ready() -> void:
	var cleanup := ShaderMaterial.new()
	cleanup.shader = preload("res://game/shaders/sprite_alpha.gdshader")
	material = cleanup
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func sync(enemy: Dictionary, delta: float, hero_x: float) -> void:
	ranged = enemy.ranged
	target_x = hero_x
	if previous_hp >= 0 and enemy.hp < previous_hp:
		hurt_time = 0.16
	if ranged and previous_windup > 0 and enemy.windup <= 0:
		cast_time = 0.18
	previous_windup = enemy.windup
	previous_hp = enemy.hp
	hurt_time = maxf(0, hurt_time - delta)
	cast_time = maxf(0, cast_time - delta)
	if enemy.hp <= 0:
		phase = "dead"
	elif enemy.windup > 0:
		phase = "attack"
		clock = (0.45 - enemy.windup) / 0.45 * 0.30
	elif enemy.timer > 1.55:
		phase = "attack"
		clock = 0.30 + (1.8 - enemy.timer)
	elif absf(enemy.x - previous_x) > 0.01:
		if phase != "walk":
			clock = 0
		phase = "walk"
		clock += delta
	else:
		phase = "idle"
		clock = 0
	previous_x = enemy.x
	position = Vector2(enemy.x, 500)
	# Sheets face left. Turn toward the hero when the battle crosses positions.
	scale = Vector2(0.72 if hero_x <= enemy.x else -0.72, 0.72)
	queue_redraw()

func fade_death(delta: float) -> bool:
	phase = "dead"
	death_time += delta
	modulate.a = maxf(0, 1.0 - death_time / 0.5)
	rotation = -minf(1.2, death_time * 3)
	queue_redraw()
	return death_time >= 0.5

func _draw() -> void:
	var row := 2 if ranged else 0
	var frame := 0
	if phase == "attack":
		row += 1
		frame = mini(5, int(clock / 0.1))
	elif phase == "walk":
		frame = int(clock / 0.11) % 6
	var tint := Color(1.6, 1.3, 1.3) if hurt_time > 0 else Color.WHITE
	Frames.draw_frame(self, "hollows", row * 6 + frame, tint)
	if phase == "attack" and clock < 0.3:
		draw_arc(Vector2(-5, -68), 65, -2.8, -0.4, 20, Color(0.75, 0.35, 1, 0.8) if ranged else Color(1, 0.5, 0.22, 0.8), 3)
	if ranged and cast_time > 0:
		var local_target := to_local(Vector2(target_x, 420))
		draw_line(Vector2(-50, -100), local_target, Color(0.7, 0.35, 1, cast_time / 0.18), 4)
