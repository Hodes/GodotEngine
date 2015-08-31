
extends Node

var oCar = null
var throttle_slider = null

func _ready():
	oCar = get_node("Car")
	throttle_slider = get_node("throttle_slider")
	oCar.debug = get_node("Dbug")
	oCar.inertia_debug = get_node("inertial_device")
	
	throttle_slider.connect("value_changed",self,"throttle_change")
	
	set_fixed_process(true)

func throttle_change():
	oCar.throttle = throttle_slider.get_ticks()

func _fixed_process(delta):
	
	if Input.is_action_pressed("ui_up"):
		oCar.throttle = 1.0
		oCar.reverse = false
	elif Input.is_action_pressed("ui_down"):
		oCar.throttle = 1.0
		oCar.reverse = true
	else:
		oCar.throttle = throttle_slider.get_val()
		print("Sliderval ", str(throttle_slider.get_val()))
	
	if Input.is_action_pressed("ui_left"):
		oCar.steering = -1.0
	elif Input.is_action_pressed("ui_right"):
		oCar.steering = 1.0
	else:
		oCar.steering = 0.0
	
	if Input.is_key_pressed(KEY_BACKSPACE):
		oCar.set_pos(Vector2(150,150))
