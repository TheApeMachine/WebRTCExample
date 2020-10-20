extends Node

onready var parent = get_parent()
var screen = null

func load_screen(s):
	if screen:
		parent.remove_child(screen)
		
	screen = load(("res://ui/%s.tscn" % s)).instance()
	parent.add_child(screen)
