extends "wheel.gd"

var tiremark = null
var smoke = null

func _ready():
	tiremark = get_node("TireMarks")
	smoke = get_node("Smoke")

func start_slide():
	tiremark.set_emitting(true)

func stop_slide():
	tiremark.set_emitting(false)

func skating(skating_factor):
	smoke.set_param(Particles2D.PARAM_INITIAL_SIZE, skating_factor * 30)
	smoke.set_emitting(true)