extends KinematicBody

# IMPORTANT NODES
onready var player = get_tree().get_root().get_node("world/entities/Player")
var weapon
var shield
onready var tween  = get_node("Tween")

var m = SpatialMaterial.new()

# STATES
var following	= true
var chasing		= true
var seeking		= false
var fleeing		= false
var pursuing	= false
var evading		= false
var wandering	= false

export var Health = 30
export(int) var points = 10
export(float) var SPEED = 300.0

var generator
var target
var lastTargetPos
onready var Target_Point = translation
export(float) var Arrival_Radius = 1.5
export var Low_Health	 = 5

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

func get_target_point():
	#if has_line_of_sight():
	if target == player:
		Target_Point = target.FootPoint
	else:
		Target_Point = target.translation
	return Target_Point
	#	Target_Point = lastTargetPos


func die():
	if generator.get_ref():
		generator.get_ref().maxSpawnable += 1
	self.queue_free()


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
	Health-=dmg

	if Health <= 0:
		weapon.get_node(weapon.Owner).ChangeScore(points)
		die()

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	#set_physics_process(true)
	#set_physics_process(true)

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



