extends KinematicBody

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

var start_point
export(String)	var projectileName					= ""
export(float) 	var maxDistanceInUnits 		= 10.0
export(float) 	var speedInUnitsPerSecond	= 20.0
export(float)	var fallRate				= 0.0
export(int)		var damage					= 10
export(bool)	var damagePastBlade			= true
var Owner
var duration = maxDistanceInUnits/speedInUnitsPerSecond
var direction
var body
var velocity

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	#set_physics_process(true)
	pass
  
func _physics_process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	if is_on_ceiling() or is_on_floor() or is_on_wall():
#		kill()
#	pass
	look_at(get_viewport().get_camera().global_transform.origin,Vector3(0,1,0))

func fire(dir,vel):
	direction = dir#Vector3(sin(dir.y),-fallRate,cos(dir.y))
	start_point = translation
	get_node("AudioStreamPlayer").play()
	$projectile/AnimatedSprite3D.frame = randi() % 10
	#prints("direction ", dVec)
	#prints("velocity: ", vel.length())
	#velocity = Vector3(vel.x,vel.y,vel.z)#.length()+speedInUnitsPerSecond+5
	#prints((vel * 2 * clamp(direction.dot(vel.normalized()),0,1)))
	#velocity = (direction * speedInUnitsPerSecond) + (vel.project(direction))#(vel * 2 * clamp(vel.dot(direction),0,1))
	
	#I have tried many different ways to handle projectile movement
	#This is the way
	velocity = (direction * speedInUnitsPerSecond) + (vel.project(direction) * (clamp(direction.dot(vel),0,1)))
	
	#velocity = (direction * speedInUnitsPerSecond) + vel
	#velocity = (direction * speedInUnitsPerSecond) 
	#$Tween.interpolate_property(self,"translation",start_point,start_point + (dir*maxDistanceInUnits), duration, 0, 1, 0)
	#$Tween.connect("tween_completed",self, "kill")
	#$Tween.start()
	#prints("Fired bubble.")

func kill():
	#if body:
		#if !(body is preload("res://scripts/magicalGirl.gd")):
			queue_free()

func _on_projectile_body_entered(Body):
	body = Body
	if !(body is preload("res://scripts/magicalGirl.gd")):
		if body.has_method("TakeDamage"):
			if damagePastBlade:
				if translation.distance_to(start_point) > 1.35:
					body.TakeDamage(damage, self)
			else:
				body.TakeDamage(damage, self)
		kill()


func _on_Tween_tween_completed(object, key):
	kill()


func _on_projectile_area_entered(area):
	if area.has_method("TakeDamage"):
		area.TakeDamage(damage, self)

func smash():
	#get_node("projectile/CollisionShape").shape.radius = 8
	var bodies = get_node("potionCollision").get_overlapping_bodies()
	#prints("bodies: ", bodies)
	for i in bodies:
		prints("body: ", i)
		if i.has_method("take_damage"):
			prints("hurting: " , i)
			i.take_damage(damage, self)
	queue_free()
	pass
