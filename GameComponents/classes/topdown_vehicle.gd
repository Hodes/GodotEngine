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
var _inv_mass = 0
# Must be the global position of 0,0 center of vehicle
var _inertia = null

# Debugging
var debug = null
var inertia_debug = null

# The steering power is divided by how many wheels with torque the vehicle has
# To low power will not make the vehicle to move
export(float) var power = 10.0
# The weight factor is used to let weight of vehicle 
export(float) var weight_factor = 100

export(bool) var calculate_forces = true # If is to calculate the forces, PhysicsInvolved

export(float) var reverse_power_factor = 0.5 # How much of the vehicle power will be available when reversing

export(float) var inertial_recovery = .5

export(float) var max_inertial_dist = 30


func _ready():
	# Set the inertia starting point
	self._inertia = get_global_pos()
	# Prepare with wheels instances
	updateWheels()
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
	# If is flagged to calculate the forces
	if calculate_forces:
		applyVehicleForces(delta)


func applySterring(delta):
	for oWheel in _wheels:
		if oWheel.has_sterring:
			oWheel.steering_rot = -self.steering * _PIOVERFOUR

func _integrate_forces(state):
	_inv_mass = state.get_inverse_mass()

func applyVehicleForces(delta):
	if debug != null:
		# Debug text
		debug.clear()
		
	# Vehicle linear velocity
	var vehicleLV = get_linear_velocity()
		#The vehicle global pos
	var vehicleGpos = get_global_pos()
	
	##
	# CALCULATES INERTIA
	var inertial_diff = Vector2(self._inertia.x - vehicleGpos.x, self._inertia.y - vehicleGpos.y)
	
	self._inertia.x += (inertial_diff.x * -1) * self.inertial_recovery 
	self._inertia.y += (inertial_diff.y * -1) * self.inertial_recovery 
	self._inertia.x = clamp(self._inertia.x, vehicleGpos.x - self.max_inertial_dist, vehicleGpos.x + self.max_inertial_dist) 
	self._inertia.y = clamp(self._inertia.y, vehicleGpos.y - self.max_inertial_dist, vehicleGpos.y + self.max_inertial_dist) 
	
	# Inertial Length
	var inertial_length = self._inertia.distance_to(vehicleGpos)
	# The inertial factor is the percentage between max inertial minus 1% of max inertial, to be able
	# to acceletare... to have a value greater than zero
	var inertial_factor = inertial_length / self.max_inertial_dist
	inertial_factor = clamp(inertial_factor, self.inertial_recovery, 1)
	
	for oWheel in _wheels:
		# #######################
		# Calculate the final rotation of the wheel
		#  agregating all the separated rotations
		var wheel_final_rotation = get_rot() + oWheel.steering_rot + oWheel.relative_rot
		
		# The Direction vector of the wheel
		var dirVec = Vector2(0.0,-1.0).rotated(wheel_final_rotation)
		
		#############
		#Control the wheel dynamics
		#Get the current wheel velocity 
		# and normalize it to use as factor to calculate the grip force
		var wheel_linear_vel_norm = oWheel.body.get_linear_velocity().normalized()
		var finalWeight = oWheel.body.get_linear_velocity().length() * (get_weight() / self.weight_factor)
		
		#Direction of the wheels grip force
		var wheel_grip_dir = dirVec.rotated(_PIOVERTWO)
		#The resultant force of the grip against the wheel trajectory
		var wheel_grip_force = wheel_linear_vel_norm.dot(wheel_grip_dir)
		
		# Apply the amount of force needed to pause the lateral sliding of the wheel
		# it is the length of wheel linear velocity
		var wheel_grip_force_final = wheel_grip_force * finalWeight
		# and then apply the wheel grip factor
		wheel_grip_force_final = wheel_grip_force_final * oWheel.grip
		
		# calculate the grip force vector
		var grip_force_vector = wheel_grip_dir * -wheel_grip_force_final 
		
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
		
		#############
		#Calculate the torque based on diretion vector
		# if the wheel is applied to
		if oWheel.has_torque:
			#Calulate the resulting power based on amount of torque wheels
			var max_wheel_power = self.power / self._torque_wheels_count
			# Multiply by motor sense of direction
			var resulting_power = max_wheel_power * self.throttle
			# Reverse with 
			if self.reverse:
				resulting_power = resulting_power * -(self.reverse_power_factor)
			
			#Control the wheels torque
			# with acceleration vector without influence of factors to be able to compare 
			# with influenced vector
			var vWDir = Vector2(resulting_power, resulting_power)
			vWDir = vWDir * dirVec 
			
			# The acceleration vector influenced by all factors
			var vWDirInfluenced = Vector2(vWDir.x, vWDir.y)
		
			# Now apply the throttle factor and the wheel sliding 
			#   to the main acceleration vector
			vWDirInfluenced = vWDirInfluenced * inertial_factor * (1-abs(wheel_sliding_factor))
			# Calculates the diference bettween the length of acceleration vectors to know the wheel is skating
			var skatin_factor = 0
			if vWDir.length() > 0:
				skatin_factor = 1 - ( vWDirInfluenced.length() / vWDir.length() )
				skatin_factor = skatin_factor * self.throttle
			## Call the method to tell the wheel is skating
			if skatin_factor > 0.1: 
				oWheel.skating(skatin_factor)
			
			if debug != null:
				debug.add_text("SKF "+str(skatin_factor))
				debug.newline()
				
			
			# Apply the acceleration impulse
			apply_impulse(oWheel.get_global_transform().get_origin()-get_pos(), vWDirInfluenced)
		
		
		# Apply the grip force to the wheel
		apply_impulse(oWheel.get_global_transform().get_origin()-get_pos(), grip_force_vector)
		
		if debug != null:
			debug.add_text("Vehicle LV "+str(vehicleLV.x)+" , "+str(vehicleLV.y))
			debug.newline()
			debug.add_text("slide "+str(wheel_sliding_factor))
			debug.newline()
			debug.add_text("LVL "+str(vehicleLV.length() ))
			debug.newline()
		
		if self.inertia_debug != null:
			self.inertia_debug.set_pos(self._inertia)
		
		#Set final updates to the wheel
		oWheel.set_rot(wheel_final_rotation)
		