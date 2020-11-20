tool
extends MeshInstance

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
export(ImageTexture) var heightmap
export(float)		 var heightmap_Height = 1
export(bool) var Generate_Heightmap setget _ready
var terrain_Points

func _ready():
	terrain_Points = mesh.get_faces()
	print(mesh.get_faces())
	for v in range(0,terrain_Points.size()):
		var vert = terrain_Points[v]
		print(vert)
		#v.y = randf() * heightmap_Height
		terrain_Points.set(v,Vector3(vert.x,vert.y+(randi()*heightmap_Height),vert.z))
