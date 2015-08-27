extends "wheel.gd"

var tiremark = null

func _ready():
	tiremark = get_node("TireMarks")

func start_slide():
	tiremark.set_emitting(true)

func stop_slide():
	tiremark.set_emitting(false)

