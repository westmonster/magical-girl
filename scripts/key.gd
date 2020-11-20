extends Area

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export(String)	var KeyName = "white"
export(bool)	var pickup	= true
export(int)		var numkeys = 1
var currentAnimation = "idle"
var animations = ["idle","sparkle"]

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	if pickup:
		get_node("AnimationPlayer").play(currentAnimation)
	
	set_physics_process(true)
	pass

func _physics_process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	get_node("MeshInstance").rotation = Vector3(0,float(OS.get_ticks_msec())/500,0)
	get_node("MeshInstance").translation = Vector3(0,sin(float(OS.get_ticks_msec())/500)/10,0)
	if !get_node("AnimationPlayer").is_playing() and pickup:
		currentAnimation = "idle"
		get_node("AnimationPlayer").play(currentAnimation)
		#get_node("AnimationPlayer").playback_speed = 1
		
	pass

func UseFunction(user):
	pass


func KeyName():
	return KeyName

func pickup():
	return pickup

func sparkle():
	#print("*Sparkling!*")
	if currentAnimation != "sparkle":
		currentAnimation = "sparkle"
		get_node("AnimationPlayer").play(currentAnimation)
		

func _on_key_area_entered(area):
	#print(area)
	if area.name == "lookTest":
		#if currentAnimation != "sparkle":
		currentAnimation = "sparkle"
		if get_node("AnimationPlayer").current_animation == "idle":
			get_node("AnimationPlayer").play(currentAnimation)


func _on_key_area_exited(area):
	if area.name == "lookTest":
		#if currentAnimation != "idle":
		currentAnimation = "idle"
		if !get_node("AnimationPlayer").is_playing():
			get_node("AnimationPlayer").play(currentAnimation)


func _on_key_body_entered(body):
	#prints("something something ", KeyName, " key")
	if body is preload("res://scripts/Player0.gd"):
		#prints(KeyName, " key picked up.")
		get_node("AnimationPlayer").stop()
		get_node("AudioStreamPlayer").play()
		translation = Vector3(0,-1,0)
		body.AddKeys(KeyName, numkeys)
		hide()



func _on_AudioStreamPlayer_finished():
	queue_free()
