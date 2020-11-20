#tool
extends GridMap

var astar = AStar.new()
var grid  = {}

export var Connections = []

#export var GenerateConnections=false setget generate
var aScript = load("res://scripts/astarConnection.gd")
#var aScript = preload("res://scripts/astarConnection.gd")

var Walkable		= [ "ground","floor","roof","bridge","burm","ledge","stair"]
var WalkableUpLevel = ["stair"]
var OneWayWalkable  = ["burm","ledge"]
var Directions		= ["u","un","unw","uw","usw","us","use","ue","une","n","nw","w","sw","s","se","e","ne","d","dn","dnw","dw","dsw","ds","dse","de","dne"]
var levelNeighbors  = ["n","nw","w","sw","s","se","e","ne"]
var levelDiagonals  = ["nw","sw","se","ne"]
var levelCardinals  = ["n","w","s","e"]
var upNeighbors		= ["un","unw","uw","usw","us","use","ue","une"]
var HasRail			= ["stair-wall", "stair-right", "stair-left", "roof-side", "bridge-side"]
var railLeft		= ["stair-left", "stair-half-wall-left","stair-wall-left"]

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	#ProcessPoints()
	#ConnectNeighbors()
	BuildAStarPath()

func generate(fart):
	if fart:
		print("Initializing generate")
		var children = get_children()
		if children.size() > 0:
			for child in children:
				remove_child(child)
		print("All clear, processing points.")
		ProcessPoints()
		print("Processed points, connecting neighbors.")
		ConnectNeighbors()
		print("Neighbors connected!")

func BuildAStarPath():
	#var con = get_children()
	for connection in Connections:
		astar.connect_points(connection.from,connection.to,connection.bidirectional)

func connect_points(a,b,bidirectional=true):
	#var aPoint = Spatial.new()
	#var bPoint = Spatial.new()
	
	#aPoint.name = String(a)
	#bPoint.name = String(b)
	
	#aPoint.translation = grid[a].top
	#bPoint.translation = grid[b].top
	
	#aPoint.set_script(aScript.new())
	#print(aScript)
	#if !bidirectional:
	#	var bdNode = Node.new()
	#	bdNode.name = "oneWay"
	#	aPoint.add_child(bdNode)
	
	#aPoint.add_child(bPoint)
	#add_child(aPoint)
	var connection = {
		"from" : a,
		"to"   : b,
		"bidirectional" : bidirectional
	}
	Connections.append(connection)

func ProcessPoints():
	var cells = get_used_cells()
	var id = 0
	for cell in cells:
		var tileName = theme.get_item_name(get_cell_item(cell.x,cell.y,cell.z))
		##### KEY #####
		# North : 16
		# South : 22
		# East  : 0
		# West  : 10
		var tileOrientation
		var tO = get_cell_item_orientation(cell.x,cell.y,cell.z)
		if tO == 16:
			tileOrientation = "s"
		if tO == 22:
			tileOrientation = "n"
		if tO == 0:
			tileOrientation = "w"
		if tO == 10:
			tileOrientation = "e"
		
		#print(String(cell)+" Name: "+tile+" Orientation: "+String(tileOrientation))
		grid[id] = {
			##### KEY #####
			# Up    - u - Y+
			# Down  - d - Y-
			# North - n - X+
			# South - s - X-
			# East  - e - Z+
			# West  - w - Z-
			"neighbors":{
				"u"		:Vector3(cell.x,cell.y+1,cell.z),
				"un"	:Vector3(cell.x+1,cell.y+1,cell.z),
				"unw"	:Vector3(cell.x+1,cell.y+1,cell.z-1),
				"uw"	:Vector3(cell.x,cell.y+1,cell.z-1),
				"usw"	:Vector3(cell.x-1,cell.y+1,cell.z-1),
				"us"	:Vector3(cell.x-1,cell.y+1,cell.z),
				"use"	:Vector3(cell.x-1,cell.y+1,cell.z+1),
				"ue"	:Vector3(cell.x,cell.y+1,cell.z+1),
				"une"	:Vector3(cell.x+1,cell.y+1,cell.z+1),
				"n"		:Vector3(cell.x+1,cell.y,cell.z),
				"nw"	:Vector3(cell.x+1,cell.y,cell.z-1),
				"w"		:Vector3(cell.x,cell.y,cell.z-1),
				"sw"	:Vector3(cell.x-1,cell.y,cell.z-1),
				"s"		:Vector3(cell.x-1,cell.y,cell.z),
				"se"	:Vector3(cell.x-1,cell.y,cell.z+1),
				"e"		:Vector3(cell.x,cell.y,cell.z+1),
				"ne"	:Vector3(cell.x+1,cell.y,cell.z+1),
				"d"		:Vector3(cell.x,cell.y-1,cell.z),
				"dn"	:Vector3(cell.x+1,cell.y-1,cell.z),
				"dnw"	:Vector3(cell.x+1,cell.y-1,cell.z-1),
				"dw"	:Vector3(cell.x,cell.y-1,cell.z-1),
				"dsw"	:Vector3(cell.x-1,cell.y-1,cell.z-1),
				"ds"	:Vector3(cell.x-1,cell.y-1,cell.z),
				"dse"	:Vector3(cell.x-1,cell.y-1,cell.z+1),
				"de"	:Vector3(cell.x,cell.y-1,cell.z+1),
				"dne"	:Vector3(cell.x+1,cell.y-1,cell.z+1)
			},
			"id"			:id,
			"gridPoint"		:cell,
			"tileName"		:tileName,
			"orientation"	:tileOrientation,
			"dontConnect"	: [],
			"top"			:Vector3(cell.x*cell_size.x+(cell_size.x/2),cell.y*cell_size.y+(cell_size.y),cell.z*cell_size.z+(cell_size.z/2))
		}
		
		if OneWayWalkable.has(grid[id].tileName):
			if grid[id].orientation in ["n","s"]:
				grid[id].dontConnect = ["e","w"]
			if grid[id].orientation in ["e","w"]:
				grid[id].dontConnect = ["n","s"]
		
		for i in HasRail:
			if grid[id].tileName.begins_with(i):
				if grid[id].tileName in railLeft:
					if grid[id].orientation == "n":
						grid[id].dontConnect = ["e","ne","se","une"]
						grid[id].top.x		 = grid[id].top.x+(cell_size.x/2)
					if grid[id].orientation == "s":
						grid[id].dontConnect = ["w","nw","sw","unw"]
						grid[id].top.x		 = grid[id].top.x-(cell_size.x/2)
					if grid[id].orientation == "e":
						grid[id].dontConnect = ["n","ne","nw","une"]
						grid[id].top.z		 = grid[id].top.z+(cell_size.x/2)
					if grid[id].orientation == "w":
						grid[id].dontConnect = ["s","se","sw","usw"]
						grid[id].top.z		 = grid[id].top.z-(cell_size.x/2)
				else:
					if grid[id].orientation == "n":
						grid[id].dontConnect = ["w","nw","sw","unw"]
						grid[id].top.x		 = grid[id].top.x-(cell_size.x/2)
					if grid[id].orientation == "s":
						grid[id].dontConnect = ["e","ne","se","une"]
						grid[id].top.x		 = grid[id].top.x+(cell_size.x/2)
					if grid[id].orientation == "e":
						grid[id].dontConnect = ["s","se","sw","usw"]
						grid[id].top.z		 = grid[id].top.z-(cell_size.x/2)
					if grid[id].orientation == "w":
						grid[id].dontConnect = ["n","ne","nw","une"]
						grid[id].top.z		 = grid[id].top.z+(cell_size.x/2)
		
		astar.add_point(id,grid[id].top)
		id += 1


func ComputeConnections(id,dirs):
	var currentCell = grid[id]
	var ids = []	
	for i in grid:
		for d in dirs:
			var compareCell = grid[i]
			if compareCell.gridPoint == currentCell.neighbors[d]:
				if d != "d": #can't really count the compared cell as walkable if it's covered
					var cUpNeighbor = compareCell.neighbors["u"]
					var upNeighbor  = currentCell.neighbors["u"]
					if !(d in currentCell.dontConnect) or !(d in compareCell.dontConnect):
						if get_cell_item(cUpNeighbor.x,cUpNeighbor.y,cUpNeighbor.z) == INVALID_CELL_ITEM and get_cell_item(upNeighbor.x,upNeighbor.y,upNeighbor.z) == INVALID_CELL_ITEM:#if neighboring cell isn't covered
							if levelNeighbors.has(d):#if its direction is on the same plane as currentCell
								if !d.begins_with("u") and !d.begins_with("d"):
									for w in Walkable:
										if compareCell.tileName.begins_with(w):#if it's walkable
											if not astar.are_points_connected(id, i):
												if !(compareCell.tileName.begins_with("floor") and currentCell.tileName.begins_with("bridge")) and !(compareCell.tileName.begins_with("bridge") and currentCell.tileName.begins_with("floor")):
													#astar.connect_points(id,i)
													connect_points(id,i)
						if d.begins_with("u"):
							for u in WalkableUpLevel:
								if compareCell.tileName.begins_with(u):#if it's a stair or ramp or some such
									if compareCell.orientation == d.right(1):#if that stair or ramp or some such is facing current cell
										if not astar.are_points_connected(id, i):
											#astar.connect_points(id,i)
											connect_points(id,i)
						if d.begins_with("d"):
							for o in OneWayWalkable:
								if currentCell.tileName.begins_with(o) and !compareCell.tileName.begins_with(o):
									if(d == "dn" and currentCell.orientation == "s")or(d == "ds" and currentCell.orientation == "n")or(d == "de" and currentCell.orientation == "w")or(d == "dw" and currentCell.orientation == "e"):
										for w in Walkable:
											if compareCell.tileName.begins_with(w):
												if not astar.are_points_connected(id, i):
													#astar.connect_points(id,i,false)
													connect_points(id,i,false)
													# HOLY SHIT
				#continue
	#return ids


func ConnectAllSameLevel():
	pass

func ConnectUpLevel():
	pass

func ConnectDownLevel():
	pass


func ConnectNeighbors():
	for cell in grid:
		ComputeConnections(cell,Directions)
		#for i in ids:
		#	if not astar.are_points_connected(cell,i):
				
		#		astar.connect_points(cell,i)

func GetPath(StartPoint,EndPoint):
	
	var startMapPoint = world_to_map(StartPoint)
	var endMapPoint   = world_to_map(EndPoint)
	#print(String(StartPoint) + " " + String(EndPoint))
	startMapPoint = Vector3(startMapPoint.x,startMapPoint.y-1,startMapPoint.z)
	endMapPoint   = Vector3(endMapPoint.x,endMapPoint.y-1,endMapPoint.z)
	#prints(sp,ep)
	var startID
	var endID
	#print(grid)
	for i in grid:
		#print(i)
		if startMapPoint == grid[i].gridPoint:
			startID = grid[i].id
		if endMapPoint == grid[i].gridPoint:
			endID = grid[i].id
	#prints(si,ei)
	if endID and startID:
		return astar.get_point_path(startID,endID)
	return PoolVector3Array()
