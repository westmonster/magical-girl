extends KinematicBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var dir

# Called when the node enters the scene tree for the first time.
#func _ready():
#	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
func _tick(root):
	root.get_node("RayCast").force_raycast_update() # DO NOT EDIT THIS LINE, if you retype the '.' after the "get_node("RayCast"), it crashes the editor!
	if root.get_node("RayCast").is_colliding():
		return FAILED
	else:
		var trans = root.get_translation()
		var delta = get_process_delta_time()
		root.velocity = Vector3(0.0,root.velocity.y,0.0)
		if root.is_on_floor():
			root.velocity += root.gravity * 0.1 * delta
		else:
			root.velocity += root.gravity * delta
		
		dir = Vector3()
		var xform = root.get_transform()
		dir -= xform.basis.z
		
		dir.y = 0
		#----- Movement -----
		dir = dir.normalized()
		
		root.velocity.y += delta * root.gravity.y
		
		var hvel = root.velocity
		hvel.y = 0
		
		var target = dir
		target *= root.max_speed
		
		var accel
		if dir.dot(hvel) > 0:
			accel = root.Accel
		else:
			accel = root.Deaccel
				
		hvel = hvel.linear_interpolate(target, accel * delta)
		root.velocity.x = hvel.x
		root.velocity.z = hvel.z
		
		root.velocity = root.move_and_slide( root.velocity , Vector3.UP, 0.05,4,deg2rad(root.max_slope_angle))
		if trans == root.get_translation():
			return FAILED
	
	return OK
	pass