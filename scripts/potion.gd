extends Area

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export(bool)	var pickup	= true
var currentAnimation = "idle"
var animations = ["idle","sparkle"]

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here

	set_physics_process(true)
	pass

func _physics_process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	get_node("MeshInstance").rotation = Vector3(0,float(OS.get_ticks_msec())/500,0)
	get_node("MeshInstance").translation = Vector3(0,sin(float(OS.get_ticks_msec())/500)/10,0)

	pass

func UseFunction(user):
	pass

func pick_up():
	translation = Vector3(0,-1,0)
	#queue_free()


func pickup():
	return pickup


func TakeDamage(dmg, weapon):
	# ToDo: implement potion "grenade" effect.
	#print("wtf potions")
	queue_free()

func _on_potion_body_entered(body):
	#print("something something potion.")
	if body is preload("res://scripts/Player0.gd"):
		#print("Adding potion")
		get_node("AudioStreamPlayer").play()
		body.AddPotions(1)
		hide()


func _on_AudioStreamPlayer_finished():
	queue_free()
