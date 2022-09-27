#####################################################################################################
#											EXPLAIN													#
#####################################################################################################
# This is a first-person camera controller for Godot 3.x. Check the manual (documents/manual.pdf) or the Github wiki on how it's designed and used.
# This is the GitHub page: https://github.com/leiget/Godot_FPC_Base

#####################################################################################################
#											NOTES													#
#####################################################################################################
# - The collision safety margin must be set to around 0.01 for the player's kinematic body, or else things like walking up steps and such will not work correctly.
#	- You'll need to test it and find out what works whenever you change the size of the player's collision shape.
# - This script is made with the intent that the player's collision shape is a capsule.
# - Note that in Godot 3.0.2 the “move_and_slide()” function has 5 arguments, but in the latest GitHub version (as of March 07, 2018) it has 6, with
#	the added argument being in the 3rd position and is “bool infinite_inertia=true”. If this option is true, what it means is that no other object
#	can rotate the character. If false, it can if enough force is applied.

#########################
#		EXTENDS			#
#########################
# Extend the KinematicBody and all inherited node variables and functions to this script.
extends KinematicBody

##################################################
#					SETTINGS					 #
##################################################
#	CLASS		#
# What character the player is playing as
var playerClass
#	HEALTH		#
# How much time, in seconds the player has left
export var health = 2000
#	SCORE		#
# Current score
var score = 0
#	POTIONS		#
#	Number of Potions in inventory
var potions = 0
#	MOUSE LOOK	#
# This allows mouselooking. This is for just in case you need it.
export var MouseLook = true
# The sensitivity of the mouse movement applied to the character’s rotation.
export var Cam_RotateSens = 0.25

#	MOVEMENT	#
#The base walk speed.
export var BaseWalkVelocity = 10
#The speed of the character when pressing shift while moving.
export(float) var ShiftWalkVelocity_Multiplier =  2
# Max floor angle the character is able to walk on in radians.
export var MaxFloorAngleRad = 0.7
# Max floor angle normalized on the Y axis, for use in normal calculations.
var MaxFloorAngleNor_Y = cos(MaxFloorAngleRad)
# The normal which defines which way is up.
export var FloorNormal = Vector3(0,1,0)
# The maximum number of slides to calculate in "move_and_slide()".
export var MaxSlides = 4
# Variable used in "move_and_slide()".
# If the body is standing on a slope and the horizontal speed (relative to the floor’s speed)
#	goes below SlopeStopMinVel, the body will stop completely.
# When set to lower values, the body will not be able to stand still on steep slopes.
# This doesn't really work. I have my own code which makes sure that the character doesn't slide on
#	slopes. This is at the end of the "FALLING" section of the player movement in the "_physics_process()"
#	section. I basically just lower gravity on the character when he is moving or standing on a slope.
export var SlopeStopMinVel = 0.05

#	FALLING		#
# The gravity to be used on the character.
export var Falling_Gravity = 9.8
# The default gravity multiplier value for when standing still and for calculating the speed of walk on slopes.
#	0.25 is a good starting place for this character script.
export var Falling_Speed_Multiplier_Default = 0.25
# Terminal velocity, in m/s. #54 m/s is the rounded terminal velocity on Earth (with Earth's air density).
export var Falling_TerminalVel = 54
# The time it takes to hit terminal velocity. #14 seconds is the average time it takes to hit terminal velocity on Earth.
export var Falling_TimeToHitTerminalVelSec = 14

#	JUMPING		#
# The jump velocity relative to gravity.
export var Jump_Vel_RelativeToGrav = 1.55
# How long the jump is until its peak, when it then starts to fall gradually.
#	This is in seconds.
export var Jump_Length = 0.75

#	STEPPING UP		#
# The max step height that the player can step upon.
#	This must be less than half the size of the player.
#	This is because when stepping on a step, a raycast is shot up from the collision position to see if there
#	is anything in the way of the player stepping up the step.
#	If this height is more than half the height of the character, it will be set to half the height of the character.
#	This happens in the "_ready()" function.
export var Step_MaxHeight = 0.5
# The dividend for the step safety margin variable, below. This is also used in "_physics_process()" to alter the step safety margin
#	based on the speed of the character.
# Raise this number to make the player move higher up when stepping on a step.
export var Step_SafetyMargin_Dividend = 0.2
# The amount to move the ray cast away from the player to help detect steps more accurately.
export var Step_RaycastDistMultiplier = 1.1

#	CAMERA INTERPOLATION   #
# The multiplicand for the "CamInterpo_Length_Secs" variable below.
#	This is also used in the same way in "_physics_process()" so that when the player presses the "Shift" modifier action
#	the camera interpolation length will be altered to fit the speed of the character.
# Lower this number to make the camera interpolation speed slower.
var CamInterpo_Length_Secs_Multiplicand = 125.0

#	SLOPE	SPEED	#
# Amount to let slopes affect gravity of the player character, and therefore speed movement speed when walking up them.
# Default is 0.2.
export var Slope_EffectMultiplier_ClimbingUp = 0.2
# Amount to let slopes affect gravity of the player character, and therefore speed movement speed when walking down them.
# Default is 1.5.
export var Slope_EffectMultiplier_ClimbingDown = 1.5

#	USE ACTION		#
# The distance (in meters) the use button ray can go; the ray that looks for things that can be used.
export var Ray_UseDist = 2.0

#########################
#		DEFINES			#
#########################
# The crest factor in a handy variable.
# Check the documentation for an explanation.
#	It's nessecary to understand normals and how they work before moving on in this script.
#	The half crest factor, as far as 2D and 3D character movement and surface normals go, makes the velocity of the character correct when walking diagonally.
#		The way it works is this: imagine the player pressed both forward and right at the same time (in a 3D first-person game). He is facing forward/north in global
#		space. And let's say the base walk velocity is just 1. The final velocity without the crest factor taken into effect is (1.0, 0.0, -1.0) in Godot. This may
#		sound correct, but think about this: what is it when the player is facing exactly 45 degs clockwise, or NW, and he presses both forward and right?
#		The final walking velocity will be (1.4142, 0.0, 0.0). Wait, what? You see what's happening?
#	The character is facing NW, right? And the player presses forward, right? So the cahracter moves
const CrestFactor = 1.414213562373095

#########################
#		SIGNALS			#
#########################
# 	Render_Pos(Vector3)
# Signal for rendering any 3D position.
signal Render_Pos(Coll_Vec3)
# 	Coll_Sphere_Show(int, Vector3)
# Signal for showing collision slides from "move_and_slide()".
signal Coll_Sphere_Show(SlideNumber, Pos_Vec3)

#########################
#		NODES			#
#########################
# The 3D camera node.
onready var Node_Camera3D = get_node("Camera_Main")
# The "Crosshair_Usable" red circle node.
onready var Node_Crosshair_Useable = get_node("Camera2D/Crosshair/Crosshair_Useable")
#	Label	#
# The top-most label, for debugging.
onready var Debug_Label = get_node("Camera2D/DEBUG/Debug_Label")
# Label_01 print string.
var Debug_Label_String = "-------------------"
# The Health label.
onready var health_label = get_node("Camera2D/HUD/Panel/timer_icon/health")
# The Potion label.
onready var potion_label = get_node("Camera2D/HUD/Panel/potion_icon/Label")
# The White keys label.
onready var wht_keys_label = get_node("Camera2D/HUD/Panel/wht_key_icon/Label")
# The Red keys label.
onready var red_keys_label = get_node("Camera2D/HUD/Panel/red_key_icon/Label")
# The Blue keys label.
onready var blu_keys_label = get_node("Camera2D/HUD/Panel/blu_key_icon/Label")
# The Yellow keys label.
onready var ylw_keys_label = get_node("Camera2D/HUD/Panel/ylw_key_icon/Label")
# The Score count label
onready var score_label = get_node("Camera2D/HUD/Panel/Score/Label")
# The muzzle to shoot stuff
onready var muzzle		= get_node("Camera_Main/loadout/muzzle")
# The projectile to shoot from the muzzle
export(String, "arrow", "blade", "magic", "force") var Projectile	= "force"
var projectile
var potionProjectile = load("res://scenes/items/projectiles/potion_projectile.tscn")

#########################
#		STATES			#
#########################
# Is player on the floor?
var State_OnFloor = false
# Is player on one or more walls?
var State_OnWalls = false
# Is the player on hitting a ceiling?
var State_OnCeiling = false
# Is player falling?
var State_Falling = false
# Is the player jumping?
var State_Jumping = false
# Is the player pressing the movement keys in a diagonal way?
var State_Movement_Diagonal_Pressed = false

#########################################
#			GLOBAL VARIABLES			#
#########################################
# These are simply variables that are used in several different sections of the code, instead of, say, only being used for jumping.
# The global position of the player.
var Player_Position = Vector3(0,0,0)
# The height of the player collision shape.
# "onready" makes sure that it will only run this line when it actually can, without causing errors.
onready var Player_Height = (get_node("CollisionShape").shape.height + get_node("CollisionShape").shape.radius * 2)
# The global Y position of the feet of the player, for stepping up steps.
onready var Player_GlobalFeetPos_Y = Player_Position.y - Player_Height/2

#########################
#		  INPUT     	#
#########################
# The input names in string format.
var String_FW = "Player_FW"
var String_BW = "Player_BW"
var String_Left = "Player_Left"
var String_Right = "Player_Right"
var String_Jump = "Player_Jump"
var String_Use = "Player_Use"
var String_Shift = "Player_Shift"
# Bools for what keys are pressed or released.
var Pressed_FW = false
var Pressed_BW = false
var Pressed_LEFT = false
var Pressed_RIGHT = false
var Pressed_Jump = false
var Pressed_Shift = false

#########################
#		MOVEMENT		#
#########################
# This holds the slide count. Filled with whatever “get_slide_count()” returns.
var SlideCount = 0
# The 3D direction normals in 3D vectors. I.e. which way the player is facing in normalized vectors.
var DirectionInNormalVec3_FWAndBW = Vector3(0,0,0)
var DirectionInNormalVec3_LeftAndRight = Vector3(0,0,0)
# The temporary movement velocity vector.
#	These are used because you always want to calculate the character's movement velocity before you actually move them.
#	These are the temporary values that are used for all the calculations before you actually use them.
var TempMoveVel_FWAndBW = Vector3(0,0,0)
var TempMoveVel_LeftAndRight = Vector3(0,0,0)
# FinalWalkVelocity is used when the player presses shift to move faster.
#	This line below simply initializes it as the regular walking velocity,
#	just in case not having it specified causes an issue.
var FinalWalkVelocity = BaseWalkVelocity
# The final move velocity vector to be applied to the character.
var FinalMoveVel = Vector3(0,0,0)

#########################
#		ROTATION		#
#########################
# The bool that says to rotate the character because the mouse has been moved.
var Mouse_Moved = false
# The screen movement of the mouse on the X and Y axis.
#	This is using "relative mouse movement". That is, the mouse position relative to what it in the previous frame.
#	If the coursor was at (10,15) during the last frame, and now it's at (15,25), it has moved (5,10) pixels
#	on the X and Y axis.
var Mouse_Rel_Movement = Vector2(0,0)
# The rotation of the camera on it's local X axis, which rotates the camera up and down.
var Cam_Local_Rot_X = 0
# The final rotation amount to be applied to the camera.
var Final_Cam_Rot_Local_X = 0
# The temporary variable to store the X rotation to be applied, to see if the player is looking too far up or down
#	and then moving it back to the vertical(X-axis) roatation limits. That is, if the character is looking up
#	at more than a 90 degree angle, like he is bending backwards, move this amount to 90 degrees so the character
#	isn't looking backwards by rotating the camera too far vertically.
var Cam_Temp_XRot_Var = 0

#########################
#		FALLING    		#
#########################
# Has the falling of the player started?
var Falling_IsFalling = false
# Float passed to the FinalMoveVel; used for telling the engine how much to actually pull the character down.
# 	This is here because when an object falls it takes a little bit of time to reach terminal velocity.
# 	This variable slowly gets higher when falling. This is the _speed_ of the falling, not the falling itself.
#		That is, this number is always positive until it is used in the FinalMoveVel 3D vector.
#	The falling speed isn't linear. It's according to the power of 0.4. Look at line ???
var Falling_Speed = 0
# The multiplier of which modifies the final falling speed relative to gravity.
#	This is mainly for slopes and making the character move slower on them.
var Falling_Speed_Multiplier = 0.0
# How long the player has been falling.
var Falling_CurrentTime = 0

#########################
#		JUMPING			#
#########################
# The jump velocity, what it initially is until it falls off when the jump hits its peak.
var Jump_Vel = Falling_Gravity * Jump_Vel_RelativeToGrav
# Current velocity of the jump.
var Jump_CurrentVel = 0.0
# The current time of the jump in progress.
var Jump_CurrentTime = 0.0
# Bool to not let the player jump again until he releases the jump button.
#	That is, he can't keep holding the jump button down and jumping without
#	letting go of the jump button first.
var Jump_Released = true

#########################
#		SLOPE SPEED		#
#########################
# The players velocity on the x and z axis.
var Slope_PlayerVelVec2D = Vector2(0.0, 0.0)
# The floor normal on the x and z axis, to compare it to the player's velocity.
var Slope_FloorNor2D = Vector2(0.0, 0.0)
# A temporary variable that will be multiplied by "Slope_MagnitudeRatio" to get a normal.
#	That normal will be what the floor normal is on the x and z axis. (Just check the manual.)
var Slope_Magnitude = 0.0
# The ratio of what the normal is before and after converting the x and z axis into 2D.
var Slope_MagnitudeRatio = 0.0
# How different the player's velocity on the x and z axis are to the floor's same axis.
var Slope_DotProduct = 0.0

#########################
#			STEPS		#
#########################
# The additional amount that character has to move up when stepping up a step.
#	This helps keep the character from getting stuck moving up and down because he can't get quite enough
#	height to get over the step.
# It's set according to how fast the player is moving, so that the stepping of stairs is more correct.
var Step_SafetyMargin = Step_SafetyMargin_Dividend/BaseWalkVelocity
# Variable to say how high to move charater up, when stepping on step.
var SteppingUp_SteppingDistance = 0.0
# The step collision position.
var Step_CollPos = Vector3(0.0, 0.0, 0.0)
# The position of the collision of the step/wall relative to the player.
#	This is relative to the player because I need to make the collision test to be a bit farther away from
#	the player, and therefore deeper into the step, so as to make sure the ray cast downward from that postion
#	actually hits the step. I have found it unreliable to not do this.
var Step_CollPos_RelToPlayer = Vector3(0.0, 0.0, 0.0)
# The position of the player before he was moved up a step.
#	This is for camera interpolation.
#	I put it here because it is modified in the "Step_Player_Up()" function.
var Step_Cam_PosBefore_Global = 0.0
# The following are for making sure the player doesn't try to move up a step when he's too parallel to it,
#	thus causing him to move up and slide back down because he can't quite get on the step.
# The direction the player is moving, normalized.
var Step_PlayerVel_Global_Norm = Vector3(0,0,0)
# The slide collision relative to the player.
var Step_CollPos_Global_RelToPlayer = Vector3(0,0,0)
# The angle between the player and the slide collision.
var Step_CollPos_AngleToPlayer = 0.0

#############################
#	CAMERA STEP SMOOTHING	#
#############################
# How long it takes to interpolate the camera, in seconds.
#	Depends on how fast the player is moving.
#	The default length is 0.08 seconds, if BaseWalkVelocity is 10.
var CamInterpo_Length_Secs = BaseWalkVelocity / (CamInterpo_Length_Secs_Multiplicand * (BaseWalkVelocity/10.0))
# The bool to activate the interpolation of the camera on a step.
var CamInterpo_DoInterpolation = false
# The default value that the camera will interpolate to, in local space to the character.
#	This is set when placing the camera in the editor. It just gets the local position of the camera.
onready var CamInterpo_DefaultPosition_Local_Y = Node_Camera3D.get_transform().origin.y
# The local camera position before going up the step.
var CamInterpo_StartingPos_Local_Y = 0.0
# The current time of the interpolation, in seconds.
var CamInterpo_CurrentTime_Secs = 0.0

#########################
#		RAY CASTING 	#
#########################
#The state of the physical space in the game.
var Ray_SpaceState = null
# Holds where the ray will come from.
var Ray_From = Vector3(0.0, 0.0 ,0.0)
# Holds where the ray will go to.
var Ray_To = Vector3(0.0, 0.0 ,0.0)
# Will hold the result of any ray cast.
var Ray_Result = null

var FootPoint

#########################
#		INTERACTION		#
#########################
# Variables concerning interaction via the "Use" action or touch.
# The position of the "Use" buttons ray intersection.
var Use_Ray_IntersectPos = Vector3(0,0,0)
# A list of objects that have been touched recently that have touch functions.
var Touch_ObjectsTouched = []
# The list of slide collision, used to compare against the list of objects that have been touched, that also have a touch function.
var SlideCollisions = []


#########################
#       INVENTORY       #
#########################
var whtKeys = 0
var redKeys = 0
var bluKeys = 0
var ylwKeys = 0

######################################################################################################################################################
#															FUNCTIONS																			     #
######################################################################################################################################################

#############################################
# Fire ( )                                  #
#############################################

func Fire():
	var prj = projectile.instance()
	prj.global_transform = get_node("Camera_Main/loadout/muzzle").global_transform
	prj.Owner = "../../players/Player"
	prj.fire(rotation-Vector3(0,PI,0))
	prj.get_node("KinematicBody")
	#print(prj)
	get_tree().get_root().get_node("world/projectiles").add_child(prj)

#############################################
# ThrowPotion ( )                           #
#############################################

func ThrowPotion():
	if potions > 0:
		var prj = potionProjectile.instance()
		prj.global_transform = get_node("Camera_Main/loadout/muzzle").global_transform
		prj.Owner = "../../entities/Player"
		prj.fire(rotation-Vector3(0,PI,0))
		prj.get_node("KinematicBody")
		#print(prj)
		get_tree().get_root().get_node("world/projectiles").add_child(prj)
		AddPotions(-1)

#############################################
# AddPotions ( int )                        #
#############################################

func AddPotions(amount):
	#prints("Added 1 potion.")
	potions += amount
	potion_label.text = "%02d" % potions

#############################################
# ChangeScore ( int )                      #
#############################################

func ChangeScore(amount):
	score += amount
	score_label.text = "%010d" % score

#############################################
# ChangeHealth ( int )                      #
#############################################

func ChangeHealth(amount):
	#prints("Added ", amount, " health.")
	health += amount
	health_label.text = "%08d" % health
	if health < 0:
		get_tree().change_scene("res://scenes/UI/mainMenu.tscn")

#############################################
# AddKeys ( string, int )                   #
#############################################

func AddKeys( keyName, numKeys):
	if keyName == "white":
		whtKeys += numKeys
		wht_keys_label.text = "%03d" % whtKeys
	if keyName == "red":
		redKeys += numKeys
		red_keys_label.text = "%02d" % redKeys
	if keyName == "blue":
		bluKeys += numKeys
		blu_keys_label.text = "%02d" % bluKeys
	if keyName == "yellow":
		ylwKeys += numKeys
		ylw_keys_label.text = "%02d" % ylwKeys
	pass

#############################################
# TakeDamage ( int, obj )                   #
#############################################

func TakeDamage( damage, weapon ):
	var defense
	if playerClass == "barbarian":
		defense = 0.5
	if playerClass == "athenan":
		defense = 0.75
	if playerClass == "elf":
		defense = 1.25
	if playerClass == "wizard":
		defense = 1.15
	ChangeHealth(-(damage*defense))

#############################################
# InterpolateCamera( float, float, float )	#
#############################################
# Interpolates the camera and returns the relative time of the interpolation.
#	So, if the total length of the interpolation was 1.5 seconds, this function would return anything from 0.0 to 1.5.
func InterpolateCamera(Prev_Pos_Local_Y, Time_Current, Time_Delta):
	# If the current time is less than the length of time it takes to interpolate the camera....
	if(Time_Current < CamInterpo_Length_Secs):
		# Set the camera's local translation according to how far along the interpolation is.
		Node_Camera3D.translation.y = lerp(Prev_Pos_Local_Y, CamInterpo_DefaultPosition_Local_Y, Time_Current/CamInterpo_Length_Secs)
		# Increment the current time.
		Time_Current += Time_Delta
		# Return the current time for the next go around of this function.
		return Time_Current
	# Otherwise, if time is up and the camera is in it's final position...
	else:
		# Make sure to manually set the final Y position of the camera, just in case.
		Node_Camera3D.translation.y = CamInterpo_DefaultPosition_Local_Y
		# Turn off the camera interpolation.
		CamInterpo_DoInterpolation = false
		# Return 0 for success.
		return 0

########################
# Step_Player_Up(void) #
########################
# Steps the player up whenever there is a step under a certain height, which is "Step_MaxHeight" above in the settings section.
func Step_Player_Up():
	# Check to see if there are more than one collision slides in the first place...
	if(SlideCount > 1):
		# If the player is on the floor...
		if(State_OnFloor):
			# And if the player is on a wall...
			if(State_OnWalls):
				# Go through each of the collisions.
				for Slide in range(SlideCount):
					# If the slide collision is a wall...
					if(get_slide_collision(Slide).normal.y <= MaxFloorAngleNor_Y):
						# Get the position of the collision.
						Step_CollPos = get_slide_collision(Slide).position
						# Get the global Y position of the player's feet.
						#	Don't forget the safe margin of the character's physics body!
						Player_GlobalFeetPos_Y = Player_Position.y - (Player_Height / 2) - get("collision/safe_margin")

						# If the slide collision if higher than the player's feet...
						if(Player_GlobalFeetPos_Y < Step_CollPos.y):
							# Get the position of the collision relative to the player.
							Step_CollPos_RelToPlayer = to_local(Step_CollPos)

							# Get the direction that the player is actually moving, not the way he is facing.
							#	This currently only works when the floor vector is (0, -1, 0). Maybe in the future I will make
							#	this project to where the player can walk on walls. Probably not.
							Step_PlayerVel_Global_Norm = Vector3( Slope_PlayerVelVec2D.x , 0.0, Slope_PlayerVelVec2D.y )

							# Get the slide collision and make it relative to the player, in this variable.
							Step_CollPos_Global_RelToPlayer = Vector3(Step_CollPos.x, Player_Position.y, Step_CollPos.z) - Player_Position
							# Then normalize it so we can get an angle.
							Step_CollPos_Global_RelToPlayer = Step_CollPos_Global_RelToPlayer.normalized()

							# Now find the angle between the player's normalized movement velocity and the direction the collision is relative to the player.
							Step_CollPos_AngleToPlayer = abs(  asin(Step_CollPos_Global_RelToPlayer.dot(Step_PlayerVel_Global_Norm))  )

							# If the player isn't running parallel to the step (within a certain angle, which is 11.5 degress/0.200712864 rads)...
							if(Step_CollPos_AngleToPlayer > 0.200712864):
								# Add a little bit to where we will be checking the step normal, to make sure it
								#	is actually over the step. This is according to what direction the player is moving.
								Step_CollPos.x = to_global(Step_CollPos_RelToPlayer * Step_RaycastDistMultiplier).x
								Step_CollPos.y = Player_GlobalFeetPos_Y + Step_MaxHeight
								Step_CollPos.z = to_global(Step_CollPos_RelToPlayer * Step_RaycastDistMultiplier).z

								# Setup and execute a raycast at the collision position specified.
								Ray_SpaceState = get_world().get_direct_space_state()
								Ray_From = Vector3(Player_Position.x , Step_CollPos.y , Player_Position.z)
								Ray_To = Step_CollPos
								Ray_Result = Ray_SpaceState.intersect_ray(Ray_From,Ray_To,[self])

								# If there is nothing in the way of the character...
								#	This is here because, say there is a step that is partly above the ground. It's not touching. If the character walks into it,
								#	and it's within the step size threshold, this code will not allow the ray to be shot from within the step, causing it(the ray cast) to
								#	collide with the backside of the face, on the bottom of the step.
								if(Ray_Result.empty()):
									# Now we are going to shoot a ray from the collision position up to see if there is anything in the way.
									Ray_From = Step_CollPos
									Ray_To = Vector3(Step_CollPos.x, Player_Position.y, Step_CollPos.z)
									Ray_Result = Ray_SpaceState.intersect_ray(Ray_From,Ray_To,[self])

									# If there is nothing in the way above the collision point...
									if(Ray_Result.empty()):
										# Setup and execute a raycast at the collision position specified.
										Ray_From = Step_CollPos
										Ray_To = Vector3(Step_CollPos.x, Player_GlobalFeetPos_Y, Step_CollPos.z)
										Ray_Result = Ray_SpaceState.intersect_ray(Ray_From,Ray_To,[self])

										# If there is a result from the raycast that is not empty...
										if(not Ray_Result.empty()):
											# If the stepping distance has not been set, and the camera is not being interpolated from a previous step...
											if(SteppingUp_SteppingDistance == 0):
												# Get the position of the camera before it was stepped up, in global space.
												Step_Cam_PosBefore_Global = to_global(Node_Camera3D.translation)

												# Set the distance to move up in a variable.
												SteppingUp_SteppingDistance = (Ray_Result.position.y - Player_GlobalFeetPos_Y + Step_SafetyMargin)

												# Set the starting local Y axis position of the camera interpolation, which is simply where the camera was before it was moved up with the player.
												CamInterpo_StartingPos_Local_Y = to_local(Step_Cam_PosBefore_Global).y - SteppingUp_SteppingDistance

												# If the starting position is starting to fall below half of the player's height...
												if(CamInterpo_StartingPos_Local_Y < 0.0):
													# Set it to half the player's height (which is 0.0 in the "player.tscn" scene).
													CamInterpo_StartingPos_Local_Y = 0.0

												# Move the player up a little past the step.
												global_translate(Vector3(0.0, SteppingUp_SteppingDistance, 0.0))

												# Then set the local position of the camera node back down to where it was before moving.
												Node_Camera3D.translation.y = CamInterpo_StartingPos_Local_Y

												# Say to do interpolation.
												CamInterpo_DoInterpolation = true

												# Reset camera interpolation timer.
												CamInterpo_CurrentTime_Secs = 0

				# Reset the stepping distance to 0.
				SteppingUp_SteppingDistance = 0

###############################
# Touch_CheckAndExecute(void) #
###############################
# This function checks for and executes any "Touched_Function()" inside a colliding object script.
func Touch_CheckAndExecute():
	#If the player is on the floor, wall(s), or ceiling...
	if(State_OnFloor or State_OnWalls or State_OnCeiling):
		# If there are slide collisions...
		if(SlideCount > 0):
			# Loop through all the slides.
			for Slide in range(SlideCount):
				# If the current slide collider has a touch function...
				if(get_slide_collision(Slide).collider.has_method("Touched_Function")):
					# And if the list doesn't have the current collider with the touch function...
					if(not Touch_ObjectsTouched.has(get_slide_collision(Slide).collider)):
						# Add it to the list according to the slide number (I don't know if this will
						#	overwrite other elements in the array by using the Slide number as the index).
						Touch_ObjectsTouched[Slide] = get_slide_collision(Slide).collider
						# Then execute the touch function.
						Touch_ObjectsTouched[Slide].Touched_Function()

			# Clear the slide collision array.
			SlideCollisions.clear()
			# Then resize it to the maximum number of slides.
			SlideCollisions.resize(MaxSlides)

			# Loop through the slide collision array.
			for Index in range(SlideCollisions.size()):
				# If the current index number is less than the total slide count...
				if(Index < SlideCount):
					# Add the current slide to the slide collision array.
					SlideCollisions[Index] = get_slide_collision(Index).collider
				# Otherwise, if the current index is more than the number of slides...
				else:
					# Set the current element to null.
					SlideCollisions[Index] = null

			# Loop through touched object list.
			for Index in range(Touch_ObjectsTouched.size()):
				# If the current element isn't null...
				if(Touch_ObjectsTouched[Index] != null):
					# Check to see if the current touched object is in the slide collision list. If it isn't...
					if(not SlideCollisions.has(Touch_ObjectsTouched[Index])):
						# Get rid of it from the touched object list.
						Touch_ObjectsTouched[Index] = null

		# Otherwise, if there aren't slide collisions...
		else:
			# Cast a ray from the player's origin down to a little below his feet.
			Ray_SpaceState = get_world().get_direct_space_state()
			Ray_From = self.get_global_transform().origin
			Ray_To = Ray_From
			Ray_To.y -= ((Player_Height * 0.5) * 1.05)
			Ray_Result = Ray_SpaceState.intersect_ray(Ray_From,Ray_To,[self])

			# If there is something there...
			if(Ray_Result):
				# And if that thing has a touch function...
				if(Ray_Result.collider.has_method("Touched_Function")):
					#If the list doesn't have the current collider...
					if(not Touch_ObjectsTouched.has(Ray_Result.collider)):
						# Add it to the list at the first index.
						#	I hope that doesn't overwrite anything. So far, so good.
						Touch_ObjectsTouched[0] = Ray_Result.collider
						# Then execute that object's touch function.
						Touch_ObjectsTouched[0].Touched_Function()

			# Otherwise, if there isn't anything there...
			else:
				# Clear the slide collision array.
				SlideCollisions.clear()
				# Then resize it to the maximum number of slides.
				SlideCollisions.resize(MaxSlides)

				# Loop through the slide collision array.
				for Index in range(SlideCollisions.size()):
					# If the current index number is less than the total slide count...
					if(Index < SlideCount):
						# Add the current slide to the slide collision array.
						SlideCollisions[Index] = get_slide_collision(Index).collider
					# Otherwise, if the current index is more than the number of slides...
					else:
						# Set the current element to null.
						SlideCollisions[Index] = null

				# Loop through touched object list.
				for Index in range(Touch_ObjectsTouched.size()):
					# If the current element isn't null...
					if(Touch_ObjectsTouched[Index] != null):
						# Check to see if the current touched object is in the slide collision list. If it isn't...
						if(not SlideCollisions.has(Touch_ObjectsTouched[Index])):
							# Get rid of it from the touched object list.
							Touch_ObjectsTouched[Index] = null

###################################
# Slope_AffectSpeed(Slide_Number) #
###################################
# Makes the character walk more slowly up hills and faster down them.
# The character is not affected so much by gravity when walking parallel on the ramp.
func Slope_AffectSpeed():
	# If there is an actual slide collision...
	if(SlideCount > 0):
		# Check the slide collisions.
		for Slide in range(SlideCount):
			# If it is a floor...
			if(get_slide_collision(Slide).normal.y > MaxFloorAngleNor_Y):
				# The code in this section makes the character walk more slowly up hills and faster down them.
				#	It also makes the character not affected so much by gravity when walking parallel on the ramp.
				#	So if the character is walking from one side of the ramp to the other, the character isn't
				#	being pulled down so much.

				# Setup the X and Z axis of the floor normal as a 2D vector for calculations.
				Slope_FloorNor2D = Vector2(get_slide_collision(Slide).normal.x, get_slide_collision(Slide).normal.z)

				# Filter out any floor normal that is less than a certain threshold...
				#	This is here because a perfectly level floor will still have a normal of something very small.
				#	I don't know why this is. Probably a rounding error or something. Games can't have perfect accuracy, because
				#	it would slow things down too much if it did.
				# Maybe this isn't really needed?
				# If the floors y normal is straight up, practically speaking...
				if((abs(get_slide_collision(Slide).normal.y) >= 0.9999999)):
					# Make the floor normals 0.
					Slope_FloorNor2D = Vector2(0.0, 0.0)

				# If the player is moving the character diagonally...
				if(State_Movement_Diagonal_Pressed):
					# Setup the temporary player velocity vector, taking into account the crest factor.
					Slope_PlayerVelVec2D = Vector2(   (((TempMoveVel_FWAndBW.x / FinalWalkVelocity) + (TempMoveVel_LeftAndRight.x/FinalWalkVelocity)) / CrestFactor) ,
													  (((TempMoveVel_FWAndBW.z / FinalWalkVelocity) + (TempMoveVel_LeftAndRight.z/FinalWalkVelocity)) / CrestFactor)   )
				# Otherwise, he is not moving diagonally, so...
				else:
					# Setup the temporary velocity vector.
					Slope_PlayerVelVec2D = Vector2(((TempMoveVel_FWAndBW.x / FinalWalkVelocity) + (TempMoveVel_LeftAndRight.x/FinalWalkVelocity)) ,
											((TempMoveVel_FWAndBW.z / FinalWalkVelocity) + (TempMoveVel_LeftAndRight.z/FinalWalkVelocity)))

				# Find out the current magnitude of the x and z axis of the floor normal, so we can calculate it as if it were stand straight up (as if normal.y == 0.0)
				Slope_Magnitude = sqrt( pow( abs(Slope_FloorNor2D.x) , 2) + pow( abs(Slope_FloorNor2D.y) , 2))

				# If the magnitude of the slope isn't 0 (to avoid a "can't divide by 0" error)...
				if(Slope_Magnitude != 0):
					#Get the ratio that we need to multiply the shortened 2D vector by to get a full vector.
					Slope_MagnitudeRatio = 1/Slope_Magnitude
				# Otherwise, if the slope vector magnitude IS 0...
				else:
					# Just make the magnitude ratio 0.
					Slope_MagnitudeRatio = 0

				# Get the dot product of the slope's normal, normalized to what it would be if it where standing stright up (if the y normal was 0.0), to
				#	the player's current velocity direction. Basically, find out which direction and by how much the lpayer is moving relative to the ramp.
				#	Is he moving up the ramp at a 45 degree angle? Or is he moving parrallel to the ramp? This will find out.
				Slope_DotProduct = Vector2( Slope_FloorNor2D.x*Slope_MagnitudeRatio , Slope_FloorNor2D.y*Slope_MagnitudeRatio ).dot(Slope_PlayerVelVec2D)

				# If the player is going down the ramp...
				if(Slope_DotProduct > 0):
					# Multiply the dot product by a certain amount, so as to make the falling speed stronger, so the character doesn't "step" down the ramp as if it where stairs.
					Slope_DotProduct *= Slope_EffectMultiplier_ClimbingDown
				#Otherwise, if he is going up the ramp...
				else:
					# Multiply the slope's dot product by the slope effect multipler, so that the game designer can say how much he wants the slope to affect the player's walking
					#	velocity.
					Slope_DotProduct *= Slope_EffectMultiplier_ClimbingUp

				# Finally, setup the falling speed multiplier.
				Falling_Speed_Multiplier = lerp(Falling_Speed_Multiplier_Default, 1.0, pow( MaxFloorAngleNor_Y/get_slide_collision(Slide).normal.y , 4) * abs(Slope_DotProduct))



######################################################################################################################################################
#																		READY																		 #
######################################################################################################################################################
func _ready():
	get_node("Camera_Main/loadout").show()
	get_node("/root/playerHandler").applyValues(self)
	if playerClass == "barbarian":
		get_node("Camera_Main/loadout/leftHand/elfArms").free()
		get_node("Camera_Main/loadout/leftHand/wizArm").free()
		get_node("Camera_Main/loadout/rightHand/shield").free()
		get_node("Camera_Main/loadout/leftHand/blackBlade").free()
		
	if playerClass == "athenan":
		get_node("Camera_Main/loadout/leftHand/elfArms").free()
		get_node("Camera_Main/loadout/leftHand/wizArm").free()
		get_node("Camera_Main/loadout/leftHand/BarbarianHammer").free()
	
	if playerClass == "wizard":
		get_node("Camera_Main/loadout/leftHand/elfArms").free()
		get_node("Camera_Main/loadout/rightHand/shield").free()
		get_node("Camera_Main/loadout/leftHand/BarbarianHammer").free()
		get_node("Camera_Main/loadout/leftHand/blackBlade").free()
	
	if playerClass == "elf":
		get_node("Camera_Main/loadout/leftHand/wizArm").free()
		get_node("Camera_Main/loadout/leftHand/BarbarianHammer").free()
		#get_node("Camera_Main/loadout/leftHand/wizArm/AnimationPlayer").playback_speed = 1.75
		get_node("Camera_Main/loadout/rightHand/shield").free()
		get_node("Camera_Main/loadout/leftHand/blackBlade").free()
	#####################
	#	SET PROCESSES	#
	#####################
	# Unhandled input to be done.
	# Unhandled input is any input that is not handled by the GUI(control) or from _input().
	#	For instance, pressing space in a textbox won't make your character jump.
	#set_process_unhandled_input(true)
	set_process_input(true)

	# Set the physics to be done. This is now the new _fixed_process() from Godot 2.1.
	#	This is called according to the physics system's framerate. If it is set to 60 (in
	#	the project settings of your project) and no slowdown occurs, it will always run 60 times
	#	a second.
	set_physics_process(true)

	#####################
	#	INITIALIZATIONS	#
	#####################
	# These lines in this section initialize several variables and states.
	#	It's important to set initial variables and states because we don't know for sure
	#	what state the character is going to be in when starting a scene or respawning.

	#First, we must do "move_and_slide()" so that we can get some of our states.
	move_and_slide(Vector3(0.0, 0.0, 0.0), FloorNormal, SlopeStopMinVel, MaxSlides, MaxFloorAngleRad)

	#	Set Player On Floor	#
	# This makes the character start falling if not placed on a floor.
	# If the player is on the floor...
	if(is_on_floor()):
		# Say that he is not falling.
		State_Falling=false
		# And that he is one the floor in the variable.
		State_OnFloor = true
	# Otherwise, he's not on the floor. So...
	else:
		# Say that he is falling.
		State_Falling=true
		# And that he is not on the floor.
		State_OnFloor = false

	# Set if the player is on a wall.
	#	This is simply to initialize whether the character is on a wall.
	State_OnWalls = is_on_wall()

	# If the jump action is not pressed...
	if(not Input.is_action_pressed(String_Jump)):
		# Say that the jump action is released.
		Jump_Released = true

	# Set the initial player position variable.
	#	Later on in this code, this variable is set before it is used, anyway. But I like to have this here
	#	as it doesn't cause slowdown or overhead and I may change the code or reference this before that code
	#	for some reason.
	Player_Position = translation

	# Set the global Y position of the players feet.
	Player_GlobalFeetPos_Y = Player_Position.y - Player_Height/2

	# If the max step height is more than half the player...
	if(Step_MaxHeight > Player_Height * 0.5):
		# Set it back to half the player height.
		Step_MaxHeight = Player_Height * 0.5

	# Set the default label text.
	Debug_Label.set_text(Debug_Label_String)

	# Set the size of the touched objects array according to the maximum number of slides this character will have in its "move_and_slide()" function.
	Touch_ObjectsTouched.resize(MaxSlides)
	get_node("RayCast").add_exception(self)
	FootPoint = get_node("RayCast").get_collision_point()
	"""
	# Set the projectile
	if Projectile == "arrow":
		projectile = preload("res://scenes/items/projectiles/arrow.tscn")
	if Projectile == "blade":
		projectile = preload("res://scenes/items/projectiles/blade.tscn")
	if Projectile == "magic":
		projectile = preload("res://scenes/items/projectiles/magic.tscn")
	if Projectile == "force":
		projectile = preload("res://scenes/items/projectiles/force.tscn")
	"""



######################################################################################################################################################
#																UNHANDLED INPUT																		 #
######################################################################################################################################################
# This is for any input not handled elsewhere, like if a control node (a GUI node, like a window or something)
#	is currently using the mouse, this function will not run. When the GUI node is gone/minimized/no longer
#	there, the input will be handled here.
func _input(event):
	#############
	#	MOUSE	#
	#############
	# If the current event is a mouse movement...
	if(event is InputEventMouseMotion):
		# If mouselook is enabled...
		if(MouseLook):
			#####################
			#	 CALCULATION	#
			#####################
			#	LEFT and RIGHT	#
			# Set how much the mouse has moved from its last position.
			Mouse_Rel_Movement = event.relative

			# Find out what the current local X rotation is of the camera itself.
			Cam_Local_Rot_X = rad2deg(Node_Camera3D.get_rotation().x)

			# Add the mouse movement to the local camera X axis rotation.
			Cam_Temp_XRot_Var = Cam_Local_Rot_X + -Mouse_Rel_Movement.y

			# If it's too low...
			#if(Cam_Temp_XRot_Var < -90):
				# Set it back to the lower limit.
				#Final_Cam_Rot_Local_X = Cam_Temp_XRot_Var + 90 + Mouse_Rel_Movement.y
			# Else, if it's too high...
			#elif(Cam_Temp_XRot_Var > 90):
				# Set it to the upper limit.
				#Final_Cam_Rot_Local_X = Cam_Temp_XRot_Var - 90 + Mouse_Rel_Movement.y
			# Else, it must be within limits. So...
			#else:
				# Set the final X axis rotation.
			#	Final_Cam_Rot_Local_X = Mouse_Rel_Movement.y

			# Say that the mouse has moved so the player and his camera can be rotated.
			Mouse_Moved = true
	if(Input.is_action_just_pressed("ui_cancel")):
		if get_node("Camera2D/PauseMenu").visible:
			#MouseLook = true
			get_node("Camera2D/PauseMenu").hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false
		if !get_node("Camera2D/PauseMenu").visible:
			#MouseLook = false
			get_node("Camera2D/PauseMenu").show()
			get_node("Camera2D/PauseMenu").set_process_input(true)
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
			
	if(Input.is_action_just_pressed("Player_PrimaryAction")):
		if playerClass == "athenan":
			if(!get_node("Camera_Main/loadout/rightHand").get_child(0).active):
				if(!get_node("Camera_Main/loadout/leftHand").get_child(0).busy):
					if(get_node("Camera_Main/loadout/leftHand").get_child(0).has_method("Action")):
						get_node("Camera_Main/loadout/leftHand").get_child(0).Action()
		if playerClass != "athenan":
			if(!get_node("Camera_Main/loadout/leftHand").get_child(0).busy):
				if(get_node("Camera_Main/loadout/leftHand").get_child(0).has_method("Action")):
					get_node("Camera_Main/loadout/leftHand").get_child(0).Action()
				
	
	if(Input.is_action_just_pressed("Player_ThrowPotion")):
		ThrowPotion()
	
	if(Input.is_action_just_released("Player_PrimaryAction")):
		if playerClass == "athenan":
			if(!get_node("Camera_Main/loadout/rightHand").get_child(0).busy):
				if(get_node("Camera_Main/loadout/leftHand").get_child(0).has_method("UnAction")):
					get_node("Camera_Main/loadout/leftHand").get_child(0).UnAction()


	if(Input.is_action_just_pressed("Player_SecondaryAction")):
		if(get_node("Camera_Main/loadout/rightHand").get_child_count()>0):
			if(!get_node("Camera_Main/loadout/leftHand").get_child(0).busy):
				if(!get_node("Camera_Main/loadout/rightHand").get_child(0).busy):
					if(get_node("Camera_Main/loadout/rightHand").get_child(0).has_method("Action")):
						get_node("Camera_Main/loadout/rightHand").get_child(0).Action()

	if(Input.is_action_just_released("Player_SecondaryAction")):
		if(get_node("Camera_Main/loadout/leftHand").get_child_count()>0) and (get_node("Camera_Main/loadout/rightHand").get_child_count()>0):
			if(!get_node("Camera_Main/loadout/rightHand").get_child(0).busy):
				if(get_node("Camera_Main/loadout/rightHand").get_child(0).has_method("UnAction")):
					get_node("Camera_Main/loadout/rightHand").get_child(0).UnAction()




######################################################################################################################################################
#																	PHYSICS																			 #
######################################################################################################################################################
func _physics_process(delta):
	####################################################################################################
	#												GET INFO										   #
	####################################################################################################
	# First, it is important that we get info on what is happening to our character.
	FootPoint = get_node("RayCast").get_collision_point()
	#prints("footPoint: ", FootPoint)
	#####################################
	#			FLOOR or WALLS			#
	#####################################
	# Update if the player is on the floor, wall, or ceiling...
	State_OnFloor = is_on_floor()
	State_OnWalls = is_on_wall()
	State_OnCeiling = is_on_ceiling()
	# Get the slide count and put it in this variable.
	SlideCount = get_slide_count()
	# Update the current player position reference variable.
	Player_Position = translation

	#####################################
	#	GET ROTATION-DIRECTION NORMALS	#
	#####################################
	# Get the direction the player is facing in normalized vectors.
	#	Look at the first example, which is commented out as it is unessecary; the one that says "Example of manual code:" below.
	#		Notice the first variable in the "DirectionInNormalVec3_FWAndBW" 3D vector.
	#		As you can see, it has "sin(get_rotation().y)" in it. What does this mean?
	#	Break down this formula into the simpiliest parts you can. Breaking things down to it's simpilest parts is the basis of all sciences.
	#		This is how people throughout history have figured things out, even complicated problems.
	#	So, according to this philosophy, "sin(get_rotation().y)" is 3 parts: a "sin()" sine function, a "get_rotation()"
	#		function, and the "y" variable of that "get_rotation()" function.
	#	So that means that "get_rotation().y" gets the global rotation of the node that this script is currently attached to.
	#	"get_rotation().y" is in radians. Let's say the character is looking straight ahead according to global space.
	#		That is, "get_rotation().y" equals "0".
	#	So, now that we have that, find the sine of that number. This also equals 0.
	#		This is a hard-to-understand thing for begginers, but it's not complicated.
	#		It's just one of those things that are difficult to get into your brain, but once it's there you've got it.
	#	So what does that result mean? Practically speaking, the "0" in the sine function tells us how much the character is
	#		looking along the X axis.
	#	It says "0" because we are not looking along the X axis at all, but we are actually looking along the Y axis
	#		according to global space. But, if we were looking 90 degrees right in global space, our result would be "1",
	#		because we are completely looking along the positive X axis in global space. We are not facing N or S, but E.
	#	Now remember, this is all done in radians, as they are faster in computers because they are native to mathematics.
	#	So when I mentioned degrees, it was simply for your easy understanding.
	#	Let's say we are looking 45 degrees to the right. This is ~0.7853rads (look up how to convert degrees to radians and
	#		vice versa). The sine of that ("sin(0.7853)") is about "0.7070". This means we are looking along the +X axis about 70%.
	#	Then you do this with the other axies according to the function that you should use (sin() or cos()).
	#	This way, when we add velocity to the character, the velocity will be multiplied 0.7070 along the X axis, and he will
	#		we walking straight relative to the player direction. If you didn't do this, when you press forward it will be according
	#		to global space, and it will not take into account the direction the player is facing.
	#	This is triginometry, and you'll have to look elsewhere for a tutorial or information on that, as this comment is too long
	#		as it is. And I don't think it's very clear, either.
	#	Remember that this is trigonometry, so you have to think in 90 degree (right) angles.
	#	Basically, the sine of an angle is how long the opposite side is compared to the hypotenuse. Go find some pictures related to
	#		trigonometry.
	# Example of manual code:
	# DirectionInNormalVec3_FWAndBW = Vector3(sin(get_rotation().y), 0, cos(get_rotation().y))
	# DirectionInNormalVec3_LeftAndRight = Vector3(cos(get_rotation().y),0,sin(get_rotation().y))

	# This code here is new. I didn't know you could just use the global transform matrix, but that obviously makes sense, as it is exactly what I had above,
	#	only it is calculated by the C++ code in the engine instead of by a comparatively slow GDscript. The math above is still nessecary to know to make a
	#	good game.
	DirectionInNormalVec3_FWAndBW = get_global_transform().basis.z
	DirectionInNormalVec3_LeftAndRight = Vector3(get_global_transform().basis.x.x, get_global_transform().basis.x.y, -get_global_transform().basis.x.z)

	##########################################################################
	#								INPUT									 #
	##########################################################################
	# Get input that is pressed and set bools accordingly.

	#########################
	#		MOVEMENT		#
	#########################
	#Set the action bool variables.
	Pressed_FW = Input.is_action_pressed(String_FW)
	Pressed_BW = Input.is_action_pressed(String_BW)
	Pressed_LEFT = Input.is_action_pressed(String_Left)
	Pressed_RIGHT = Input.is_action_pressed(String_Right)

	# If a movement key is pressed...
	if((Pressed_FW and Pressed_LEFT) or (Pressed_FW and Pressed_RIGHT) or (Pressed_BW and Pressed_LEFT) or (Pressed_BW and Pressed_RIGHT)):
		# Say that it is in this bool.
		State_Movement_Diagonal_Pressed = true
	# Otherwise, if it isn't...
	else:
		# Say that it is not.
		State_Movement_Diagonal_Pressed = false
	"""
	#########################
	#			JUMP		#
	#########################
	# If the jump key was pressed...
	if(Input.is_action_pressed(String_Jump)):
		# Then say that the jump key has been pressed.
		Pressed_Jump = true
		# If the player is currently jumping or falling, AND is not on the floor...
		if((State_Jumping or State_Falling) and not State_OnFloor):
			# Say that the jump key has not been released.
			Jump_Released = false
	# Otherwise, if the jump key was released...
	elif(not Input.is_action_pressed(String_Jump)):
		# Say that the player is not pressing the jump key.
		Pressed_Jump = false
		# And say that he has released it.
		Jump_Released = true
	"""
	#####################################
	#			SPEED SHIFT				#
	#####################################
	# If the speed shift key is pressed...
	if(Input.is_action_pressed(String_Shift)):
		# Multiply the final walk velocity by the speed shift velocity.
		FinalWalkVelocity = BaseWalkVelocity * ShiftWalkVelocity_Multiplier
	# Otherwise...
	else:
		# Set the final walk velocity as the base velocity.
		FinalWalkVelocity = BaseWalkVelocity

	# Set the step saftey margin according to the player's current speed.
	Step_SafetyMargin = Step_SafetyMargin_Dividend/FinalWalkVelocity
	# Then set the camera interpolation length according to the speed of the player.
	CamInterpo_Length_Secs = FinalWalkVelocity / (CamInterpo_Length_Secs_Multiplicand * (FinalWalkVelocity/10.0))

	#############################################
	#			CROSSHAIR: USABLE ITEM			#
	#			AND USE BUTTON					#
	#############################################
	# This hides or shows the red circle texture on screen if there is a visible item within reach
	#	of the character, if he's pointing at it.
	# Setup and execute a raycast to see if there is a usable item.
	Ray_SpaceState = get_world().get_direct_space_state()
	Ray_From = Node_Camera3D.get_global_transform().origin
	Ray_To = -Node_Camera3D.get_global_transform().basis.z * Ray_UseDist + Ray_From
	Ray_Result = Ray_SpaceState.intersect_ray(Ray_From,Ray_To,[self])

	# If the ray hit something...
	if(not Ray_Result.empty()):
		#COLLIDER#
		# If the colliding object itself has a use function...
		if(Ray_Result.collider.has_method("UseFunction")):
			# Show the red circle over the crosshair.
			Node_Crosshair_Useable.visible=true
			# If the player pressed the use button and it was previously released...
			if(Input.is_action_just_pressed(String_Use)):
				# Set what the position of the ray intersection is.
				Use_Ray_IntersectPos = Ray_Result.position
				# Use the function of the object intersected.
				Ray_Result.collider.UseFunction()
		#PARENT#
		# Else if its parent has a "UseFunction()" function...
		elif(Ray_Result.collider.get_parent().has_method("UseFunction")):
			# Show the red circle over the crosshair.
			Node_Crosshair_Useable.visible=true
			# If the player pressed the use button and it was previously released...
			if(Input.is_action_just_pressed(String_Use)):
				# Set what the position of the ray intersection is.
				Use_Ray_IntersectPos = Ray_Result.position
				# Use the function of the object intersected.
				Ray_Result.collider.get_parent().UseFunction()
		#NO USE FUNCTION#
		# Otherwise, if there is not...
		else:
			# Hide the red circle.
			Node_Crosshair_Useable.visible=false
			# Then reset the ray intersections position.
			Use_Ray_IntersectPos = Vector3(0,0,0)
	# Else, if the ray hit nothing...
	else:
		# Hide the red circle.
		Node_Crosshair_Useable.visible=false
		# Then reset the ray intersections position.
		Use_Ray_IntersectPos = Vector3(0,0,0)


	#if(State_OnFloor):
	####################################################################################################
	#										HORIZONTAL MOVEMENT				 						   #
	####################################################################################################
	#########################################
	#	FORWARD AND BACKWARDS CALCULATIONS	#
	#########################################
	# If forwards or backwards are pressed, just set the player to move in that direction.
	# If both or neither keys are pressed, then set the player to not move at all, e.g. velx=0 and velz=0.
	#	FORWARDS	#
	if(Pressed_FW and not Pressed_BW):
		TempMoveVel_FWAndBW.x = -DirectionInNormalVec3_FWAndBW.x * FinalWalkVelocity
		TempMoveVel_FWAndBW.z = -DirectionInNormalVec3_FWAndBW.z * FinalWalkVelocity
	#	BACKWARDS	#
	elif(not Pressed_FW and Pressed_BW):
		TempMoveVel_FWAndBW.x = DirectionInNormalVec3_FWAndBW.x * FinalWalkVelocity
		TempMoveVel_FWAndBW.z = DirectionInNormalVec3_FWAndBW.z * FinalWalkVelocity
	#	BOTH		#
	elif(Pressed_FW and Pressed_BW):
		TempMoveVel_FWAndBW.x = 0
		TempMoveVel_FWAndBW.z = 0
	#	NEITHER		#
	elif(not Pressed_FW and not Pressed_BW):
		TempMoveVel_FWAndBW.x = 0
		TempMoveVel_FWAndBW.z = 0
	#	FAILSAFE	#
	#This is a failsafe case.
	else:
		TempMoveVel_FWAndBW.x = 0
		TempMoveVel_FWAndBW.z = 0

	#########################################
	#		LEFT AND RIGHT	CALCULATIONS	#
	#########################################
	# If left or right are pressed, just set the player to move in that direction.
	# If both or neither keys are pressed, then set the player to not move at all, e.g. velx=0 and velz=0.
	#	LEFT		#
	if(Pressed_LEFT and not Pressed_RIGHT):
		TempMoveVel_LeftAndRight.x = -DirectionInNormalVec3_LeftAndRight.x * FinalWalkVelocity
		TempMoveVel_LeftAndRight.z = DirectionInNormalVec3_LeftAndRight.z * FinalWalkVelocity
	#	RIGHT		#
	elif(not Pressed_LEFT and Pressed_RIGHT):
		TempMoveVel_LeftAndRight.x = DirectionInNormalVec3_LeftAndRight.x * FinalWalkVelocity
		TempMoveVel_LeftAndRight.z = -DirectionInNormalVec3_LeftAndRight.z * FinalWalkVelocity
	#	BOTH		#
	elif(Pressed_LEFT and Pressed_RIGHT):
		TempMoveVel_LeftAndRight.x = 0
		TempMoveVel_LeftAndRight.z = 0
	#	NEITHER		#
	elif(not Pressed_LEFT and not Pressed_RIGHT):
		TempMoveVel_LeftAndRight.x = 0
		TempMoveVel_LeftAndRight.z = 0
	#	FAILSAFE	#
	#This is a failsafe case.
	else:
		TempMoveVel_LeftAndRight.x = 0
		TempMoveVel_LeftAndRight.z = 0

	#########################
	#	ADD X AND Z AXIS	#
	#########################
	# First, reset the final move velocity, just in case.
	FinalMoveVel = Vector3(0.0, 0.0, 0.0)
	# If the character is moving diagonally...
	if(State_Movement_Diagonal_Pressed):
		# Set the final move velocity vector according to the crest factor.
		FinalMoveVel=(TempMoveVel_FWAndBW + TempMoveVel_LeftAndRight) / CrestFactor
	# Otherwise, if he is simply moving on one relative axis...
	else:
		# Set the final move velocity.
		FinalMoveVel=(TempMoveVel_FWAndBW + TempMoveVel_LeftAndRight)

	####################################################################################################
	#										VERTICAL MOVEMENT				 						   #
	####################################################################################################
	#########################################
	#				ON FLOOR				#
	#########################################
	# If the player is on the floor and falling and wasn't jumping...
	if(State_OnFloor and State_Falling and not State_Jumping):
		# Say that the falling has stopped.
		Falling_IsFalling = false
	# Otherwise, if the player is not on the floor and not jumping...
	elif(not State_OnFloor and not State_Jumping):
		# He is falling.
		State_Falling = true
	# Otherwise, if the player is on the floor and was jumping, but not falling...
	elif(State_OnFloor and State_Jumping and not State_Falling):
		# He has landed on the floor after a jump. So...
		# Say that he is not jumping anymore as he has landed on the ground.
		State_Jumping = false
		# Set the current jump velocity to 0.
		Jump_CurrentVel = 0
		# Say he has started falling.
		State_Falling = true
		# Set the current falling speed to 0.
		Falling_Speed = 0
		# Set the current falling time to "now."
		Falling_CurrentTime = 0

	#########################################
	#				JUMP PRESSED			#
	#########################################
	# If the jump key was pressed and was previously released...
	if(Pressed_Jump and Jump_Released):
		# If the character is on the floor...
		if(State_OnFloor):
			# And if he was not jumping when he hit the floor...
			if(State_Jumping==false):
				# Say that he has started his jump.
				State_Jumping = true
				# Not falling.
				State_Falling = false
				# Reset the jump timer counter.
				Jump_CurrentTime = 0

	#########################################
	#				JUMPING					#
	#########################################
	# If the player is jumping and not falling...
	if(State_Jumping and not State_Falling):
		# If he is on the floor...
		if(State_OnFloor):
			# If the player's jump velocity is the same as or less than gravity...
			if(Jump_Vel - Falling_Gravity <= 0):
				# Cancel the jump, as it would do nothing.
				State_Jumping = false
				# Set the current jump vel to 0.
				Jump_CurrentVel = 0
				# Say that he is falling.
				State_Falling = true
				# Set the falling speed to 0, as it has just started.
				Falling_Speed = 0
				# Set the current time of the player falling to "now."
				Falling_CurrentTime = 0
			# Otherwise, if the jump key was released previously...
			elif(Jump_Released):
				# Set the initial velocity of the jump according to the global character variable.
				Jump_CurrentVel = Jump_Vel
				# Set the final Y(vertical) velocity according to the current jump velocity, while subtracting gravity from it.
				FinalMoveVel.y = Jump_CurrentVel + -Falling_Gravity
		# If he is in the air in the middle of a jump...
		elif(not State_OnFloor):
			# And if the jump is not yet over...
			if(Jump_CurrentTime < Jump_Length):
				# If the player has hit his head on a ceiling or something...
				if(State_OnCeiling):
					# Set the current jump velocity to 0.
					Jump_CurrentVel = 0
					# Set the falling speed to 0.
					Falling_Speed = 0
					# Set the current falling time to "now."
					Falling_CurrentTime = 0
					# Say that the jump is over.
					State_Jumping=false
					# Say that the falling has started.
					Falling_IsFalling = true
					# Say that the player is currently falling.
					State_Falling=true
				# Otherwise, if the jump isn't over...
				else:
					# Set the current velocity of the jump according to the current time of the jump, so as to smoothly taper off the jump velocity.
					Jump_CurrentVel = Jump_Vel - (Jump_Vel * (pow(Jump_CurrentTime / Jump_Length, 2)))
					# Increment the jump timer.
					Jump_CurrentTime += delta
					# Set the final Y(vertical) velocity.
					FinalMoveVel.y = Jump_CurrentVel + -Falling_Gravity
			# Otherwise, if the jump is over...
			else:
				# Set the current jump velocity to 0.
				Jump_CurrentVel = 0
				# Set the falling speed to 0.
				Falling_Speed = 0
				# Set the current falling time to "now."
				Falling_CurrentTime = 0
				# Say that the jump is over.
				State_Jumping=false
				# Say that the falling has started.
				Falling_IsFalling = true
				# Say that the player is currently falling.
				State_Falling=true

	#########################################
	#				FALLING					#
	#########################################
	# If our character is falling...
	if(State_Falling):
		# And if he's not jumping...
		if(not State_Jumping):
			# If not on floor...
			if(not State_OnFloor):
				# If the falling speed is less than terminal velocity...
				if(Falling_Speed < Falling_TerminalVel):
					# If the falling has not started yet...
					if(not Falling_IsFalling):
						# Say that it has started.
						Falling_IsFalling = true
						# And set the current falling time to "now".
						Falling_CurrentTime = 0
					# Otherwise, if the falling has already started...
					elif(Falling_IsFalling and Falling_CurrentTime < Falling_TimeToHitTerminalVelSec):
						# Update the falling timer.
						Falling_CurrentTime += delta
					# Set final falling speed.
					Falling_Speed = Falling_TerminalVel * pow(Falling_CurrentTime/Falling_TimeToHitTerminalVelSec, 0.4)
			# Otherwise, if the player is on the floor...
			else:
				# If the character is moving...
				if(FinalMoveVel.x != 0 or FinalMoveVel.z != 0):
					# Run the function that makes the character speed affected by the slope.
					Slope_AffectSpeed()
				# Otherwise, if the player is not moving...
				else:
					# Set the falling speed multiplier to the default specified in the settings.
					Falling_Speed_Multiplier = Falling_Speed_Multiplier_Default

				# Set the final falling speed multiplier.
				Falling_Speed = Falling_Gravity * Falling_Speed_Multiplier

			# Apply final falling velocity.
			FinalMoveVel.y = -Falling_Speed

	#####################################################################################################
	#									FINAL MOVEMENT APPLICATION										#
	#####################################################################################################
	#####################
	#	MOUSE ROTATION	#
	#####################
	if(Mouse_Moved):
		# Here the mouse movement is finally applied.
		# Apply the y axis rotation to the character kinematic body.
		#	This means rotate the whole character left and right.
		self.rotate_y(deg2rad(-Mouse_Rel_Movement.x) * Cam_RotateSens)
		# Apply the x axis rotation to the camera.
		#	And this is rotating _just_ the camera only, up and down on its local X axis.
		Node_Camera3D.rotate_x(deg2rad(-Final_Cam_Rot_Local_X) * Cam_RotateSens)

		#Say that the mouse is basically done moving.
		Mouse_Moved = false

	#####################
	#	LINEAR MOVEMENT	#
	#####################
	# If character is on floor...
	if(State_OnFloor):
		# Add the floor velocity to the player character's final movement velocity.
		FinalMoveVel += get_floor_velocity() * delta

	# Apply the movement calculations with move_and_slide().
	move_and_slide(FinalMoveVel, FloorNormal, SlopeStopMinVel, MaxSlides, MaxFloorAngleRad)

	#########################################
	#				GET STATES				#
	#########################################
	# Update if the player is on the floor, wall, or ceiling.
	#	This is nessecary for after the "move_and_slide()" above, as that updates "is_on_floor()", "is_on_wall()", and "is_on_ceiling()".
	State_OnFloor = is_on_floor()
	State_OnWalls = is_on_wall()
	State_OnCeiling = is_on_ceiling()
	# Get the slide count and put it in this variable.
	SlideCount = get_slide_count()
	# Update the current player position reference variable.
	Player_Position = translation

	#########################################
	#				STEPS					#
	#########################################
	# Execute the stepping up function.
	Step_Player_Up()

	#############################
	#	CAMERA INTERPOLATION	#
	#############################
	#If the stepping function set the camera to be interpolated...
	if(CamInterpo_DoInterpolation == true):
		#Do the camera interpolation and return the modified interpolation time.
		CamInterpo_CurrentTime_Secs = InterpolateCamera(CamInterpo_StartingPos_Local_Y, CamInterpo_CurrentTime_Secs, delta)

	#####################################
	#		  TOUCH FUNCTION			#
	#####################################
	#Check for and execute any touch functions.
	Touch_CheckAndExecute()

	#############################
	#			DEBUG			#
	#############################
	#Set the debug text as the FPS.
	Debug_Label_String = "FPS: " + str(Engine.get_frames_per_second())
	#Set the debug text.
	Debug_Label.set_text(Debug_Label_String)

func _on_Timer_timeout():
	ChangeHealth(-1)
	get_node("Timer").start()
	pass # replace with function body
