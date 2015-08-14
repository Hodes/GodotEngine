extends RigidBody2D

var Game = null

var headAnimator = null
var upperBodyAnimator = null
var lowerBodyAnimator = null
var oUpperBody = null
var oLowerBody = null
var oFrontArm = null
var oBackArm = null
var weaponShootPos = null

var lastDirection = 1
var shootCountDown = 5.0
var shootTime = 5.0

var speed = 450.0
var jumpStrength = 30.0

#Character STATES
var falling = true
var jumping = false
var moving = false
var holdingWeap = true

func _input(event):
	# Mouse in viewport coordinates
	if (event.type==InputEvent.MOUSE_MOTION):
		var mousePos = event.pos
		controlAim(mousePos)
	if event.is_action("fire") and event.is_pressed():
		var mousePos = event.pos
		shoot(mousePos)

func _ready():
	Game = get_node("/root/Game")
	Game.oPlayer = self
	#headAnimator = get_node("UpperBody/Torso/Head/HeadAnimationPlayer")
	#headAnimator.play("LoopHead")
	upperBodyAnimator = get_node("UpperBody/UpperBodyAnimation")
	lowerBodyAnimator = get_node("LowerBody/LowerBodyAnimation")
	
	oUpperBody = get_node("UpperBody")
	oLowerBody = get_node("LowerBody")
	oFrontArm = oUpperBody.get_node("Torso/FrontArm")
	oBackArm = oUpperBody.get_node("Torso/BackArm")
	
	weaponShootPos = oFrontArm.get_node("FrontUpperArm/FrontLowerArm/WeaponSocket/Weapon/shoot_pos")
	
	set_fixed_process(true)
	set_process_input(true)

func touchGround():
	falling = false
	jumping = false

func shoot(mousePos):
	if shootCountDown <= 0:
		#Vector Up rotated on arm angle
		var viewportOrigin = get_viewport_transform().get_origin() * -1
		var mousePosInViewport = mousePos + viewportOrigin
		var rotToMouse = oFrontArm.get_global_pos().angle_to_point(mousePosInViewport)
		var projectileSpeed = Vector2(0,-Game.projectileSpeed).rotated(rotToMouse)
		Game.spawProjectile(weaponShootPos.get_global_pos(), projectileSpeed)

func switchAnimation(anim,bodyLevel=0):
	if anim == "Falling":
		jumping = false
		falling = true
	if bodyLevel==1:
		if upperBodyAnimator.get_current_animation() != anim:
			upperBodyAnimator.play(anim)
	if bodyLevel==2:
		if lowerBodyAnimator.get_current_animation() != anim:
			lowerBodyAnimator.play(anim)
	
func processAnimations():
	if holdingWeap:
		switchAnimation("HoldWeapon",1)
		
	if jumping:
		if not holdingWeap:
			switchAnimation("Jump",1)
		switchAnimation("Jump",2)
	elif falling:
		if not holdingWeap:
			switchAnimation("Falling",1)
		switchAnimation("Falling",2)
	elif moving: 
		if not holdingWeap:
			switchAnimation("Running",1)
		switchAnimation("Running",2)
	else:
		if not holdingWeap:
			switchAnimation("Idle",1)
		switchAnimation("Idle",2)
	

func controlAim(mousePos):
	var viewportOrigin = get_viewport_transform().get_origin() * -1
	var mousePosInViewport = mousePos + viewportOrigin
	var inverted = false
	if oUpperBody.get_global_pos().x < mousePosInViewport.x:
		oUpperBody.set_scale(Vector2(1,1))
	elif oUpperBody.get_global_pos().x > mousePosInViewport.x:
		oUpperBody.set_scale(Vector2(-1,1))
		inverted = true
	#Rotate the arm
	var rotToMouse = oFrontArm.get_global_pos().angle_to_point(mousePosInViewport)
	if inverted:
		rotToMouse = -rotToMouse
	oFrontArm.set_rot(rotToMouse+(PI/2))
	oBackArm.set_rot(rotToMouse+(PI/2))

func _fixed_process(delta):
	var btn_right = Input.is_action_pressed("ui_right")
	var btn_left = Input.is_action_pressed("ui_left")
	var btn_up = Input.is_action_pressed("ui_up")
	var btn_down = Input.is_action_pressed("ui_down")
	
	var dirVec = Vector2()
	
	if btn_right:
		dirVec = Vector2(1.0,0)
		moving = true
		lastDirection = 1
	elif btn_left:
		dirVec = Vector2(-1.0,0)
		moving = true
		lastDirection = 0
	else: 
		moving = false
		
	#Process the shooting time
	if shootCountDown > 0:
		shootCountDown -= 0.1
	
	#Test ground before test jump
	if get_node("GroundCheckRay").is_colliding():
		falling = false
	else: 
		falling = true
	
	#Apply the movement to the character Body
	var currentVel = get_linear_velocity()
	#Jump
	if btn_up and not falling and not jumping:
		currentVel.y = -jumpStrength*20
		set_linear_velocity(currentVel)
		jumping = true
	#Move on X axis
	currentVel.x = speed * dirVec.x
	set_linear_velocity(currentVel)
	
	#Do inversions on sprites
	if lastDirection==0:
		oLowerBody.set_scale(Vector2(-0.8,0.8))
	else:
		oLowerBody.set_scale(Vector2(0.8,0.8))
	
	#Process the animations
	processAnimations()
	