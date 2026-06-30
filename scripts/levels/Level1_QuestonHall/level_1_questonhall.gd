# level_1_questonhall.gd
extends Node2D

@export var player: CharacterBody2D
@export var cat: CharacterBody2D

@onready var balloon = preload("res://dialogue/balloon.tscn").instantiate()
var dialogue_res = preload("res://dialogue/main.dialogue")

@onready var bgm = $BGMPlayer
var fade_time := 2.0  # Fade time for BGM in seconds

var cat_is_following: bool = false
var minigame_completed: bool = false

func _ready():
	# --- CRITICAL: Handle player positioning FIRST ---
	if GameState.returning_from_level == "level2":
		print("DEBUG: Returning from Level 2")
		GameState.returning_from_level = "" # Reset
		
		if GameState.player_return_position != null and player:
			player.global_position = GameState.player_return_position
			player.set_input_enabled(true)
			var camera = player.get_node_or_null("Camera2D")
			if camera:
				camera.zoom = Vector2.ONE
				camera.reset_smoothing()
			GameState.player_return_position = null
	
	elif GameState.persevere_minigame_completed and GameState.player_return_position != null:
		if player:
			player.global_position = GameState.player_return_position
			player.set_input_enabled(true)
			var camera = player.get_node_or_null("Camera2D")
			if camera:
				camera.zoom = Vector2.ONE
				camera.reset_smoothing()
		GameState.player_return_position = null
	
	add_child(balloon)
	DialogueManager.mutated.connect(_on_dialogue_mutated)
	
	var story_exit = $"0/LevelExitTrigger"
	story_exit.monitoring = false

	# --- HANDLE CAT FOLLOWING STATE ---
	if GameState.cat_is_following_globally:
		cat_is_following = true
		if cat and cat.has_method("start_following"):
			print("DEBUG: Making cat start following player")
			
			# --- NEW: Position cat next to player when returning from Level 2 ---
			if GameState.returning_from_level == "level2" or GameState.returning_from_level == "":
				# Get the FOLLOW_DISTANCE from the cat (same logic as Level 2)
				var cat_spawn_offset = Vector2(player.facing_direction * cat.FOLLOW_DISTANCE, 0)
				cat.global_position = player.global_position + cat_spawn_offset
				
				# Orient the cat correctly based on the player's facing direction
				if player.facing_direction < 0:
					cat.animated_sprite.flip_h = true
				else:
					cat.animated_sprite.flip_h = false
				
				print("DEBUG: Positioned cat at: ", cat.global_position, " (offset: ", cat_spawn_offset, ")")
			
			cat.start_following(player)
	
	# --- HANDLE MINIGAME COMPLETION CLEANUP ---
	if GameState.persevere_minigame_completed:
		$MinigameTrigger.get_child(0).call_deferred("set_disabled", true)
		$MinigameTrigger.call_deferred("set_monitoring", false)
		$HallwayTrigger.get_child(0).call_deferred("set_disabled", true)
		$HallwayTrigger.call_deferred("set_monitoring", false)
		
		if not GameState.persevere_minigame_dialogue_shown:
			balloon.show()
			balloon.start(dialogue_res, "paper_minigame_success")
			GameState.persevere_minigame_dialogue_shown = true
	
	# --- HANDLE CAT DIALOGUE STATE ---
	if GameState.cat_dialogue_completed and cat:
		var encounter_area = cat.get_node_or_null("EncounterArea")
		if encounter_area:
			encounter_area.get_child(0).call_deferred("set_disabled", true)
			encounter_area.call_deferred("set_monitoring", false)

	# --- FADE IN BGM ---
	if bgm:
		bgm.volume_db = -40  # Start quiet
		bgm.play()
		var t = create_tween()
		t.tween_property(bgm, "volume_db", 0, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _exit_tree():
	# --- FADE OUT BGM ---
	if bgm and bgm.playing:
		var t = create_tween()
		t.tween_property(bgm, "volume_db", -40, fade_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		t.finished.connect(func(): bgm.stop())

func _on_dialogue_mutated(data: Dictionary):
	if data.get("mutation") == "follow_cat":
		print("Player chose to follow the cat!")
		cat_is_following = true
		GameState.cat_is_following_globally = true
		if cat and cat.has_method("start_following"):
			cat.start_following(player)
	elif data.get("mutation") == "start_minigame":
		get_tree().change_scene_to_file("res://scenes/minigames/minigame_persevere.tscn")
	elif data.get("mutation") == "proceed_to_level2":
		print("DEBUG: Player chose to proceed to Level 2. Initiating animated exit.")
		GameState.level_1_story_exit_completed = true
		GameState.player_return_position = Vector2(1394, 683)
		
		player.scene_to_load_after_transition = "res://scenes/levels/level2_callereal.tscn"
		player.transition_data = { "exit_direction": -1 }
		player.is_in_transition = true
		player.start_transition()
	elif data.get("mutation") == "stay_in_level1":
		print("DEBUG: Player chose to stay in Level 1.")
		player.set_input_enabled(true)
		$"0/LevelExitTrigger".monitoring = true

func start_cat_dialogue():
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		var tween_in = create_tween()
		tween_in.set_trans(Tween.TRANS_SINE)
		tween_in.tween_property(camera, "zoom", Vector2(1.2, 1.2), 1.0)
	
	DialogueManager.dialogue_ended.connect(_on_cat_dialogue_ended, CONNECT_ONE_SHOT)
	balloon.show()
	balloon.start(dialogue_res, "cat_encounter")

func _on_cat_dialogue_ended(_resource: DialogueResource):
	GameState.cat_dialogue_completed = true
	
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		var tween_out = create_tween()
		tween_out.set_trans(Tween.TRANS_SINE)
		tween_out.tween_property(camera, "zoom", Vector2.ONE, 0.5)
	
	if not GameState.level_1_story_exit_completed:
		$"0/LevelExitTrigger".monitoring = true
		print("DEBUG: LevelExitTrigger is now active.")

func _on_level_exit_trigger_body_entered(body):
	if body != player: return
	player.set_input_enabled(false)
	var choice_dialogue_title = "follow_cat_exit_choices" if cat_is_following else "resist_urge_exit_choices"
	balloon.show()
	balloon.start(dialogue_res, choice_dialogue_title)
	print("DEBUG: Exit choice dialogue started: ", choice_dialogue_title)

func _on_hallway_trigger_body_entered(body):
	if body != player: return
	balloon.start(dialogue_res, "hallway_thoughts")
	$HallwayTrigger/CollisionShape2D.call_deferred("set_disabled", true)

func _on_minigame_trigger_body_entered(body):
	if body != player or minigame_completed: return
	player.set_input_enabled(false)

	var camera = player.get_node_or_null("Camera2D")
	if camera:
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.tween_property(camera, "zoom", Vector2(1.2, 1.2), 1.0)

	balloon.show()
	balloon.start(dialogue_res, "paper_minigame_start")
	$MinigameTrigger.get_child(0).call_deferred("set_disabled", true)
	$MinigameTrigger.call_deferred("set_monitoring", false)

func _on_minigame_completed():
	minigame_completed = true
	$MinigameTrigger.get_child(0).set_disabled(true)
	player.set_input_enabled(true)
	
func start_dialogue_balloon_from_trigger(resource: DialogueResource, title: String):
	balloon.show()
	balloon.start(resource, title)
