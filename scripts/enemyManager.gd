extends Spatial

var delta
onready var player = get_tree().get_root().get_node("world/entities/Player")
# class member variables go here, for example:
# var a = 2
# var b = "textvar"

#########################
#    GET TARGET POINT   #
#########################
func get_target_point(ent):
	#if has_line_of_sight():
	if ent.target == player:
		ent.Target_Point = ent.target.FootPoint
	else:
		ent.Target_Point = ent.target.translation
	#return ent.Target_Point
	#	Target_Point = lastTargetPos

##########################
#     TURN TO VECTOR     #
##########################
func turn_to_vector(ent, to):
	#get_target_point()
	var toRot   = atan2(to.x,to.z)
	var rotDiff = toRot - ent.rotation.y
	if abs(rotDiff) > deg2rad(180):
		rotDiff += -360 if rotDiff > 0 else 360

	if rotDiff < 0:
		ent.rotation.y+=5*delta

	if rotDiff > 0:
		ent.rotation.y-=5*delta

	#if abs(rotDiff) <= 2:
	#	rotation.y = toRot


##########################
#          SEEK          #
##########################
func seek(ent):
	ent.get_target_point()
	var moveDir = (ent.Target_Point - ent.translation).normalized()
	var rotDiff =  atan2(moveDir.x,moveDir.z) - ent.rotation.y
	var moveAmount = delta*ent.SPEED
	#prints("next Path point: ", path[PathIndex])
	#prints("translation: ", translation)
	#prints("moveDir: ", moveDir)
	turn_to_vector(ent, moveDir)

	#if not is_on_floor():
	#	ent.moveDir.y -= 1000*delta

	var dotProd = -Vector2(moveDir.x,moveDir.z).dot(Vector2(sin(ent.rotation.y),cos(ent.rotation.y)))
	if dotProd < 0: dotProd = 0
	#prints("dotProd: ",dotProd)
	ent.move_and_slide( moveDir * moveAmount * dotProd ,Vector3(0,1,0))
	return false


##########################
#          FLEE          #
##########################
func flee(ent):
	ent.get_target_point()
	var moveDir = (translation - ent.Target_Point).normalized()
	var rotDiff =  atan2(moveDir.x,moveDir.z) - rotation.y
	var moveAmount = delta*ent.SPEED
	#prints("next Path point: ", path[PathIndex])
	#prints("translation: ", translation)
	#prints("moveDir: ", moveDir)
	turn_to_vector(moveDir)

	#if not is_on_floor():
	#	moveDir.y -= 100*delta

	var dotProd = -Vector2(moveDir.x,moveDir.z).dot(Vector2(sin(ent.rotation.y),cos(ent.rotation.y)))
	if dotProd < 0: dotProd = 0
	#prints("dotProd: ",dotProd)
	ent.move_and_slide( moveDir * moveAmount * dotProd ,Vector3(0,1,0))
	return false
	
##########################
#         MELEE          #
##########################

func melee(ent):
	#print("meleeing!")
	if ent.weapon != null:
		ent.weapon.Action()
	return true

##########################
#         THINK          #
##########################

func think(ent):
	if ent.translation.distance_to(ent.target.FootPoint) > ent.Arrival_Radius:
		seek(ent)
	else:
		turn_to_vector(ent, ent.target.FootPoint - ent.translation)
		#if has_line_of_sight():
		melee(ent)

##########################
#         READY          #
##########################

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	#set_physics_process(true)
	pass

func _physics_process(Delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	delta = Delta
	if get_child_count() > 0:
		var children = get_children()
		for i in children:
			think(i)