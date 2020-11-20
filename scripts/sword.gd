extends Spatial

# class member variables go here, for example:
export(int) var			damage 			= 10
export(int) var			windupSpeed 	= 1000
export(int) var			stabSpeed 		= 1500
export(int) var			hSlash_L2RSpeed = 1500
export(int) var			hSlash_R2LSpeed = 1500
export(int) var			vSlash 			= 1500
export(NodePath) var	Owner
export(bool)	 var	is_NPC			= false
var						attack			= false
var						swingAngle		= 0
var						attackID		= 0
var						attackBlocked	= false
var						busy			= false
var						hitBodies		= Array()
var						CurrentAttack
var						MouseRelative
onready var				tween 			= get_node("Tween")
var						attackList		= ["stab", "hSlash_L2R", "hSlash_R2L", "vSlash"]
export(bool) var		dynamicCombat	= false
export(bool) var		isBarbarian		= false
export(float) var		AnimationPlaybackSpeed = 1.0
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	set_physics_process(true)
	if dynamicCombat:
		set_process_input(true)
	
	get_node("AnimationPlayer").play("idle")
	#if !dynamicCombat and !is_NPC:
	get_node("AnimationPlayer").playback_speed = AnimationPlaybackSpeed

func _physics_process(delta):
	if !get_node("AnimationPlayer").is_playing():
		get_node("AnimationPlayer").play("idle")
	#if attack:
	#	var bodies = get_node("col").get_overlapping_bodies()
	#	for i in bodies:
	#		var skip = false
	#		for j in hitBodies:
	#			if j == i: 
	#				skip = true
	#		if !skip: i.TakeDamage(damage)
		
	

func _input(event):
	if(event is InputEventMouseMotion):
		MouseRelative = event.relative
	else:
		MouseRelative = Vector2(0,0)
	swingAngle = atan2(MouseRelative.y, MouseRelative.x)
		

func Fire():
	#print(Owner)
	if get_node(Owner).has_method("Fire"):
		get_node(Owner).Fire()

func Action():
	if !busy:
		if isBarbarian:
			#print("starting attack, swingtesting")
			SwingTest()
			#print("swingTest Complete")
			Attack()
		else:
			get_node("AnimationPlayer").play("windUp")
		
		busy = true;

func Attack():
	attack = true
	#attackID += 1
	#var attacks = ["hSlash_R2L","hSlash_L2R","vSlash","stab"]
	#var rnd = randi()%4
	get_node("AnimationPlayer").play(CurrentAttack)

func SwingTest():
	#var mrev = InputEventMouseMotion.relative
	#if(MouseRelative == Vector2(0,0)):
	if is_NPC or !dynamicCombat:
		if attack:
			#print("not attacking")
			return
		CurrentAttack = attackList[randi()%4]
		#print(CurrentAttack)
	else:
		CurrentAttack = "stab"
		if( abs(MouseRelative.x)>abs(MouseRelative.y)):
			if(MouseRelative.x > 0):
				CurrentAttack = "hSlash_L2R"
				rotation = Vector3(0,0,-swingAngle)
			else:
				CurrentAttack = "hSlash_R2L"
				rotation = Vector3(0,0,-swingAngle-135)
				
		if( abs(MouseRelative.y)>abs(MouseRelative.x)):
			if(MouseRelative.y > 0):
				CurrentAttack = "vSlash"
				rotation = Vector3(0,0,-swingAngle-67.5)
			else:
				CurrentAttack = "stab"
	Attack()
	

func NotBusy():
	busy = false
	#print(rotation)
	#tween.interpolate_property(self,"rotation", rotation, Vector3(0,0,0), 0.2,Tween.TRANS_LINEAR,0)
	#tween.start()

func NotAttacking():
	attack = false
	#busy = false
	attackBlocked = false
	

func PlayIdle():
	get_node("AnimationPlayer").play("idle")

func BlockAttack():
	#print("Being blocked")
	attackBlocked = true
	busy = true
	get_node("AnimationPlayer").play("blocked")

func _on_col_body_entered(body):
	if body != get_node(Owner):
		if attack and !attackBlocked:
			if( body.has_method("TakeDamage")):
				if is_NPC:
					if body == get_tree().get_root().get_node("world/entities/Player"):
						body.TakeDamage(damage,self)
				else:
					body.TakeDamage(damage,self)
				#print(attackBlocked)

func _on_col_area_entered(area):
	#print("area entered")
	#if area.has_method("Owner"):
	if "Owner" in area.get_parent():
		if area.get_parent().Owner != Owner:
			if attack and !attackBlocked:
				#print("attack")
				if( area.get_parent().has_method("TakeDamage")):
					area.get_parent().TakeDamage(damage,self)
	else:
		if area.has_method("pickup"):
			if attack and !attackBlocked:
				if area.has_method("TakeDamage"):
					area.TakeDamage(damage,self)
					#print("damaging")
					#print(attackBlocked)


