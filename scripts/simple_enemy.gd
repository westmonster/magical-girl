extends KinematicBody

# IMPORTANT NODES
onready var player = get_tree().get_root().get_node("world/players/Player")
var weapon
var shield
onready var tween  = get_node("Tween")
var animation

var m = SpatialMaterial.new()

# STATES
var following	= true
var chasing		= true
var seeking		= false
var fleeing		= false
var pursuing	= false
var evading		= false
var wandering	= false
var stunned		= false

export var Health = 30
export(int) var points = 10
export(float) var SPEED = 300.0

var generator
var target
var lastTargetPos
onready var Target_Point = translation
export(float) var Arrival_Radius = 1.5
export var Low_Health	 = 5
export(bool) var floating = false

var velocity = Vector3()
var x = 0
var FootPoint
var random
var turnSpeed = 0


##########################
#						 #
#   GENERAL FUNCTIONS    #
#						 #
##########################

########################
#       ROLL_RNG       #
########################
func roll_rng():
	randomize()
	#random = randf() * (2*PI) - PI
	random = rand_range(-PI, PI)
	#print(random)

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
#    GET TARGET POINT   #
#########################
func get_target_point():
	#if has_line_of_sight():
	if target == player:
		Target_Point = target.FootPoint
	else:
		Target_Point = target.translation
	return Target_Point
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
	#prints("targetDot: ",targetDot)
	if targetDot > 0.8:
		return true
	return false


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
	#print(ray.get_collider())
	if ray.get_collider() == target:
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
	#print("meleeing!")
	if weapon != null:
		weapon.Action()
		if animation:
			#print("has animation player node")
			if animation.current_animation != "attack":
				#print("animating melee")
				animation.play("attack")
	return true

##########################
#         BLOCK          #
##########################
func block():
	if shield != null:
		shield.NPC_Action()
	return true

##########################
#       PROJECTILE       #
##########################
func projectile():
	return true

##########################
#          DIE           #
##########################
func die():
	if generator.get_ref():
		generator.get_ref().maxSpawnable += 1
	self.queue_free()

##########################
#						 #
# 	STEERING BEHAVIORS	 #
#						 #
##########################

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
	#rotation.y = -toRot
	#print(rotDiff)
	if rotDiff < -0.5:
		rotation.y+=5*delta
		return

	if rotDiff > -0.5:
		rotation.y-=5*delta
		return
	
	#print(toRot)
	if abs(rotDiff) <= -3:
		rotation.y = -toRot

##########################
#     TURN TO VECTOR     #
##########################
func turn_to_vector_B(to):
	var delta = get_process_delta_time()
	var rotTransform = transform.looking_at(to,Vector3(0,1,0))
	var thisRotation = Quat(transform.basis).slerp(rotTransform.basis,turnSpeed)
	turnSpeed += delta
	if turnSpeed>1:
    	turnSpeed = 1
	transform = Transform(thisRotation,transform.origin)

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

	var dotProd = -Vector2(sin(rotation.y),cos(rotation.y)).dot(Vector2(moveDir.x,moveDir.z))
	if dotProd < 0: dotProd = 0
	#prints("dotProd: ",dotProd, "; MoveDir: ", moveDir, "; moveAmount:", moveAmount )
	#dotProd = 1
	#print(moveDir)
	#prints("movement: ", moveDir * moveAmount * dotProd)
	move_and_slide( moveDir * moveAmount * dotProd ,Vector3(0,1,0))
	seeking = true
	if animation.current_animation != "walk":
		animation.play("walk")
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
	#prints("dotProd: ",dotProd)
	move_and_slide( moveDir * moveAmount * dotProd ,Vector3(0,1,0))
	return false

##########################
#         STUN           #
##########################
func stun(onoff):
	stunned = onoff

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
#      TAKE  DAMAGE      #
##########################
func TakeDamage(dmg,weapon):
	var y=x%3
	"""
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
	"""
	#get_node("armature/Skeleton/model").get_surface_material(1).set_albedo(get_node("armature/Skeleton/model").get_surface_material(1).get_albedo()/2)
	#if !weapon.has_variable("maxDistanceInUnits"):
	x+=1
	Health-=dmg
	animation.play("stun")
	
	if Health <= 0:
		weapon.get_node(weapon.Owner).ChangeScore(points)
		die()

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	#set_physics_process(true)
	
	
	if has_node("AnimationPlayer"):
		animation = get_node("AnimationPlayer")
	
	if get_node("weapon").get_child_count() > 0:
		weapon = get_node("weapon").get_child(0)
	if get_node("shield").get_child_count() > 0:
		shield = get_node("shield").get_child(0)
	#tween.connect("tween_completed",self,"IncrementPathIndex")
	#tween.connect("tween_started",self,"TweenStarted")
	#tween.start()
	#rotation = Vector3(0,0,0)
	#path = navigation.get_simple_path(translation,player.translation)
	m.flags_unshaded = true
	m.flags_no_depth_test = true
	m.flags_use_point_size = true
	m.albedo_color = Color(1.0, 1.0, 1.0, 1.0)

	weapon.is_NPC = true

	target = player

	#prints("Generated first path: ", path)
	#Target_Point = path[0]
	#prints("Target Point: ", Target_Point)
	#prints("Added ", get_instance_id(), " at location: ", translation)

func _physics_physics_process(delta):
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
	#find()
	#if is_in_range():
	#	if !is_facing_target():
	#		face_target()
	#		return
	#	melee()
	
	if animation:
		if !stunned:
			if !animation.is_playing():
				if seeking:
					animation.play("walk")
				else:
					animation.play("idle")
	
	if floating:
		get_node("armature").translation = Vector3(0,0.35 + sin(float(OS.get_ticks_msec()+random+((translation.x+translation.y)/2))/500)/10,0)
	if !stunned:
		#print("not stunned")
		if translation.distance_to(target.translation) > Arrival_Radius:
			#print("seeking")
			seek()
		else:
			turn_to_vector(target.translation - translation)
			#if has_line_of_sight():
			melee()
	
	
	seeking = false
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


