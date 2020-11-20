extends KinematicBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var turn_completed = false
var start_rot
var turn_tween = Tween.new()
# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(turn_tween)
	turn_tween.repeat = false
	turn_tween.connect("tween_completed", self, "_on_turn_tween_completed")
	
#	pass # Replace with function body.

func _on_turn_tween_completed():
	turn_completed = true
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _tick(root):

	if !turn_tween.is_active():
		if turn_completed:
			turn_completed = false
			return OK
		else:
			turn_tween.interpolate_property(root, "rotation:y", root.rotation.y, stepify(root.rotation.y - (PI/2), PI/2), 0.25, 0, 2, 0)
			turn_tween.start()
			return ERR_BUSY
	else:
		return FAILED
	