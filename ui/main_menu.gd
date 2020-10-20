extends Control

onready var parent = get_parent()

func _on_new_game_pressed():
	parent.ui.load_screen("lobby")
