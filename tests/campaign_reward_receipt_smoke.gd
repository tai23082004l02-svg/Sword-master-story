extends SceneTree
const Progress = preload("res://game/campaign_progress.gd")
const RPG = preload("res://game/rpg_data.gd")
class FailingProgress extends Progress:
	var fail := false
	func commit(candidate: Dictionary) -> bool:
		if fail:
			last_error = "Giả lập lỗi ghi"
			return false
		return super.commit(candidate)
func _initialize() -> void: call_deferred("run")
func labels(node: Node) -> String:
	var output := ""
	for child in node.get_children():
		if child is Label: output += child.text + "\n"
		output += labels(child)
	return output
func run() -> void:
	var p := FailingProgress.new("user://receipt-%d.json" % Time.get_ticks_usec())
	var token := p.begin_run(1)
	var dust: int = p.data.rpg.dust
	var tickets: int = p.data.rpg.sweep_tokens
	var receipt := p.finish_run(token, true, 10, 5)
	assert(receipt.ok and receipt.dust == p.data.rpg.dust-dust and receipt.dust == 2)
	assert(receipt.sweep_tokens == p.data.rpg.sweep_tokens-tickets and receipt.sweep_tokens == 1)
	# A full inventory must report every awarded dust, without granting twice on retry.
	while p.data.rpg.inventory.size() < 500: RPG.grant_item(p.data.rpg, "ember_sword")
	assert(p.commit(p.data))
	var scene = load("res://scenes/main.tscn").instantiate()
	scene.progress = p
	root.add_child(scene)
	await process_frame
	scene.start_campaign(1)
	scene.battle.state = "won"
	scene.battle.elapsed = 10
	var before := p.data.duplicate(true)
	p.fail = true
	scene.show_campaign_result()
	assert(not scene.receipt.ok and p.data == before)
	p.fail = false
	scene.show_campaign_result()
	receipt = scene.receipt
	assert(receipt.ok and receipt.loot.uid == 0 and receipt.dust == 7)
	assert(p.data.rpg.dust-before.rpg.dust == receipt.dust)
	assert(p.data.rpg.sweep_tokens-before.rpg.sweep_tokens == receipt.sweep_tokens)
	assert("+7 bụi" in labels(scene.campaign_panel) and "+1 vé quét" in labels(scene.campaign_panel))
	var settled := p.data.duplicate(true)
	scene.show_campaign_result()
	assert(p.data == settled)
	var restored := Progress.new(p.path)
	assert(restored.load_game() and restored.data == settled)
	token = p.begin_run(1)
	dust = p.data.rpg.dust
	tickets = p.data.rpg.sweep_tokens
	receipt = p.finish_run(token, false, 10, 0)
	assert(receipt.ok and receipt.dust == 0 and receipt.sweep_tokens == 0)
	assert(p.data.rpg.dust == dust and p.data.rpg.sweep_tokens == tickets)
	scene.audio.stop_all()
	scene.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("PASS: campaign receipt matches dust/ticket deltas, full inventory UI, failed-save retry/dedup, reload and loss rewards")
	quit()
