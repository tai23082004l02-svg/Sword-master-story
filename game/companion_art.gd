extends "res://game/hero_art.gd"
## Presentation only. All damage, shields and healing remain owned by Battle.
const SHEETS = {
	"brann": preload("res://assets/party/brann_sheet.png"),
	"lyra": preload("res://assets/party/lyra_sheet.png"),
	"nyx": preload("res://assets/party/nyx_sheet.png"),
	"sol": preload("res://assets/party/sol_sheet.png")
}
var actor: Dictionary = {}
var character_id := "brann"
var last_hp := -1.0
var last_x := 0.0
var hurt_left := 0.0
var initialized := false

func configure(id: String) -> void:
	sword_overlays = false
	character_id = id
	sheet = SHEETS[id]
	frame_regions = {}
	if id == "lyra":
		# Generated skill poses are spaced slightly closer than the regular grid.
		# Explicit regions exclude the next pose while preserving the full bow.
		frame_regions = {18: Rect2(0, 768, 232, 256), 19: Rect2(236, 768, 212, 256), 20: Rect2(450, 768, 318, 256)}
	initialized = false
	hurt_left = 0
	set_clip("idle", true)

func _process(dt: float) -> void:
	if preview:
		super._process(dt)
	else:
		queue_redraw()

func sync(data: Dictionary, dt: float, paused: bool, finished: bool = false) -> void:
	if character_id != data.id or actor != data:
		configure(data.id)
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
		# Map preparation and recovery to the same six atlas frames as Aether.
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
