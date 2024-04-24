extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_single_mode_button_pressed():
	Global.goto_scene("res://scene/main_game.tscn")

func _on_multi_player_mode_button_pressed():
	Global.goto_scene("res://scene/multiplayer_config_menu.tscn")

func _on_quit_button_pressed():
	print_debug("Quit game")
	get_tree().quit()
