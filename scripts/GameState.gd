# GameState.gd
extends Node

var player_return_position: Variant = null

var persevere_minigame_completed: bool = false
var persevere_minigame_dialogue_shown: bool = false

var cat_is_following_globally: bool = false
var level_1_story_exit_completed: bool = false

# NEW: Track if cat dialogue has been encountered
var cat_dialogue_completed: bool = false

# NEW: Track which level we're returning from
var returning_from_level: String = ""

var triggered_dialogues = {}

func _ready():
	print("GameState ready.")

# Marks a dialogue trigger as having been activated.
func mark_dialogue_as_triggered(unique_trigger_id: String):
	if not triggered_dialogues.has(unique_trigger_id):
		triggered_dialogues[unique_trigger_id] = true
		print("Dialogue trigger marked as triggered: ", unique_trigger_id)

# Checks if a dialogue trigger has already been activated.
func is_dialogue_triggered(unique_trigger_id: String) -> bool:
	return triggered_dialogues.has(unique_trigger_id)

# You could expand this later for full save/load functionality
# func save_game_state():
#     # Example: Save triggered_dialogues to a file
#     var file = FileAccess.open("user://save_game.dat", FileAccess.WRITE)
#     file.store_var(triggered_dialogues)
#     file.close()

# func load_game_state():
#     # Example: Load triggered_dialogues from a file
#     if FileAccess.file_exists("user://save_game.dat"):
#         var file = FileAccess.open("user://save_game.dat", FileAccess.READ)
#         triggered_dialogues = file.get_var()
#         file.close()
#         print("Loaded triggered dialogues: ", triggered_dialogues)
#     else:
#         print("No save file found for game state.")
