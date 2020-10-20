extends Node

onready var parent = get_parent()
onready var player = preload("res://player/player.tscn")

var player_instance

func load_player(networked=false):
	player_instance = player.instance()
	player_instance.networked = networked
	parent.add_child(player_instance)
	
	return player_instance
