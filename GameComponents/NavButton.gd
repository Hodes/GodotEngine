
extends Button

export(String) var sceneName = ""

func _ready():
	connect("pressed", self, "onClick")


func onClick():
	if not sceneName.empty():
		get_tree().change_scene("res://sample_scenes/"+self.sceneName+".xscn")
	else:
		get_tree().change_scene("res://main.xscn")