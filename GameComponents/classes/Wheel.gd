extends PinJoint2D

export(bool) var hasTorque = false
export(bool) var hasSterring = false
# How much the wheel grip in the ground
export(float) var grip = 1.0

var isSliding = false

# The wheel rigidbody
var body = null

func _init():
	pass
	
func _ready():
	if has_node("WheelBody"):
		self.body = get_node("WheelBody")
		if self.body extends RigidBody2D:
			set_node_b(self.body.get_path())
	else:
		print("The wheel body is not present in the wheel tree. Please create a RigidBody2D with name 'WheelBody'.")
	

func _enter_tree():
	var parent = get_parent()
	if parent != null and parent extends RigidBody2D:
		set_node_a(parent.get_path())
	if not (parent extends RigidBody2D):
		print("Wheel parent isn't a RigidBody2d, the wheel will not work properly.")

func startSlide():
	pass

func stopSlide():
	pass

func sliding():
	pass

