extends Area

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export(String)	var foodName = ""
export(int)		var healAmt = 100
export(bool)	var pickup	= true
var currentAnimation = "idle"

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
	get_tree().get_root().get_node("world/entities/Player").AddKeys(foodName, 1)

	queue_free()


func pickup():
	return pickup


func TakeDamage(dmg, weapon):
	queue_free()

func _on_food_body_entered(body):
	if body is preload("res://scripts/Player0.gd"):
	#if body == get_tree().get_root().get_node("world/entities/Player"):
		#print("Adding Food")
		body.ChangeHealth(healAmt)
		get_node("AudioStreamPlayer").play()
		hide()



func _on_AudioStreamPlayer_finished():
	queue_free()
