
extends RigidBody2D

#Item mode 0 pickup, 1 projectile
export(int) var mode = 0
export(int) var itemID = 0

var Game = null
var ItemConst = null
var oAnimator = null
var life = 10

func _ready():
	# Initialization here
	set_fixed_process(true)
	Game = get_node("/root/Game")
	ItemConst = get_node("/root/ItemConst")
	oAnimator = get_node("Animator")
	setMode(mode)
	setID(itemID)
	connect("body_enter", self, "onCollide")

func onCollide(body):
	if body.is_in_group("Player") and mode == 0:
		pickUp()
	if body.is_in_group("enemy") and mode == 1:
		body.receiveDamage(ItemConst.ItemDamage[itemID] * Game.PlayerLevel)

func setID(id):
	itemID = id
	get_node("Label").set_text(ItemConst.ItemNames[itemID])
	get_node("Sprite").set_frame(itemID)

func setMode(pMode):
	if pMode==0:
		life = 100
		get_node("Label").show()
		oAnimator.play("Flashing")
	elif pMode==1:
		get_node("Label").hide()
		oAnimator.play("Danger")

func pickUp():
	Game.collectItem(itemID)
	get_node("Animator").play("Got")
	#Set to mode -1 destroing
	mode = -1

func _fixed_process(delta):
	if life > 0:
		life -= 0.1
	if life <= 0:
		queue_free()