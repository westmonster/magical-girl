extends Spatial


export(NodePath) var	Owner
var						busy	= false
onready	var				tween	= get_node("Tween")
var						active	= false

func _ready():
	pass


func PlayIdle():
	get_node("AnimationPlayer").play("idle")

func TakeDamage(damage,weapon):
	#print("Blocking weapon")
	if active:
		weapon.BlockAttack()

func NPC_Action():
	Action()
	get_node("Timer").start()

func Action():
	#print("raising")
	tween.interpolate_property(get_node("col"),"translation", get_node("col").translation, Vector3(-0.25,-0.225,0.15), 0.2,Tween.TRANS_LINEAR,0)
	tween.start()
	active = true

func UnAction():
	#print("lowering")
	tween.interpolate_property(get_node("col"),"translation", get_node("col").translation, Vector3(0,-0.325,0.15), 0.2,Tween.TRANS_LINEAR,0)
	tween.start()
	active = false

func _on_Tween_tween_started(object, key):
	pass
	#print("starting tween")


#func _on_Tween_tween_completed(object, key):
	#print("finished tween")

func _on_Timer_timeout():
	UnAction()
