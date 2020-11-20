extends KinematicBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var turn_completed = false
var start_rot
var turn_tween = Tween.new()
var flip_flop = false
const max_count = 4
var flip_flop_count = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	add_child(turn_tween)
	turn_tween.repeat = false
	turn_tween.connect("tween_completed", self, "_on_turn_tween_completed")
	
#	pass # Replace with function body.

func _on_turn_tween_completed(object, path):
	#prints("Turn Completed!")
	turn_completed = true
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _tick(root):

	if !turn_tween.is_active():
		if turn_completed:
			turn_completed = false
			if flip_flop_count >= max_count:
				flip_flop = !flip_flop
				flip_flop_count = 0
			else:
				flip_flop_count+=1
				
			return OK
		else:
			var mul
			if flip_flop: mul = 1
			else: mul = -1
			#prints("Flip-flop: ", flip_flop)
			turn_tween.interpolate_property(root, "rotation:y", root.rotation.y, stepify(root.rotation.y + (mul*PI/2), PI/2), 0.125, 0, 2, 0)
			turn_tween.start()
			return ERR_BUSY
	else:
		return FAILED
	