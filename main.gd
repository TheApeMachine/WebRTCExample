extends Node

onready var scenes = $scenes
onready var input = $input
onready var ui = $ui
onready var network = $network

var player

func _ready() -> void:
	ui.load_screen("main_menu")
	
func _input(_event):
	input.handle_event(_event)
