extends KinematicBody

# IMPORTANT NODES
onready var gridmap = get_node("../../../GridMap")
onready var player  = get_node("../../player/Player")
export(float) var SPEED = 100.0
onready var BehaviorTree = get_node("BehaviorTree")
onready var Blackboard   = get_node("BehaviorBlackboard")
onready var tween = get_node("Tween")

# STATES
var following	= true
var chasing		= true
var seeking		= false
var fleeing		= false
var pursuing	= false
var evading		= false
var wandering	= false


var target
onready var TargetPoint = translation
var ArrivalRadius = 0.1
var path = []
var PathIndex = 0
var velocity = Vector3()
var x = 0
var FootPoint


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

##########################
#         CHASE          #
##########################
func chase():
	if player.is_on_floor():
		if !chasing:
			path = gridmap.GetPath(translation,player.translation)

			#print(path)
			if path.size() > 0:
				#tween.interpolate_property(self,"translation", translation,path[PathIndex],0.2,Tween.TRANS_LINEAR,0)
				#tween.start()
				#chasing = true
				PathIndex = 0


func TweenStarted(object,key):
	pass
	#print("Tweening Started!")


##########################
#   CHECK PATH PROGRESS  #
##########################
func CheckPathProgress():
	#prints("Distance to target point: ",abs(translation.distance_to(path[PathIndex])), " Within arrival radius: ", translation.distance_to(path[PathIndex]) < ArrivalRadius)
	if path.size() > 0:
		if abs(translation.distance_to(path[PathIndex])) < ArrivalRadius:
			if PathIndex == path.size()-1:
				path = gridmap.GetPath(translation,player.translation)
				#prints("Generated new path: ", path)
				PathIndex = 0
				if path.size() == 0:
					return
				TargetPoint = path[0]
			else:
				PathIndex += 1
				TargetPoint = path[PathIndex]
	else:
		path = gridmap.GetPath(translation,player.translation)
		#prints("Generated new path: ", path)
		if path.size() == 0:
			return
		PathIndex = 0
		TargetPoint = path[0]


##########################
#						 #
# 	STEERING BEHAVIORS	 #
#						 #
##########################

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
	CheckPathProgress()
	#seeking = true
	#var MASS = 1.0
	#var ARRIVE_DISTANCE = 1.0
	var desired_velocity = (TargetPoint - translation)#.normalized() * SPEED
	#var dist = desired_velocity.length()
	desired_velocity = desired_velocity.normalized()
	var steering = desired_velocity - velocity
	#velocity += steering / MASS
	var tempVel = (velocity + steering).normalized()
	var lookDir = Vector3(lerp(sin(rotation.y), -tempVel.x, get_process_delta_time()), 0, lerp(cos(rotation.y), -tempVel.z,get_process_delta_time()))
	var angle = atan2(lookDir.x,lookDir.z)
	rotation = Vector3(rotation.x, angle,rotation.z)
	var velModulate = -lookDir/desired_velocity
	if velModulate.x < 0: velModulate.x = 0
	if velModulate.z < 0: velModulate.z = 0
	tempVel = tempVel * velModulate 
	#steering = truncate(steering, SPEED)
	#steering = steering/MASS
	velocity = truncate(velocity + steering, SPEED)

	move_and_slide( velocity * get_process_delta_time() )
	#rotation = Vector3(0,Vector2(velocity.x,velocity.z).angle(),0)
	#return translation.distance_to(TargetPoint) < ARRIVE_DISTANCE


##########################
#          FLEE          #
##########################
func flee():
	pass


##########################
#         PURSUE         #
##########################
func pursue():
	pass


##########################
#         EVADE          #
##########################
func evade():
	pass


##########################
#         WANDER         #
##########################
func wander():
	pass


##########################
#         ATTACK         #
##########################
func attack():
	pass


##########################
#         BLOCK          #
##########################
func block():
	pass


##########################
#  INCREMENT PATH INDEX  #
##########################
func IncrementPathIndex(object,key):
	#print("Tweening Finished!")
	if path.size() > 0: # if path index has not yet reached the end of the path.
		PathIndex += 1
	
	if PathIndex == path.size()-1: # if enemy has reached the end of it's path, calculate a new one to the player
		#chasing   = false
		#chase()
		path = gridmap.GetPath(translation,player.translation)
		prints("Generated new path: ", path)
		if path.size():
			PathIndex = 0
			TargetPoint = path[PathIndex]


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
	#path = gridmap.GetPath(translation,player.translation)
	prints("Generated first path: ", path)
	#TargetPoint = path[0]
	prints("Target Point: ", TargetPoint)

func _physics_process(delta):
	pass
	#FootPoint = get_node("RayCast").get_collision_point()
	#if following:
	#	TargetPoint = path[PathIndex]
	#	if translation.distance_to(TargetPoint) < ArrivalRadius:
	#		print("Incrementing Path ", TargetPoint)
	#		IncrementPathIndex(null,null)
	#if !chasing:
	#	chase()


func _process(delta):
	BehaviorTree.tick(self, Blackboard)

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


