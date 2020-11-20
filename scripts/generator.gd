extends StaticBody

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export(bool) var active = true
export(int) var Health = 3
export(float) var regenIntervalInSeconds = 0.1
export(float) var retryIntervalInSeconds = 0.1
export(int)   var activationRadius		 = 15
export(int)   var radiusExpandAmount	 = 1
export(int)   var maxSpawnable			 = 8
export(PackedScene) var toGenerate
var spawnlist = []
var alive = true
onready var animator = get_node("AnimationPlayer")
onready var raycast = get_node("RayCast")
var raypos
onready var timer   = get_node("Timer")


func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	
	get_node("activateRadius/CollisionShape").shape.radius = activationRadius
	timer.wait_time = regenIntervalInSeconds
	raypos  = raycast.translation
	#set_process(true)

func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
	
	pass

func die():
	alive = false
	get_node("activateRadius/CollisionShape").disconnect("body_exited",self,"_on_activateRadius_body_exited")
	self.queue_free()

func TakeDamage(dmg, weapon):
	Health -= 1
	animator.current_animation = "damage"
	animator.seek(animator.current_animation_position + 0.5)
	if Health <= 0:
		die()
	pass

func generate():
	if maxSpawnable > 0:
		var tg = toGenerate.instance(0)
		raycast.cast_to = raycast.cast_to.rotated(Vector3(0,1,0),PI*0.25)
		tg.translation = raycast.cast_to + translation
		tg.target = get_tree().get_root().get_node("world/players/Player")
		tg.generator = weakref(self)
		tg.roll_rng()
		tg.stunned = false
		tg.get_node("AudioStreamPlayer3D").play()
		spawnlist.append(weakref(tg))
		get_tree().get_root().get_node("world/entities").add_child(tg)
		raycast.rotation = Vector3(0, raycast.rotation.y + (PI * 0.25), 0)
		maxSpawnable -= 1
		timer.wait_time = regenIntervalInSeconds

func _on_Timer_timeout():
	if raycast.is_colliding():
		var rayrot = raycast.rotation
		var i = 8
		for i in range(0,8):
			raycast.rotation = Vector3(rayrot.x, rayrot.y + (PI * 0.25), rayrot.z)
			raycast.force_raycast_update()
			if !raycast.is_colliding():
				generate()
				break
				
		timer.wait_time = retryIntervalInSeconds
	else:
		generate()
	
			
func activate():
	active = true
	timer.start()
	get_node("activateRadius/CollisionShape").shape.radius += radiusExpandAmount

func _on_activateRadius_body_entered(body):
	if active:
		if body == get_tree().get_root().get_node("world/players/Player"):
			activate()

func _on_activateRadius_body_exited(body):
	if body == get_tree().get_root().get_node("world/players/Player"):
		timer.stop()
		if alive:
			for i in spawnlist:
				if i.get_ref():
					i.get_ref().die()
			spawnlist.clear()
