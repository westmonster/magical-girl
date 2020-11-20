extends "res://addons/godot-behavior-tree-plugin/bt_base.gd"

export(NodePath) var Actor
export(bool)	 var IsNot = false
export(String, "Nevermind", "has_target", "is_in_range", "is_in_arrival_radius", "is_facing_target", "has_line_of_sight", "get_target_point", "has_low_health",\
"find", "chase", "seek", "pursue", "flee", "wander", "melee", "block", "use", "face_target") var Action = "Nevermind"
# Leaf Node
func tick(tick):
	var children = get_children()
	if Actor:
		if Action != "Nevermind":
			if get_node(Actor).has_method(Action):
				#prints("has method: ", Action)
				var actionResult = get_node(Actor).call(Action)
				if IsNot:
					actionResult = !actionResult
				if actionResult:
					var result
					for child in children:
						result = child.tick(tick)
						prints(self, " ticked ", child)
						if result != OK:
							break
					prints(self, " finished.")
					return result
	return FAILED