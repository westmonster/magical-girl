extends Spatial

export(bool) var	TriggerOnce 	= false
export(bool) var	SpawnClosed		= true
export(bool) var	AutoOpen		= true
export(bool) var	Locked			= false
var					opened			= false
var					occupied		= false
export(float) var	TimeBeforeClose	= 2
export(int) var		RequiresKey		= 0
export(float) var	ActuateTime		= 1
onready var			tween			= get_node("Tween")
onready var			timer			= get_node("Timer")

func _ready():
	timer.wait_time = TimeBeforeClose
	#if Locked:
		#get_node("AnimationPlayer").play("setType")
		#get_node("AnimationPlayer").current_animation = "setType"
		#get_node("AnimationPlayer").seek(RequiresKey)
		#get_node("AnimationPlayer").playback_speed = 0
		#get_node("AnimationPlayer").stop(false)
	if SpawnClosed:
		Close()
	else:
		Open()

func UseFunction():
	if opened:
		Close()
	if !opened:
		Open()

func Open():
	tween.interpolate_property(get_node("col"),"translation", get_node("col").translation, Vector3(2,0,-0.5), ActuateTime,Tween.TRANS_LINEAR,0)
	tween.start()
	if !opened:
		get_node("col/open").play()
	opened = true
	timer.start()
	

func Close():
	if !Locked:
		if !occupied:
			tween.interpolate_property(get_node("col"),"translation", get_node("col").translation, Vector3(0,0,-0.5), ActuateTime,Tween.TRANS_LINEAR,0)
			tween.start()
			opened = false
			get_node("col/close").play()


func _on_trigger_body_entered(body):
	if body == get_tree().get_root().get_node("world/players/Player"):
		occupied = true
		#print(occupied)
		if Locked:
			match RequiresKey:
				3:
					if body.ylwKeys > 0:
						body.AddKeys( "yellow", -1)
						Locked = false
				2:
					if body.bluKeys > 0:
						body.AddKeys( "blue", -1)
						Locked = false
				1:
					if body.redKeys > 0:
						body.AddKeys( "red", -1)
						Locked = false
				0:
					if body.whtKeys > 0:
						body.AddKeys( "white", -1)
						Locked = false
		if !Locked:
			if(body!=get_node("col")):
				if AutoOpen:
					Open()

func _on_trigger_body_exited(body):
	occupied = false
	#print(occupied)
	if AutoOpen:
		if !TriggerOnce:
			Close()


func _on_Timer_timeout():
	#print("Timeout!")
	if !occupied:
		if !TriggerOnce:
			Close()
	else:
		timer.start()
