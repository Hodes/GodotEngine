
extends Node

# member variables here, example:
# var a=2
# var b="textvar"
var oCamera = null
var followObject = null
var Game = null

func _ready():
	Game = get_node("/root/Game")
	Game.oWorld = self
	Game.updateGUI()
	#Set the spaws on game
	Game.addEnemySpaw(get_node("EnemySpaw1").get_pos())
	Game.addEnemySpaw(get_node("EnemySpaw2").get_pos())
	Game.itemSpawArea[0] = get_node("ItemSpawMin").get_pos().x
	Game.itemSpawArea[1] = get_node("ItemSpawMax").get_pos().x
	
	oCamera = get_node("Camera2D")
	oCamera.make_current()
	#global.set_current_camera(oCamera)
	followObject = get_node("DevMan")
	set_fixed_process(true)
	get_viewport().connect("size_changed",self,"viewportChanged")

func viewportChanged():
	var viewportRect = get_viewport().get_rect()
	var oBG = get_node("ParallaxBackground/BG")
	oBG.set_pos(Vector2(viewportRect.size.x/2,0))

func _fixed_process(delta):
	oCamera.set_pos(followObject.get_pos())