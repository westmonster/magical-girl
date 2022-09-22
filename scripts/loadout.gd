extends Spatial

var Pressed_fire = false
export(NodePath) var Owner
# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const RED = 0
const GRN = 1
const BLU = 2

export(int, "Red", "Green", "Blue") var current_wand
var _current_wand


# Called when the node enters the scene tree for the first time.
func _ready():
	_current_wand = "weapons/magicalGirlWand%s" % current_wand
	cycle_wand(current_wand)
	
	# NOTE: not sure what the following did but there's no hint of the functions or signals anymore
#	for i in $weapons.get_children():
#		i.connect("current_state", get_node(Owner), "change_state")
#		prints("Connected node: ", i, " to ", get_node(Owner))
#	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	#####################################
	#		SHOOTING & MELEE			#
	#####################################
	if(Input.is_action_pressed("Player_PrimaryAction")):
		if(get_node(_current_wand).has_method("Action")):
			#prints("Fired!")
			#prints("Owner: ", get_node(Owner))
			get_node(_current_wand).Action(Owner)
	
	if(Input.is_action_just_released("Player_PrimaryAction")):
		pass
	
	
	if(Input.is_action_just_pressed("Player_SecondaryAction")):
		if(get_node(_current_wand).has_method("SecondaryAction")):
			get_node(_current_wand).SecondaryAction(Owner)
	
	if(Input.is_action_just_released("Player_SecondaryAction")):
		pass
	

func cycle_wand(wand_color):
	current_wand = wand_color
	match wand_color:
		RED:
			$weapons/magicalGirlWand0.show()
			$weapons/magicalGirlWand1.hide()
			$weapons/magicalGirlWand2.hide()
			_current_wand = "weapons/magicalGirlWand0"
			
		GRN:
			$weapons/magicalGirlWand0.hide()
			$weapons/magicalGirlWand1.show()
			$weapons/magicalGirlWand2.hide()
			_current_wand = "weapons/magicalGirlWand1"
			
		BLU:
			$weapons/magicalGirlWand0.hide()
			$weapons/magicalGirlWand1.hide()
			$weapons/magicalGirlWand2.show()
			_current_wand = "weapons/magicalGirlWand2"
