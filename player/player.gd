extends KinematicBody

onready var parent = get_parent()

var MAX_SPEED = 500
var ACCELERATION = 2000
var motion = Vector3.ZERO
var network_id = 1
var networked = false

func _physics_process(delta):
	if networked:
		pass
	else:
		var axis = get_input_axis()
		
		if axis == Vector3.ZERO:
			apply_friction(ACCELERATION * delta)
		else:
			apply_movement(axis * ACCELERATION * delta)
			
		motion = move_and_slide(motion)
		
		if motion != Vector3(0, 0, 0):
			parent.network.sync_motion(parent.player.network_id, motion)
			
func get_input_axis():
	var axis = Vector3.ZERO
	
	axis.x = int(Input.is_action_pressed("mv_right")) - int(Input.is_action_pressed("mv_left"))
	axis.z = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	
	return axis.normalized()
	
func apply_friction(amount):
	if motion.length() > amount:
		motion -= motion.normalized() * amount
	else:
		motion = Vector3.ZERO
		
func apply_movement(acceleration):
	motion += acceleration
	motion = motion
	
func networked_move(m):
	m = str2var("Vector3" + m)
	var _err = move_and_slide(m)
