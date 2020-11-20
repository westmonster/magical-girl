extends Node

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	set_physics_process(true)

func _physics_process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
	if get_child_count() > 0:
		var children = get_children()
		for i in children:
			if i.start_point.distance_to(i.translation) > i.maxDistanceInUnits:
				if i.projectileName == "potion":
					i.smash()
				else:
					i.kill()
			else:
				if i.projectileName == "potion":
					var j = i.fallRate * delta
					i.move_and_slide((Vector3(0,-j,0) + i.direction) * i.velocity * delta, Vector3(0,1,0), 0.05, 4, 0.785398 )
					i.fallRate += j
					if i.is_on_wall() or i.is_on_floor():
						i.smash()
				else:
					#prints("Direction: ", i.direction, ", Speed: ", i.velocity, ", Delta: ", delta)
					#prints("total speed: ", i.velocity + i.speedInUnitsPerSecond)
					#prints("Velocity modifier: ", i.velocity*i.direction.dot(i.velocity.normalized()))
					#i.move_and_slide((i.direction * i.speedInUnitsPerSecond) + (i.velocity.normalized() * 2 * clamp(i.direction.dot(i.velocity),0,1)), Vector3(0,1,0), 0.05, 4, 0.785398 )
					i.move_and_slide(i.velocity, Vector3(0,1,0), 0.05, 4, 0.785398 )
					if i.is_on_wall() or i.is_on_ceiling() or i.is_on_floor():
						i.queue_free()
