extends Area

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export(String)	var nextLevel = "res://scenes/levels/lvl1.tscn"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func UseFunction(user):
	pass


func _on_exit_body_entered(body):
	if body is preload("res://scripts/Player0.gd"):
		get_tree().change_scene(nextLevel)
