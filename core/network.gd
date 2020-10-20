extends Node

onready var parent = get_parent()
var players = {}

func _on_host_game():
	print("network._on_host_game()")
	$server.listen(1234)
	
func _on_join_game(player_name, lobby_name, host_addr):
	print(("network._on_join_game(%s, %s, %s)" % [player_name, lobby_name, host_addr]))
	$client.start(player_name, lobby_name, host_addr)
	parent.remove_child(parent.ui.screen)
	
func add_player(network_id):
	var player = parent.scenes.load_player(false)
	parent.player = player
	player.network_id = network_id
	players[network_id] = player

func sync_motion(network_id, motion):
	$client.sync_motion(network_id, motion)
