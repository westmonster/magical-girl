extends Area

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export(String)	var treasureName = ""
export(int)		var points	= 100
export(bool)	var pickup	= true
var currentAnimation = "idle"
var animations = ["idle","sparkle"]

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func treasureName():
	return treasureName

func pickup():
	return pickup

func _on_treasure_body_entered(body):
	if body is preload("res://scripts/Player0.gd"):
		
		get_node("AudioStreamPlayer").play()
		
		translation = Vector3(0,-1,0)
		body.ChangeScore(points)
		hide()



func _on_AudioStreamPlayer_finished():
	queue_free()
