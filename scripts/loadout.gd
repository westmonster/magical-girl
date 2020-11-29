extends Spatial

var Pressed_fire = false
export(NodePath) var Owner
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const GIRL_RED = 0
const GIRL_GRN = 1
const GIRL_BLU = 2


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	#####################################
	#		SHOOTING & MELEE			#
	#####################################
	if(Input.is_action_pressed("Player_PrimaryAction")):
		if($weapons.get_child(0).has_method("Action")):
			#prints("Fired!")
			#prints("Owner: ", get_node(Owner))
			$weapons.get_child(0).Action(Owner)
	
	if(Input.is_action_just_released("Player_PrimaryAction")):
		pass
	
	
	if(Input.is_action_just_pressed("Player_SecondaryAction")):
		if($weapons.get_child(0).has_method("SecondaryAction")):
			$weapons.get_child(0).SecondaryAction(Owner)
	
	if(Input.is_action_just_released("Player_SecondaryAction")):
		pass
	

func cycle_wand(wand_color):
	if($weapons.get_child(0).has_method("cycle_wand")):
			$weapons.get_child(0).cycle_wand(wand_color)
