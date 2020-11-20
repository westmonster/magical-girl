extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func _tick(root):
	if root.health <= 0:
		return FAILED
	return OK