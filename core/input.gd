extends Node

onready var parent = get_parent()

func handle_event(_event):
	if Input.is_key_pressed(KEY_ESCAPE):
		parent.ui.show_menu()
	if parent.player:
		if Input.is_action_pressed("punch_left"):
			parent.player.attack()
