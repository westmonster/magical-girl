extends RayCast


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
var air

# Called when the node enters the scene tree for the first time.
func _ready():
	set_physics_process(true)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	air = (get_collision_point() - global_transform.origin).length()
	if(is_colliding()):
		$Shadow.opacity = 1-(air  / 10)
		$Shadow.scale = Vector3(1,1,1)-(Vector3(air,air,0)/10)
		#prints("Shadow opacity:", $Shadow.opacity)
	else:
		$Shadow.opacity = 0
		$Shadow.scale = Vector3(0,0,1)
	pass
