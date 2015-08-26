#Get a Vector2 resulting from degree and radius
static func degreeRadiusToVector2(degrees, radius):
	var rads = deg2rad(degrees)
	var resX = cos(rads)*radius
	var resY = sin(rads)*radius
	return Vector2(resX,resY)
#Continuous increment or decrement a value within a speed (proportional to 
#the distance between current X desired) until reach desired value 
static func valueWalkProportional(current, desired, speed):
	var step = (desired-current)*speed
	return current+step
#Continuous increment or decrement a value within a speed until reach desired value
static func valueWalkFixed(current, desired, speed):
	var factor = 0
	if(desired<current):
		factor = 1
	elif(desired>current):
		factor = -1
	return current+(factor*speed)