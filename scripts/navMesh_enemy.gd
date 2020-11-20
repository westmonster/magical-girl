extends KinematicBody

# IMPORTANT NODES
export(NodePath) var navigationNode
onready var navigation = get_node(navigationNode)
export(NodePath) var playerNode
onready var player  = get_node(playerNode)
export(float) var SPEED = 300.0
#onready var BehaviorTree = get_node("BehaviorTree")
#onready var Blackboard   = get_node("BehaviorBlackboard")
#onready var weapon		 = get_node("weapon").get_child(0)
#onready var shield		 = get_node("shield").get_child(0)
onready var tween = get_node("Tween")
onready var weapon = get_node("weapon")
onready var shield = get_node("shield")

var m = SpatialMaterial.new()

# STATES
var following	= true
var chasing		= true
var seeking		= false
var fleeing		= false
var pursuing	= false
var evading		= false
var wandering	= false

export var Health = 10

var target
var lastTargetPos 
onready var Target_Point = translation
export var Arrival_Radius = 0.5
export var Low_Health	 = 5

var path = []
var PathIndex = 0
var velocity = Vector3()
var x = 0
var FootPoint


##########################
#						 #
#   GENERAL FUNCTIONS    #
#						 #
##########################

#########################
#        TRUNCATE       #
#########################
func truncate(vector, maximum):
	if vector.length() != 0:
		var i = maximum / vector.length()
		i if i < 1.0 else 1.0
		var v = vector.normalized()
		return v*i
	return Vector3(0,0,0)


func TweenStarted(object,key):
	pass
	#print("Tweening Started!")

##########################
#						 #
#    PASSIVE ACTIONS     #
#						 #
##########################

#########################
#        NEW PATH       #
#########################
func new_path():
	get_target_point()
	var begin = navigation.get_closest_point(translation)
	var end   = navigation.get_closest_point(Target_Point)
	#prints("end: ",end,"player pos: ",player.FootPoint)
	path = navigation.get_simple_path(begin,end,true)
	path = Array(path)
	path.invert()
	
	var im = navigation.get_node("draw")
	#im.material_override = m
	im.clear()
	im.begin(Mesh.PRIMITIVE_POINTS, null)
	im.add_vertex(begin)
	im.add_vertex(end)
	im.end()
	im.begin(Mesh.PRIMITIVE_LINE_STRIP, null)
	
	for x in path:
		#prints("Point in path: ", x)
		im.add_vertex(x)
	im.end()
	#prints("Generated new path: ", path)
	#if path.size() == 0:
	#	return true
	PathIndex = 0
	if path:
		Target_Point = path[0]
	return true

#########################
#    GET TARGET POINT   #
#########################
func get_target_point():
	#if has_line_of_sight():
		if player:
			Target_Point = player.FootPoint
		else:
			Target_Point = player.translation
	#else:
	#	Target_Point = lastTargetPos
##########################
#     HAS LOW HEALTH     #
##########################
func has_low_health():
	if Health <= Low_Health:
		return true
	return false

##########################
#      CLEAR TARGET      #
##########################
func clear_target():
	target = null
	return true

##########################
#       HAS TARGET       #
##########################
func has_target():
	if target != null:
		return true
	return false

##########################
#    IS FACING TARGET    #
##########################
func is_facing_target():
	get_target_point()
	var targetDir = (Target_Point - translation).normalized()
	var targetDot = Vector2(targetDir.x,targetDir.y).dot(Vector2(sin(rotation.y),cos(rotation.y)))#targetDir = atan2(targetDir.x,targetDir.z) 
	prints("targetDot: ",targetDot)
	if targetDot > 0.8:
		return true
	return false

##########################
#       CLEAR PATH       #
##########################
func clear_path():
	path.clear()
	return true

##########################
#       IS IN RANGE      #
##########################
func is_in_range():
	get_target_point()
	if translation.distance_to(Target_Point) > Arrival_Radius*3:
		return false
	else:
		return true
		
##########################
#      IS IN RADIUS      #
##########################
func is_in_arrival_radius():
	get_target_point()
	if translation.distance_to(Target_Point) > Arrival_Radius:
		return false
	return true
		
##########################
#    HAS LINE OF SIGHT   #
##########################
func has_line_of_sight():
	var ray = RayCast.new()
	ray.translation = Vector3(0,0,0)
	ray.cast_to		= target.translation - translation
	ray.force_raycast_update()
	if ray.get_collider() == target:
		print(ray.get_collider())
		lastTargetPos = target.translation
		return true
	return false

##########################
#						 #
#  INTERACTIVE ACTIONS   #
#						 #
##########################

##########################
#         MELEE          #
##########################
func melee():
	print("meleeing!")
	#weapon.Attack()
	return true

##########################
#         BLOCK          #
##########################
func block():
	shield.NPC_Action()
	return true

##########################
#       PROJECTILE       #
##########################
func projectile():
	return true


##########################
#						 #
# 	STEERING BEHAVIORS	 #
#						 #
##########################

##########################
#         CHASE          #
##########################
func chase():
	get_target_point()
	if player.is_on_floor():
		if !chasing:
			path = navigation.get_simple_path(translation,Target_Point)

			#print(path)
			if path.size() > 0:
				#tween.interpolate_property(self,"translation", translation,path[PathIndex],0.2,Tween.TRANS_LINEAR,0)
				#tween.start()
				#chasing = true
				PathIndex = 0

##########################
#          MOVE          #
##########################
func move(to_location):
	var delta   = get_process_delta_time()
	var moveDir = (to_location - translation).normalized()
	var rotDiff =  atan2(moveDir.x,moveDir.z) - rotation.y 
	var moveAmount = delta*SPEED
	#prints("next Path point: ", path[PathIndex])
	#prints("translation: ", translation)
	#prints("moveDir: ", moveDir)
	turn_to_vector(moveDir)
	
	if not is_on_floor():
		moveDir.x = 0
		moveDir.z = 0
		moveDir.y -= 50000*delta
	
	var dotProd = -Vector2(moveDir.x,moveDir.z).dot(Vector2(sin(rotation.y),cos(rotation.y)))
	#if dotProd < 0: dotProd = 0
	dotProd = (dotProd + 1)/2
	#prints("dotProd: ",dotProd)
	move_and_slide( moveDir * moveAmount * dotProd ,Vector3(0,1,0))

##########################
#      FACE TARGET       #
##########################
func face_target():
	var delta = get_process_delta_time()
	#get_target_point()
	var toRot   = atan2(Target_Point.x,Target_Point.z)
	var rotDiff = toRot - rotation.y 
	if abs(rotDiff) > deg2rad(180):
		rotDiff += -360 if rotDiff > 0 else 360
	
	if rotDiff < 0:
		rotation.y+=5*delta
	
	if rotDiff > 0:
		rotation.y-=5*delta
	
	if is_facing_target():
		return true
	
	return false


##########################
#     TURN TO VECTOR     #
##########################
func turn_to_vector(to):
	var delta = get_process_delta_time()
	#get_target_point()
	var toRot   = atan2(to.x,to.z)
	var rotDiff = toRot - rotation.y 
	if abs(rotDiff) > deg2rad(180):
		rotDiff += -360 if rotDiff > 0 else 360
	
	if rotDiff < 0:
		rotation.y+=5*delta
	
	if rotDiff > 0:
		rotation.y-=5*delta
	
	#if abs(rotDiff) <= 2:
	#	rotation.y = toRot

##########################
#          FIND          #
##########################
func find():
	#if has_line_of_sight():
	new_path()
	#get_target_point()
	#prints("Distance to target point: ",abs(translation.distance_to(path[PathIndex])), " Within arrival radius: ", translation.distance_to(path[PathIndex]) < Arrival_Radius)
	if (path.size() > 1):
		var to_walk = get_process_delta_time()*SPEED
		var to_watch = Vector3(0, 1, 0)
		while(to_walk > 0 and path.size() >= 2):
			var pfrom = path[path.size() - 1]
			var pto = path[path.size() - 2]
			to_watch = (pto - pfrom).normalized()
			var d = pfrom.distance_to(pto)
			#if (d <= to_walk):
			if translation.distance_to(path[path.size()-1]) < Arrival_Radius:
				path.remove(path.size() - 1)
				to_walk -= d
			else:
				#path[path.size() - 1] = pfrom.linear_interpolate(pto, to_walk/d)
				to_walk = 0
		
		var atpos = path[path.size() - 1]
		var atdir = to_watch
		atdir.y = 0
		
		"""var t = Transform()
		t.origin = atpos
		t=t.looking_at(atpos + atdir, Vector3(0, 1, 0))
		set_transform(t)"""
		if not is_in_arrival_radius():
			move(path[path.size()-1])
		else:
			if path.size() == 1:
				return true
				path = []
			#turn_to_vector((Target_Point - translation).normalized())
			#if translation.distance_to(Target_Point) < Arrival_Radius*3:
			#	path.clear()
		
		if (path.size() < 1):
			path = []
			return true
		#	set_process(false)
	
	#else:
	#	new_path()
		#print(path)
	
	return false
		

##########################
#          IDLE          #
##########################
func idle():
	following	= false
	chasing		= false
	seeking		= false
	fleeing		= false
	pursuing	= false
	evading		= false
	wandering	= false


##########################
#          SEEK          #
##########################
func seek():
	get_target_point()
	var delta   = get_process_delta_time()
	var moveDir = (Target_Point - translation).normalized()
	var rotDiff =  atan2(moveDir.x,moveDir.z) - rotation.y 
	var moveAmount = delta*SPEED
	#prints("next Path point: ", path[PathIndex])
	#prints("translation: ", translation)
	#prints("moveDir: ", moveDir)
	turn_to_vector(moveDir)
	
	if not is_on_floor():
		moveDir.y -= 1000*delta
	
	var dotProd = -Vector2(moveDir.x,moveDir.z).dot(Vector2(sin(rotation.y),cos(rotation.y)))
	if dotProd < 0: dotProd = 0
	prints("dotProd: ",dotProd)
	move_and_slide( moveDir * moveAmount * dotProd ,Vector3(0,1,0))
	return false


##########################
#          FLEE          #
##########################
func flee():
	get_target_point()
	var delta   = get_process_delta_time()
	var moveDir = (translation - Target_Point).normalized()
	var rotDiff =  atan2(moveDir.x,moveDir.z) - rotation.y 
	var moveAmount = delta*SPEED
	#prints("next Path point: ", path[PathIndex])
	#prints("translation: ", translation)
	#prints("moveDir: ", moveDir)
	turn_to_vector(moveDir)
	
	if not is_on_floor():
		moveDir.y -= 100*delta
	
	var dotProd = -Vector2(moveDir.x,moveDir.z).dot(Vector2(sin(rotation.y),cos(rotation.y)))
	if dotProd < 0: dotProd = 0
	prints("dotProd: ",dotProd)
	move_and_slide( moveDir * moveAmount * dotProd ,Vector3(0,1,0))
	return false


##########################
#         PURSUE         #
##########################
func pursue():
	return false


##########################
#         EVADE          #
##########################
func evade():
	return false


##########################
#         WANDER         #
##########################
func wander():
	return false



##########################
#  INCREMENT PATH INDEX  #
##########################
func IncrementPathIndex(object,key):
	get_target_point()
	#print("Tweening Finished!")
	if path.size() > 0: # if path index has not yet reached the end of the path.
		PathIndex += 1

	if PathIndex == path.size()-1: # if enemy has reached the end of it's path, calculate a new one to the player
		#chasing   = false
		#chase()
		path = navigation.get_simple_path(translation,Target_Point)
		prints("Generated new path: ", path)
		if path.size():
			PathIndex = 0
			Target_Point = path[PathIndex]


##########################
#      TAKE  DAMAGE      #
##########################
func TakeDamage(dmg,weapon):
	var y=x%3
	if(y==0):
		get_node("model1").hide()
		get_node("model2").show()
		get_node("model3").hide()

	if(y==1):
		get_node("model1").hide()
		get_node("model2").hide()
		get_node("model3").show()

	if(y==2):
		get_node("model1").show()
		get_node("model2").hide()
		get_node("model3").hide()
	x+=1

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	#set_physics_process(true)
	set_process(true)
	#tween.connect("tween_completed",self,"IncrementPathIndex")
	#tween.connect("tween_started",self,"TweenStarted")
	#tween.start()
	#rotation = Vector3(0,0,0)
	#path = navigation.get_simple_path(translation,player.translation)
	m.flags_unshaded = true
	m.flags_no_depth_test = true
	m.flags_use_point_size = true
	m.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	
	#weapon.is_NPC = true
	
	target = player
	
	prints("Generated first path: ", path)
	#Target_Point = path[0]
	prints("Target Point: ", Target_Point)

func _physics_process(delta):
	pass
	#FootPoint = get_node("RayCast").get_collision_point()
	#if following:
	#	Target_Point = path[PathIndex]
	#	if translation.distance_to(Target_Point) < Arrival_Radius:
	#		print("Incrementing Path ", Target_Point)
	#		IncrementPathIndex(null,null)
	#if !chasing:
	#	chase()


func _process(delta):
	#BehaviorTree.tick(self, Blackboard)
	find()
	if is_in_range():
		if !is_facing_target():
			face_target()
			return
		melee()
		
	#CheckPathProgress()
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
	#if following:
	#	if !(tween.is_active()):
	#		print("starting tween")
	#		tween.interpolate_property(self,"translation", translation,path[PathIndex],1,Tween.TRANS_LINEAR,0)
	#		tween.start()

		#else:
			#print(tween.get_runtime())
			#if tween.get_runtime() == 1:
			#	tween.start()
			#print(get_node("shield").translation)


