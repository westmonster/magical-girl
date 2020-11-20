extends Node

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var flip_flop

func _ready():
	flip_flop = false

func _tick(root):
	flip_flop = !flip_flop
	if flip_flop:
		return OK
	else:
		return FAILED