extends Control

onready var parent = get_parent()
onready var player_name = get_node("CanvasLayer/player_name")
onready var lobby_name = get_node("CanvasLayer/lobby_name")
onready var host_address = get_node("CanvasLayer/host_address")

func _on_host_game_pressed():
	parent.network._on_host_game()
	parent.network._on_join_game(player_name.text, lobby_name.text, host_address.text)
	
func _on_join_game_pressed():
	parent.network._on_join_game(player_name.text, lobby_name.text, host_address.text)
