extends Node2D
const Frames = preload("res://game/sprite_frames.gd")
var clock := 0.0
var phase := "idle"
var attack_kind := "slash"
var empowered := false
var flash := 0.0
var impact := 0.0
var hurt := 0.0
var previous_hp := -1.0
var previous_x := 0.0
var death_time := 0.0

func _ready() -> void:
	var cleanup := ShaderMaterial.new()
	cleanup.shader = preload("res://game/shaders/sprite_alpha.gdshader")
	material = cleanup
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func sync(enemy: Dictionary, delta: float, hero_x: float) -> void:
	empowered = enemy.phase == 2
	flash = enemy.phase_flash
	impact = enemy.impact
	attack_kind = enemy.attack_kind
	hurt = maxf(0, hurt - delta)
	if previous_hp >= 0 and enemy.hp < previous_hp:
		hurt = 0.12
	previous_hp = enemy.hp
	if enemy.windup > 0:
		phase = "attack"
		clock = (1.0 - enemy.windup / enemy.windup_total) * 0.3
	elif enemy.impact > 0:
		phase = "attack"
		clock = 0.3 + (0.25 - enemy.impact)
	elif absf(enemy.x - previous_x) > 0.01:
		phase = "walk"
		clock += delta
	else:
		phase = "idle"
		clock = 0
	previous_x = enemy.x
	position = Vector2(enemy.x, 490)
	scale = Vector2(1.05 if hero_x <= enemy.x else -1.05, 1.05)
	queue_redraw()

func fade_death(delta: float) -> bool:
	phase = "dead"
	death_time += delta
	modulate.a = 1.0 if death_time < 0.5 else maxf(0, (0.8 - death_time) / 0.3)
	queue_redraw()
	return death_time >= 0.8

func _draw() -> void:
	var frame := 0
	if phase == "dead":
		frame = 21 + mini(2, int(death_time / 0.2))
	elif flash > 0:
		frame = 18 + int((0.75 - flash) / 0.2) % 2
	elif phase == "attack":
		frame = (6 if attack_kind == "slash" else 12) + mini(5, int(clock / 0.1))
	elif hurt > 0:
		frame = 20
	elif phase == "walk":
		frame = int(clock / 0.13) % 6
	if empowered and phase != "dead":
		draw_arc(Vector2(0, -82), 100, 0, TAU, 48, Color(0.6, 0.25, 0.9, 0.35), 3)
	var tint := Color(1.15, 0.85, 1.2) if empowered else Color.WHITE
	Frames.draw_frame(self, "eclipse", frame, tint)
	if phase == "attack" and clock < 0.3:
		draw_arc(Vector2(-25, -90), 70 + clock * 40, -2.8, -0.6, 24, Color(0.9, 0.4, 1, 0.75), 4)
	if impact > 0 and phase != "dead":
		var alpha := impact / 0.25
		if attack_kind == "wave":
			draw_arc(Vector2(-70 - (0.25 - impact) * 600, -75), 68, 1.8, 4.5, 24, Color(0.8, 0.4, 1, alpha), 9)
		elif attack_kind == "heavy":
			draw_line(Vector2(-90, -185), Vector2(-90, 5), Color(0.8, 0.4, 1, alpha), 12)
