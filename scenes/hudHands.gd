extends Spatial

onready var skeleton = get_node("HudHandsSkeleton")
var sk_chain_target_left
var sk_chain_target_right

func _ready():
	#sk_chain_target_left = skeleton.create_ik_chain(1,3)
	#sk_chain_target_right = skeleton.create_ik_chain(4,6)
	#set_process(true)
	pass

func _process(delta):
	#skeleton.change_chain_goal(sk_chain_target_left, get_node("../leftHand").get_child(0).get_node("col/handle"), true)
	#skeleton.solve_chain(sk_chain_target_left)
	
	#skeleton.change_chain_goal(sk_chain_target_right, get_node("../rightHand").get_child(0).get_node("col/handle"), true)
	#skeleton.solve_chain(sk_chain_target_right)
	pass
