extends SceneTree
## Deterministic extraction of an already-generated, disjoint parts kit.
const NAMES = ["torso", "pelvis", "head", "hair_back", "hair_front", "cape_upper", "cape_middle", "cape_lower", "arm_front_upper", "arm_front_lower", "hand_front", "arm_back_upper", "arm_back_lower", "hand_back", "leg_front_upper", "leg_front_lower", "boot_front", "leg_back_upper", "leg_back_lower", "boot_back", "sword", "pauldron_front", "pauldron_back", "belt"]
func _initialize() -> void:
	var source := Image.load_from_file("res://assets/aether_rig/source_parts.png")
	assert(source.get_size() == Vector2i(1536, 1024))
	var records: Array = []
	for i in range(NAMES.size()):
		var region := Rect2i((i % 6) * 256, (i / 6) * 256, 256, 256)
		var part := source.get_region(region)
		for y in range(256):
			for x in range(256):
				var pixel := part.get_pixel(x, y)
				pixel.a *= smoothstep(0.08, 0.20, pixel.a)
				if pixel.a < 0.02:
					pixel = Color.TRANSPARENT
				part.set_pixel(x, y, pixel)
		var bounds := part.get_used_rect()
		assert(bounds.has_area())
		var cropped := part.get_region(bounds)
		var path := "res://assets/aether_rig/parts/%s.png" % NAMES[i]
		assert(cropped.save_png(path) == OK)
		records.append({"id": NAMES[i], "file": "parts/%s.png" % NAMES[i], "source_rect": [region.position.x + bounds.position.x, region.position.y + bounds.position.y, bounds.size.x, bounds.size.y]})
	var manifest := {"character": "Aether", "source": "Original parts kit generated with OpenAI image generation, 2026-11-06; existing Aether used only as design reference", "third_party_assets": false, "processing": "Godot Image region extraction, existing alpha-residue curve baked once, trim transparent borders; no repaint", "parts": records, "status": "skeletal cutout prototype; pending device and visual approval"}
	var file := FileAccess.open("res://assets/aether_rig/manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	print("PASS: extracted 24 independent Aether parts")
	quit()
