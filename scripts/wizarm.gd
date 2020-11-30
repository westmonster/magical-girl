extends Spatial

# class member variables go here, for example:
export(int) var			damage 			= 10
export(float) var		refactory_time	= 0.07
export(float) var		second_ref_time	= 0.44
export(NodePath) var	loadout_path
export(PackedScene) var	petal
export(bool)	 var	is_NPC				= false
export(bool)	 var	primaryPlayAudio	= false
export(bool)	 var	secondaryPlayAudio	= false
var						attack			= false
var						swingAngle		= 0
var						attackID		= 0
var						attackBlocked	= false
var						busy			= false
var						hitBodies		= Array()
var						dynamicCombat	= false
var _delta
var is_firing = false
var is_secondary = false

const RED = 0
const GRN = 1
const BLU = 2
export(int, "Red", "Green", "Blue") var current_color
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_physics_process(true)
	$AnimationPlayer.set_blend_time("idle", "fire", 0.125)
	cycle_wand(current_color)
	$Timer.wait_time = refactory_time
	$secondaryTimer.wait_time = second_ref_time
	#set_process_input(true)

	#if !dynamicCombat and !is_NPC:
	#	get_node("AnimationPlayer").playback_speed = 1.5

func _physics_process(delta):
	_delta = delta
	if !get_node("AnimationPlayer").is_playing():
		get_node("AnimationPlayer").play("idle")
	
	if !busy: 
		if($muzzle/muzzle.rotation.x > 0):
			$muzzle/muzzle.rotate_x(delta/-12)
		if($muzzle/muzzle.rotation.x < 0):
			$muzzle/muzzle.rotation.x = 0
	pass
	#if attack:
	#	var bodies = get_node("col").get_overlapping_bodies()
	#	for i in bodies:
	#		var skip = false
	#		for j in hitBodies:
	#			if j == i:
	#				skip = true
	#		if !skip: i.TakeDamage(damage)



func Fire(_owner):
	match current_color:
		RED:
			pass
		GRN:
			var prj = petal.instance()
			prj.global_transform = $muzzle/muzzle.global_transform
			prj.Owner = _owner
			var __owner = get_node(loadout_path).get_node(_owner)
			prj.fire(-$muzzle/muzzle.global_transform.basis.z.normalized(), __owner.velocity )
			#print(prj)
			get_tree().get_root().get_node("world/projectiles").add_child(prj)
			$muzzle/muzzle.rotate_x(_delta/25)
				#print(get_node("Camera_Main/loadout/muzzle/Muzzle").rotation.x)
			if $muzzle/muzzle.rotation.x > 0.25:
				$muzzle/muzzle.rotation.x = 0.25
			$muzzle.rotate_z(_delta*10)
			pass
		BLU:
			for x in range(8):
				var prj = petal.instance()
				prj.Owner = _owner
				var __owner = get_node(loadout_path).get_node(_owner)
				$muzzle/muzzle.rotation.x = randf() * 0.15
				$muzzle.rotation.z = randf() * PI * 2
				prj.global_transform = $muzzle/muzzle.global_transform
				prj.fire(-$muzzle/muzzle.global_transform.basis.z.normalized(), __owner.velocity )
				#print(prj)
				get_tree().get_root().get_node("world/projectiles").add_child(prj)
			pass


func Action(_owner):
	#print(busy)
	if !busy:
		#prints("Firing!")
		$AnimationPlayer.seek(0.0,true)
		$AnimationPlayer.play("fire")
		if primaryPlayAudio:
			#get_node("AudioStreamPlayer").pitch_scale = rand_range(0.95,1.15)
			$AudioStreamPlayer.play()
		busy = true
		attack = true
		$Timer.start()
		Fire(_owner)
	is_firing = true

func SecondaryAction(_owner):
	#print(busy)
	if !busy:
		$AnimationPlayer.seek(0.0,true)
		$AnimationPlayer.play("secondaryFire")
		if secondaryPlayAudio:
			#get_node("AudioStreamPlayer").pitch_scale = rand_range(0.95,1.15)
			$AudioStreamPlayer.play()
		busy = true
		attack = true
		$secondaryTimer.start()
		#Fire()
	is_secondary = true

func playAnimation(anim):
	if not busy and not attack:
		if get_node("AnimationPlayer").current_animation == anim and !get_node("AnimationPlayer").is_playing():
			get_node("AnimationPlayer").play(anim)
		if get_node("AnimationPlayer").current_animation != anim:
			get_node("AnimationPlayer").play(anim)

func NotAttacking():
	#prints("done firing!")
	busy = false
	attack = false
	attackBlocked = false
	pass 

func cycle_wand(wand_color):
	current_color = wand_color
	match wand_color:
		RED:
			$wand/wand_RED.show()
			$wand/wand_GRN.hide()
			$wand/wand_BLU.hide()
			pass
		GRN:
			$wand/wand_RED.hide()
			$wand/wand_GRN.show()
			$wand/wand_BLU.hide()
			pass
		BLU:
			$wand/wand_RED.hide()
			$wand/wand_GRN.hide()
			$wand/wand_BLU.show()
			pass


func _on_Timer_timeout():
	#prints("done firing!")
	NotAttacking()
	pass # Replace with function body.


func _on_secondaryTimer_timeout():
	NotAttacking()
	pass # Replace with function body.
