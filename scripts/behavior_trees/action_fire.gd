#extends "res://scripts/drone.gd"
extends KinematicBody


onready var _ball = preload("res://scenes/ball.tscn")
var fire_timer = Timer.new()
var _root
var can_fire = true
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

func _ready():
	fire_timer.connect("timeout", self, "_on_fire_timer_timeout")
	add_child(fire_timer)

func _tick(root):
	_root = root
	#prints("Fire Tick: ", root)
	#if has_node("rotation_helper/muzzle"):
	if can_fire:
		fire()
		can_fire = false
		#fire_timer.one_shot = true
		fire_timer.start(root.fire_wait_time)
		return OK
	else:
		return FAILED
	pass

func _on_fire_timer_timeout():
	can_fire = true

func fire():
	#prints("Child nodes: ", get_children())
	var ball = _ball.instance()
	ball.set_name(_root.get_name() + str(_root.ball_index)) # Ensure unique name for the bomb
	ball.creator = _root
	ball.from_player = _root.get_tree().get_network_unique_id()
	ball.color = _root.player_color
	ball.outline = _root.outline_color
	for i in ball.get_node("color").get_children():
		if i.name == _root.player_color: i.show()
		else: i.hide()
	
	for j in ball.get_node("outline").get_children():
		if j.name == _root.outline_color: j.show()
		else: j.hide()
	
	# No need to set network mode to ball, will be owned by master by default
	_root.get_node("../..").add_child(ball)
	ball.set_global_transform(_root.get_node("rotation_helper/muzzle").global_transform)
	ball.start_point = ball.global_transform.origin
	_root.ball_index+=1
	_root.get_node("AudioStreamPlayer3D").play(0.0)
