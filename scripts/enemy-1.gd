extends KinematicBody

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export(float) var SPEED = 10.0
onready var BehaviorTree = get_node("BehaviorTree")
onready var Blackboard   = get_node("BehaviorBlackboard")
onready var tween = get_node("Tween")

# STATES
var following	= true
var chasing		= false
var seeking		= false
var fleeing		= false
var pursuing	= false
var evading		= false
var wandering	= false


var target
onready var TargetPoint = translation
var ArrivalRadius = 0.5
var path = []
var PathIndex = 0
var velocity = Vector3()
var x = 0
var FootPoint


##########################
#         CHASE          #
##########################
func chase():
	if get_node("../../player/Player").is_on_floor():
		if !chasing:
			path = get_node("../../../GridMap").GetPath(translation,get_node("../../player/Player").translation)

			#print(path)
			if path.size() > 0:
				tween.interpolate_property(self,"translation", translation,path[PathIndex],0.2,Tween.TRANS_LINEAR,0)
				tween.start()
				chasing = true
				PathIndex = 0


##########################
#    CREATE NAV PATH     #
##########################
func CreateNavPath():
	if get_node("../../player/Player").is_on_floor():
		path = get_node("../../../GridMap").GetPath(translation,get_node("../../player/Player").translation)
		#print(path)
		if path.size():
			chasing = true
			PathIndex = 0
			TargetPoint = path[PathIndex]


func TweenStarted(object,key):
	pass
	#print("Tweening Started!")


##########################
#          IDLE          #
##########################

func idle():
	var following	= false
	var chasing		= false
	var seeking		= false
	var fleeing		= false
	var pursuing	= false
	var evading		= false
	var wandering	= false

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
#          SEEK          #
##########################
func seek():
	#seeking = true
	var MASS = 1.0
	var ARRIVE_DISTANCE = 1.0
	var desired_velocity = (TargetPoint - translation)#.normalized() * SPEED
	var dist = desired_velocity.length()
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
	if path.size() > 0:
		PathIndex += 1
	if PathIndex < path.size()-1: # if enemy hasn't finished the path, move on to tweening toward the next node
		tween.interpolate_property(self,"translation", translation,path[PathIndex],1,Tween.TRANS_LINEAR,Tween.EASE_IN,0)
		tween.start()
	if PathIndex == path.size()-1: # if enemy has reached the end of it's path, calculate a new one to the player
		chasing   = false
		#chase()
		path = get_node("../../../GridMap").GetPath(translation,get_node("../../player/Player").translation)
		if path.size() > 0:
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
	set_physics_process(true)
	set_process(true)
	#tween.connect("tween_completed",self,"IncrementPathIndex")
	#tween.connect("tween_started",self,"TweenStarted")
	#tween.start()
	path = get_node("../../../GridMap").GetPath(translation,get_node("../../player/Player").translation)
	TargetPoint = path[0]

func _physics_process(delta):
	#FootPoint = get_node("RayCast").get_collision_point()
	#if following:
	#	TargetPoaint = path[PathIndex]
	if translation.distance_to(TargetPoint) < ArrivalRadius:
		IncrementPathIndex(null,null)


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


