
extends Node

var oCar = null

func _ready():
	oCar = get_node("Car")
	oCar.debug = get_node("Dbug")
	set_fixed_process(true)

func _fixed_process(delta):
	
	if Input.is_action_pressed("ui_up"):
		oCar.throttle = 1.0
		oCar.reverse = false
	elif Input.is_action_pressed("ui_down"):
		oCar.throttle = 1.0
		oCar.reverse = true
	else:
		oCar.throttle = 0.0
	
	if Input.is_action_pressed("ui_left"):
		oCar.steering = -1.0
	elif Input.is_action_pressed("ui_right"):
		oCar.steering = 1.0
	else:
		oCar.steering = 0.0
	
	if Input.is_key_pressed(KEY_BACKSPACE):
		oCar.set_pos(Vector2(150,150))
