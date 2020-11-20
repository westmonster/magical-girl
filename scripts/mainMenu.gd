extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().get_root().connect("size_changed", self, "ViewportSizeChanged")

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_start_pressed():
	get_node("TextureRect/start_container").hide()
	get_tree().change_scene("res://scenes/levels/magicalGirlTestScene.tscn")


func _on_quit_pressed():
	get_tree().quit()

func ViewportSizedChanged():
	var Viewport_Size = get_tree().get_root().get_visible_rect().size
	var start_container = get_node("TextureRect/start_container")
	get_node("TextureRect").rect_size = Vector2(Viewport_Size.x, Viewport_Size.x*(4/3))
	start_container.rect_position = Vector2( (Viewport_Size.x/2) - (start_container.rect_size.x/2), Viewport_Size.y-start_container.rect_size.y)

