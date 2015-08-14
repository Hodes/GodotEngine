
extends RigidBody2D

export(float) var HP = 100.0
export(int) var level = 1
export(float) var attack = 15.0
export(float) var speed = 340.0


export(float) var HPMax = 50.0
export(float) var XPAmount = 10
export(String) var name = ""

var Game = null
var oAnimator = null
var oDmgTest = null
var oPlayer = null

var isWalking = false
var isAttacking = false
var isDying = false
# -1 left 1 right
var direction = 1
var raycastInitialPos = 0

func _ready():
	Game = get_node("/root/Game")
	oAnimator = get_node("Animator")
	oPlayer = Game.oPlayer
	oDmgTest = get_node("DamageTest")
	raycastInitialPos = oDmgTest.get_pos()
	get_node("Info").set_text(str(level," - ",name))
	var TotalHP = float(level * HPMax)
	HP = TotalHP
	updateHP()
	set_fixed_process(true)

func updateHP():
	var TotalHP = float(level * HPMax)
	var hpPercent = float(HP/TotalHP)
	#print("Current HP:",HP," percent: ",hpPercent," Total: ",TotalHP)
	if hpPercent < 0:
		get_node("HP").set_scale(Vector2(0,1.0))
	else:
		get_node("HP").set_scale(Vector2(hpPercent,1.0))

func causeDamage():
	if oDmgTest.is_colliding() and oDmgTest.get_collider().is_in_group("Player"): 
		Game.damagePlayer(attack * level)

func receiveDamage(amount):
	HP -= amount
	updateHP()
	if HP <= 0.0:
		die()

func die():
	if not isDying:
		isAttacking = false
		isWalking = false
		isDying = true
		#Give XP to player
		Game.givePlayerXP(level * XPAmount)
		Game.enemiesAlive -= 1
		Game.updateGUI()
		oAnimator.play("Dying")

func processAnimations():
	if isAttacking and oAnimator.get_current_animation() != "Attack":
		oAnimator.play("Attack")
	elif isWalking and oAnimator.get_current_animation() != "Walking":
		oAnimator.play("Walking")

func _fixed_process(delta):
	if oPlayer != null and not isDying:
		if oPlayer.get_pos().x > get_pos().x and not isAttacking: 
			direction = 1
			isWalking = true
		if oPlayer.get_pos().x < get_pos().x and not isAttacking:
			direction = -1
			isWalking = true
		
		if oPlayer.get_pos().distance_to(get_pos()) < 200:
			oDmgTest.set_enabled(true)
			oDmgTest.set_pos(Vector2(direction*raycastInitialPos.x,raycastInitialPos.y))
			#oDmgTest.set_cast_to(Vector2(direction*50.0,0.0))
			isAttacking = true
			isWalking = false
		else:
			isAttacking = false
			oDmgTest.set_enabled(false)
		#Move
		get_node("DirectionControl").set_scale(Vector2(direction,1))
		set_linear_velocity(Vector2(direction*speed,get_linear_velocity().y))
	else:
		oPlayer = Game.oPlayer
	
	processAnimations()
