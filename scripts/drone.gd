extends KinematicBody

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export(String) var drone_name

#movement stuff
var gravity : Vector3 = Vector3.DOWN * 12.0
export(float) var speed = 5.0
export(float) var max_speed = 10.0
const Accel = 0.5
const Deaccel = 16

const max_slope_angle = 50

var velocity = Vector3()

export(float) var turn_speed = 1.25

#ball stuff
onready var _ball = preload("res://scenes/ball.tscn")
export(float) var fire_wait_time = 0.5 # Seconds
var can_fire = true
var ball_index = 0

#Declare player data here.
export(String, "red", "orange", "yellow", "green", "blue", "violet") var player_color = "yellow"
export(String, "white", "black") var outline_color = "black"
export(float) var _health = 5.0
onready var health = _health
var kills = 0
export(float) var respawn_time = 5
var flags = {}
var round_ended = false

var colors = {
	"red"    : Color("ff0000"),
	"orange" : Color("ff6600"),
	"yellow" : Color("ffff00"),
	"green"  : Color("00cc00"),
	"blue"   : Color("0000cc"),
	"violet" : Color("cc00cc"),
	"white"  : Color("ffffff"),
	"black"  : Color("000000")
	}

const is_drone = true

# Set the colors of the player(called by gamestate)
func set_colors(body, outline):
	player_color = body
	outline_color = outline
	for i in $rotation_helper/faces.get_children():
		if i.name != outline: i.hide()
		else: i.show()
	for j in $outlines.get_children():
		if j.name != outline: j.hide()
		else: j.show()
	for k in $bodies.get_children():
		if k.name != body: k.hide()
		else: k.show()

func die(killer):
	#prints(self, " was killed by: ", killer)
	#if killer._get("kills") != null:
	killer.kills += 1
	get_tree().get_root().get_node("/root/gamestate").count_kills()
	hide()
	$BehaviorTree.enabled     = false
	$CollisionShape.disabled  = true
	$CollisionShape2.disabled = true
	$Timer.connect("timeout", self, "_on_respawn_timer_timeout")
	$Timer.one_shot = true
	$Timer.start(respawn_time)

func spawn(transform):
	health = _health
	global_transform = transform
	show()
	$BehaviorTree.enabled     = true
	$CollisionShape.disabled  = false
	$CollisionShape2.disabled = false
	

func damage(by_who, damage):
	health -= damage
	#prints(self, " damaged by ", by_who, " Health: ", health)
	if health <= 0:
		die(by_who)

# Called when the node enters the scene tree for the first time.
func _ready():
	gamestate.connect("round_ended", self, "end_of_round")
	get_node("PlayerName/label").set_text(drone_name)
	set_colors(player_color, outline_color)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !round_ended:
		$BehaviorTree._tick()
	pass

func _on_respawn_timer_timeout():
	get_tree().get_root().get_node("/root/gamestate").respawn(self)
	pass

func _on_outlineTimer_timeout():
	$outlines.show()
	pass # Replace with function body.

func end_of_round(winner):
	round_ended = true
