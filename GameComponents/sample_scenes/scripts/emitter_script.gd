
extends Node2D

# member variables here, example:
# var a=2
# var b="textvar"
var lastPos = null

func _input(ev):
	# Mouse in viewport coordinates
	if (ev.type==InputEvent.MOUSE_BUTTON):
		print("Mouse Click/Unclick at: ",ev.pos)
	elif (ev.type==InputEvent.MOUSE_MOTION):
		var mousePos = ev.pos
		if(mousePos.distance_to(lastPos) > 5):
			set_rot(lastPos.angle_to_point(mousePos)-(PI/2))
		set_pos(mousePos)
		lastPos = mousePos

func _ready():
	# Initialization here
	lastPos = get_pos()
	edit_set_pivot( Vector2() )
	set_process_input(true)


