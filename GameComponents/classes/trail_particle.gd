extends Node2D

# member variables here, example:
# var a=2
# var b="textvar"
export(int) var segments = 3
export(int) var width = 20
export(float) var tailSpeed = 0.5
export(Color) var fillColor = Color(0,0,0,1)
export(Texture) var tex = null

var pointOffset = []
var pointsPos = Vector2Array()
var pointsUV = Vector2Array()

func _ready():
	# Initialization here
	var globalTransform = get_global_transform()
	#Get the global origin plus the local position
	var offset = globalTransform.get_origin()
	#sum with the local position if it has parent
	if get_parent() != null:
		offset += get_pos().rotated(globalTransform.get_rotation())*globalTransform.get_scale()
	
	pointOffset = [Vector2(0.0,-(width/2.0)), Vector2(0.0,(width/2.0))]
	
	for i in range(segments):
		pointsPos.push_back(Vector2(offset.x+pointOffset[0].x, offset.y+pointOffset[0].y) * globalTransform.get_scale())
		#print("Point [",i,"] added to ",pointsPos[pointsPos.size()-1].x," , ",pointsPos[pointsPos.size()-1].y)
		pointsPos.push_back(Vector2(offset.x+pointOffset[1].x, offset.y+pointOffset[1].y) * globalTransform.get_scale())
		#print("Point [",i,"] added to ",pointsPos[pointsPos.size()-1].x," , ",pointsPos[pointsPos.size()-1].y)
		pointsUV.push_back(Vector2(i/(segments-1.0),0))
		#print("UV [",i,"] added to ",pointsUV[pointsUV.size()-1].x," , ",pointsUV[pointsUV.size()-1].y)
		pointsUV.push_back(Vector2(i/(segments-1.0),1))
		#print("UV [",i,"] added to ",pointsUV[pointsUV.size()-1].x," , ",pointsUV[pointsUV.size()-1].y)

	set_process(true)
	update()
	
func _process(delta):
	var globalTransform = get_global_transform()
	var lastPoints = [pointsPos.get(pointsPos.size()-2),pointsPos.get(pointsPos.size()-1)]
	
	#Update the last iteration to the center offset of the effect
	var origin = globalTransform.get_origin()
	var angle = globalTransform.get_rotation()
	if get_parent() != null:
		origin += get_pos().rotated(angle)*globalTransform.get_scale()
	var rotatedOffset = Vector2Array()
	rotatedOffset.push_back(pointOffset[0].rotated(angle)*globalTransform.get_scale())
	rotatedOffset.push_back(pointOffset[1].rotated(angle)*globalTransform.get_scale())
	
	lastPoints[0].x = origin.x+rotatedOffset[0].x
	lastPoints[0].y = origin.y+rotatedOffset[0].y
	lastPoints[1].x = origin.x+rotatedOffset[1].x
	lastPoints[1].y = origin.y+rotatedOffset[1].y
	
	pointsPos.set(pointsPos.size()-2,lastPoints[0])
	pointsPos.set(pointsPos.size()-1,lastPoints[1])
	
	for i in range(pointsPos.size()-lastPoints.size()):
		var nextPoint = i+2
		var pointA = pointsPos[i]
		var pointB = pointsPos[nextPoint]
		var distance = pointA.distance_to(pointB)
		var speedFactor = distance*tailSpeed
		var directionVec = Vector2(0,-1)
		var angle = pointA.angle_to_point(pointB)
		var speedVec = directionVec.rotated(angle) * speedFactor
		var resultVec = pointsPos.get(i) + speedVec
		pointsPos.set(i, resultVec)
	
	update()
	
func _draw():
	#Set default transformation for drawing
	var globalTransform = get_global_transform().affine_inverse()
	draw_set_transform(globalTransform.get_origin(),globalTransform.get_rotation(),globalTransform.get_scale())
	
	for i in range(pointsPos.size()-2):
		var tri = Vector2Array()
		var uv = Vector2Array()
		for j in [0,1,2]:
			var pointIndex = i+j
			var pointPos = pointsPos.get(pointIndex)
			if j==0:
				var a = pointPos.distance_to(pointsPos.get(pointIndex+1))
				var b = pointsPos.get(pointIndex+1).distance_to(pointsPos.get(pointIndex+2))
				var c = pointsPos.get(pointIndex+2).distance_to(pointPos)
				if c < 3.0 || b <3.0 || a < 3.0: 
					##print("Skip tri point ", pointIndex)
					continue
			uv.push_back(pointsUV.get(pointIndex))
			tri.push_back(Vector2(pointPos.x,pointPos.y))
			
			#print(pointIndex," Vertex UV   at ",pointsUV.get(pointIndex).x," and ",pointsUV.get(pointIndex).y)
			#print(pointIndex," Draw vertex at ",tri.get(tri.size()-1).x," and ",tri.get(tri.size()-1).y)
		if tri.size() != 3:
			#print("Skipping triangle ",i)
			continue
		if tex != null:
			draw_colored_polygon(tri, fillColor, uv, tex)
		else: 
			draw_colored_polygon(tri, fillColor)
	