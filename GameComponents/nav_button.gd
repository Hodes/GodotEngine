
extends Button

export(String) var sceneName = ""

func _ready():
	connect("pressed", self, "on_click")


func on_click():
	if not sceneName.empty():
		get_tree().change_scene("res://sample_scenes/"+self.sceneName+".xscn")
	else:
		get_tree().change_scene("res://main.xscn")