extends "res://addons/godot-behavior-tree-plugin/bt_base.gd"


const BehvError = preload("res://addons/godot-behavior-tree-plugin/error.gd")

export(NodePath) var Actor
export(String, "Nevermind", "has_target", "is_in_range", "is_in_arrival_radius", "is_facing_target", "has_line_of_sight", "get_target_point", "has_low_health", \
"find", "chase", "seek", "pursue", "flee", "wander", "melee", "block", "use", "face_target") var Action = "Nevermind"

# Leaf Node
func tick(tick):
	print("Ticking Action leaf!")
	if Actor != null:
		if Action != "Nevermind":
			if get_node(Actor).has_method(Action):
				if get_node(Actor).call(Action):
					prints(Actor, " performing ", Action)
					return OK
	prints(self, ", ",Action,  "Failing.")
	return FAILED
