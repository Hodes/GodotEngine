extends RigidBody2D

# Public
#
var throttle = 0.0 setget throttle_ch
func throttle_ch(newval):
	throttle = clamp(newval,0.0,1.0)
#
var steering = 0.0 setget steering_ch
func steering_ch(newval):
	steering = clamp(newval,-1.0,1.0)
#
var breaking = 0.0 setget breaking_ch
func breaking_ch(newval):
	breaking = clamp(newval,0.0,1.0)
#
var reverse = false

# Private
var _WheelClass = preload("res://classes/wheel.gd")
var _wheels = []
var _sterring_wheels_count = 0
var _torque_wheels_count = 0
var _PIOVERFOUR = PI/4 # Using PI not works as const 45degree
var _PIOVERTWO = PI/2 # Using PI not works as const 90degree

# Debugging
var debug = null

# The steering power is divided by how many wheels with torque the vehicle has
# To low power will not make the vehicle to move
export(float) var power = 10.0
# The weight factor is used to let weight of vehicle 
export(float) var weight_factor = 100

export(bool) var calculate_forces = true # If is to calculate the forces, PhysicsInvolved

export(float) var reverse_power_factor = 0.5 # How much of the vehicle power will be available when reversing

func _ready():
	# Prepare with wheels instances
	updateWheels()
	# If is flagged to calculate the forces
	if calculate_forces:
		set_fixed_process(true)

# This method force the class to prepare the vehicle wheel intances
func updateWheels():
	_wheels.clear()
	var children = get_children();
	for i in range(0,children.size()):
		var oChild = get_child(i)
		if oChild extends _WheelClass:
			# Register the wheel instance to have easy acess
			_wheels.push_back(oChild)
			# Register the correct wheels count of right type
			if oChild.has_torque: 
				self._torque_wheels_count += 1
			if oChild.has_sterring: 
				self._sterring_wheels_count += 1
			

func _fixed_process(delta):
	#Then process wheels
	applySterring(delta)
	applyVehicleForces(delta)

func applySterring(delta):
	for oWheel in _wheels:
		if oWheel.has_sterring:
			oWheel.steering_rot = -self.steering * _PIOVERFOUR

func applyVehicleForces(delta):
	for oWheel in _wheels:
		# #######################
		# Calculate the final rotation of the wheel
		#  agregating all the separated rotations
		var wheel_final_rotation = get_rot() + oWheel.steering_rot + oWheel.relative_rot
		
		#############
		#Calculate the torque diretion vector
		var dirVec = Vector2(0.0,-1.0).rotated(wheel_final_rotation)
		if oWheel.has_torque:
			#Calulate the resulting power based on amount of torque wheels
			var resulting_power = self.power / self._torque_wheels_count
			# Multiply by motor sense of direction
			resulting_power = resulting_power * self.throttle
			# Reverse with 
			if self.reverse:
				resulting_power = resulting_power * -(self.reverse_power_factor)
			#Control the wheels torque
			var vWDir = Vector2(resulting_power, resulting_power)
			vWDir = vWDir * dirVec
			apply_impulse(oWheel.get_global_transform().get_origin()-get_pos(),vWDir)
		
		#############
		#Control the wheel dynamics
		#Get the current wheel velocity 
		# and normalize it to use as factor to calculate the grip force
		var wheel_linear_vel_norm = oWheel.body.get_linear_velocity().normalized()
		var finalWeight = oWheel.body.get_linear_velocity().length() * (get_weight()/self.weight_factor)
		
		#Direction of the wheels grip force
		var wheel_grip_dir = dirVec.rotated(_PIOVERTWO)
		#The resultant force of the grip against the wheel trajectory
		var wheel_grip_force = wheel_linear_vel_norm.dot(wheel_grip_dir)
		
		# Apply the amount of force needed to pause the lateral sliding of the wheel
		# it is the length of wheel linear velocity
		var wheel_grip_forceFinal = wheel_grip_force * finalWeight
		# and then apply the wheel grip factor
		wheel_grip_forceFinal = wheel_grip_forceFinal * oWheel.grip
		
		# calculate the grip force vector
		var grip_force_vector = wheel_grip_dir * -wheel_grip_forceFinal 
		
		#Wheel sliding
		var wheel_sliding_factor = wheel_linear_vel_norm.dot(wheel_grip_dir)
		if not oWheel.is_sliding && wheel_linear_vel_norm.length() > 0.1 && (wheel_sliding_factor > 0.4 || wheel_sliding_factor < -0.4):
			oWheel.is_sliding = true
			oWheel.start_slide()
		elif oWheel.is_sliding && (wheel_linear_vel_norm.length() < 0.1 || (wheel_sliding_factor < 0.4 && wheel_sliding_factor > -0.4)): 
			oWheel.is_sliding = false
			oWheel.stop_slide()
		if oWheel.is_sliding: 
			oWheel.sliding(wheel_sliding_factor)
		
		# Apply the grip force to the wheel
		apply_impulse(oWheel.get_global_transform().get_origin()-get_pos(), grip_force_vector)
		
		if debug != null:
			var vehicleLV = get_linear_velocity()
			# Debug text
			debug.clear()
			debug.add_text("Vehicle LV "+str(vehicleLV.x)+" , "+str(vehicleLV.y))
			debug.newline()
			debug.add_text("LVL "+str(vehicleLV.length()))
			debug.newline()
		
		#Set final updates to the wheel
		oWheel.set_rot(wheel_final_rotation)
		