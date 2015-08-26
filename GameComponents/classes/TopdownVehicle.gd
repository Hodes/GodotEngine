extends RigidBody2D

var MathHelper = preload("res://classes/MathHelper.gd")
var wheelClass = preload("res://classes/Wheel.gd")
var wheels = []
var isAccelerating = false
var sterringAngle = 0.0
var reverse = 1

var _sterringWheelsCount = 0
var _torqueWheelsCount = 0

# Debugging
var debug = null
var arrow = null

# The Sterring power is divided by how many wheels with torque the car have
# To low power will not make the car to move
export(float) var power = 1.0
export(float) var weightFactor = 100

func _ready():
	debug = get_parent().get_node("Dbug")
	arrow = get_parent().get_node("Arrow")
	#print("The vehicle has ",wheels.size()," wheels")
	
	updateWheels()
	
	set_fixed_process(true)

# This method force the class to prepare the car wheel intances
func updateWheels():
	wheels.clear()
	var children = get_children();
	for i in range(0,children.size()):
		var oChild = get_child(i)
		if oChild extends wheelClass:
			# Register the wheel instance to have easy acess
			wheels.push_back(oChild)
			# Register the correct wheels count of right type
			if oChild.hasTorque: 
				self._torqueWheelsCount += 1
			if oChild.hasSterring: 
				self._sterringWheelsCount += 1
			

func _fixed_process(delta):
	if Input.is_action_pressed("ui_down"):
		reverse = -1
	else:
		reverse = 1 
	
	if(Input.is_action_pressed("ui_up") || Input.is_action_pressed("ui_down")):
		isAccelerating = true
	else:
		isAccelerating = false
	
	if Input.is_action_pressed("ui_left"):
		sterringAngle = deg2rad(45)
	elif Input.is_action_pressed("ui_right"):
		sterringAngle = deg2rad(-45)
	else:
		sterringAngle = 0.0
	
	if Input.is_key_pressed(KEY_BACKSPACE):
		set_pos(Vector2(150,150))
	
	#Then process wheels
	applySterring(delta)
	processWheels(delta)

func applySterring(delta):
	for oWheel in wheels:
		if oWheel.hasSterring:
			oWheel.set_rot(sterringAngle)

func processWheels(delta):
	debug.clear()
	for oWheel in wheels:
		# TODO: need to cache the rotation before to 
		# start changing the wheel rotation to steer.
		# Current way the wheel rotation relative to the car 
		#  doesn't affect the driveability
		var wheelFinalRotation = get_rot()
		#############
		#Control the wheels sterring
		if oWheel.hasSterring: 
			wheelFinalRotation = get_rot() + sterringAngle
		
		#############
		#Calculate the torque diretion vector
		var dirVec = Vector2(0.0,-1.0).rotated(wheelFinalRotation)
		#Calulate the resulting power based on amount of torque wheels
		var resultingPower = self.power / self._torqueWheelsCount
		# Multiply by motor sense of direction
		resultingPower = resultingPower * self.reverse
		#Control the wheels torque
		if oWheel.hasTorque and self.isAccelerating:
			var vWDir = Vector2(resultingPower, resultingPower)
			vWDir = vWDir * dirVec
			apply_impulse(oWheel.get_global_transform().get_origin()-get_pos(),vWDir)
		
		#############
		#Control the wheel dynamics
		#Get the current wheel velocity 
		# and normalize it to use as factor to calculate the grip force
		var wheelLinearVelNormalized = oWheel.body.get_linear_velocity().normalized()
		var finalWeight = oWheel.body.get_linear_velocity().length() * (get_weight()/self.weightFactor)
		
		#Direction of the wheels grip force
		var wheelGripDir = dirVec.rotated(PI/2)
		#The resultant force of the grip against the wheel trajectory
		var wheelGripForce = wheelLinearVelNormalized.dot(wheelGripDir)
		
		# Apply the amount of force needed to pause the lateral sliding of the wheel
		# it is the length of wheel linear velocity
		var wheelGripForceFinal = wheelGripForce * finalWeight
		# and then apply the wheel grip factor
		wheelGripForceFinal = wheelGripForceFinal * oWheel.grip
		
		# calculate the grip force vector
		var gripForceVector = wheelGripDir * -wheelGripForceFinal 
		
		#Wheel sliding
		var wheelSlidingFactor = wheelLinearVelNormalized.dot(wheelGripDir)
		if not oWheel.isSliding && wheelLinearVelNormalized.length() > 0.1 && (wheelSlidingFactor > 0.4 || wheelSlidingFactor < -0.4):
			oWheel.isSliding = true
			oWheel.startSlide()
		elif oWheel.isSliding && (wheelLinearVelNormalized.length() < 0.1 || (wheelSlidingFactor < 0.4 && wheelSlidingFactor > -0.4)): 
			oWheel.isSliding = false
			oWheel.stopSlide()
		if oWheel.isSliding: 
			oWheel.sliding()
		
		# Apply the grip force to the wheel
		apply_impulse(oWheel.get_global_transform().get_origin()-get_pos(), gripForceVector)
		
		# Debug 
		var trAngle = Vector2(0,0).angle_to_point(gripForceVector)
		arrow.set_rot(trAngle)
		# Debug text
		debug.add_text("Wheel "+oWheel.get_name())
		debug.newline()
		debug.add_text("Trajectory "+str(wheelLinearVelNormalized.x)+" and "+str(wheelLinearVelNormalized.y))
		debug.newline()
		debug.add_text("Is sliding "+str(oWheel.isSliding))
		debug.newline()
		debug.add_text("Deviation "+str(wheelSlidingFactor))
		debug.newline()
		
		
		#Set final updates to the wheel
		oWheel.set_rot(wheelFinalRotation)
		