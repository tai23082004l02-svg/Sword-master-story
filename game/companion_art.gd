extends "res://game/hero_art.gd"
## Presentation only. All damage, shields and healing remain owned by Battle.
var actor_id := ""
var actor: Dictionary = {}
var last_hp := -1.0
var last_x := 0.0
var hurt_left := 0.0
var initialized := false

func configure(id: String) -> void:
	sword_overlays = false
	actor_id = id
	character_id = {"iris":"nyx","rune":"brann","vera":"sol"}.get(id,id)
	modulate = Color("b5e2ff") if id == "iris" else (Color("ffc5da") if id == "rune" else (Color("bcf8bc") if id == "vera" else Color.WHITE))
	frame_override = -1
	initialized = false
	hurt_left = 0
	set_clip("idle", true)

func _process(dt: float) -> void:
	if preview:
		super._process(dt)
	else:
		queue_redraw()

func sync(data: Dictionary, dt: float, paused: bool, finished: bool = false) -> void:
	if actor_id != data.id or actor != data:
		configure(data.id)
	frame_override = -1
	actor = data
	preview = false
	frozen = paused
	if not initialized:
		last_hp = actor.hp
		last_x = actor.x
		initialized = true
	if paused:
		return
	clock += dt
	hurt_left = maxf(0, hurt_left - dt)
	if actor.hp < last_hp:
		hurt_left = 0.2
	if actor.hp <= 0:
		set_clip("death")
	elif finished:
		set_clip("idle")
	elif actor.visual > 0:
		set_clip("skill")
		clock = 0.48 - actor.visual
	elif hurt_left > 0:
		set_clip("hurt")
	elif actor.windup > 0 or actor.timer > 0.04:
		set_clip("attack")
		# Map preparation and recovery to the same six animation frames as Aether.
		clock = (0.18 - actor.windup) if actor.windup > 0 else 0.18 + (actor.recovery - actor.timer) * 0.18 / actor.recovery
	elif absf(actor.x - last_x) > 0.01:
		set_clip("run")
	else:
		set_clip("idle")
	last_hp = actor.hp
	last_x = actor.x

func _draw() -> void:
	super._draw()
	# Atlas artwork carries each spell; retain the persistent shield indicator.
	if not preview and not actor.is_empty() and actor.hp > 0 and actor.shield > 0:
		draw_arc(Vector2(0, -90), 100, -1.8, 1.8, 40, Color(0.95, 0.75, 0.35, 0.65), 3)
