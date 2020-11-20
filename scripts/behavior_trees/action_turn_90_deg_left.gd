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
			turn_tween.interpolate_property(root, "rotation:y", root.rotation.y, stepify(root.rotation.y + (PI/2), PI/2), 0.25, 0, 2, 0)
			turn_tween.start()
			return ERR_BUSY
	else:
		return FAILED
	
	
	"""if !turn_started:
		start_rot = root.rotation.y
		turn_started = true
		prints("Turn Started: ", start_rot)
	if turn_started:
		if Vector2(sin(root.rotation.y),cos(root.rotation.y)).dot(Vector2(sin(start_rot),cos(start_rot))) <= 0:
			turn_started = false
			return OK
			prints("Turn Finished!")
		root.rotation.y += root.turn_speed * get_process_delta_time()
		prints("Still Turning!")
	return FAILED"""