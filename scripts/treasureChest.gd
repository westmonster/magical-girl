extends Area

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var item
var opened = false
export(String, "potion","meat","treasure","whtKey","redKey","bluKey","ylwKey","rngKey","random") var contents = "random"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_treasureChest_body_entered(body):
	if !opened:
		if body is preload("res://scripts/Player0.gd"):
			if body.whtKeys > 0:
				opened = true
				body.AddKeys("white", -1)
				get_node("AnimationPlayer").play("default")
				if contents == "random":
					item = get_tree().get_root().get_node("world").randomItem().instance(0)
				else:
					item = get_tree().get_root().get_node("world").item(contents).instance(0)
				get_tree().get_root().get_node("world/items").add_child(item)
				#item.hide()
				#item.get_node("CollisionShape").shape.radius = 0.4
				item.translation = translation + Vector3(0,1,0)
				item.rotation = rotation
				item.scale = Vector3(0,0,0)
				get_node("Tween").interpolate_property(item, "scale", Vector3(0,0,0), Vector3(1,1,1), 1.2,Tween.TRANS_LINEAR,Tween.EASE_IN,0.3)
				get_node("Tween").start()
				#item.show()
				#prints(item, item.translation, " | ", translation)
				get_node("Timer").start()


func _on_Timer_timeout():
	#item.show()
	queue_free()

