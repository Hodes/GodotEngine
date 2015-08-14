
extends StaticBody2D

export(int) var frontOffset = 100
# member variables here, example:
# var a=2
# var b="textvar"
var oPlayerChar = null

func _ready():
	set_fixed_process(true)
	oPlayerChar = get_node("/root/World/DevMan")

func _fixed_process(delta):
	if(oPlayerChar.get_pos().x > get_pos().x + frontOffset):
		set_z(1)
	else:
		set_z(0)
