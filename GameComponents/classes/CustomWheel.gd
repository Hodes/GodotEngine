extends "Wheel.gd"

var tiremark = null

func _ready():
	tiremark = get_node("TireMarks")

func startSlide():
	tiremark.set_emitting(true)

func stopSlide():
	tiremark.set_emitting(false)