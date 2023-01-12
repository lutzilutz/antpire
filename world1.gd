extends Node2D

const AntResource = preload("res://ant.tscn")
const PheromonResource = preload("res://pheromon.tscn")
const WORLD_SIZE_X = 144
const WORLD_SIZE_Y = 81

var timeFromLastTick = 0
var pheromons = []
var pheromon_house_map: Array = []
var pheromon_food_map: Array = []
var pheromon_combat_map: Array = []
var pheromon_decay_map: Array = []
var pheromon_display: Array = []
var ants = []
var nAnts = 1
var spawn_tiles: Array = []

func _ready():
	init_pheromon_map()
	init_ants()

func init_ants() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var tmp_tiles: Array = spawn_tiles
	for i in range(0,nAnts):
		var newAnt = AntResource.instantiate()
		var spawn_position: Vector2i = tmp_tiles.pop_at(rng.randi() % tmp_tiles.size())
		newAnt.set_tile_pos(spawn_position.x, spawn_position.y)
		newAnt.direction = rng.randi_range(0,7)
		newAnt.z_index += 1
		get_node("Ants").add_child(newAnt)

func init_pheromon_map():
	for x in range(WORLD_SIZE_X):
		pheromon_house_map.append([])
		pheromon_food_map.append([])
		pheromon_decay_map.append([])
		pheromon_display.append([])
		for y in range(WORLD_SIZE_Y):
			pheromon_house_map[x].append(0)
			pheromon_food_map[x].append(0)
			pheromon_decay_map[x].append(-1)
			#pheromon_display[x].append(tmp_sprite)
			var tmp_pheromon = PheromonResource.instantiate()
			tmp_pheromon.position = Vector2(x*8 + 4, y*8 + 4)
			pheromon_display[x].append(tmp_pheromon)
			$Pheromons.add_child(tmp_pheromon)
			check_spawn_tiles(x,y)
	print("Found ", spawn_tiles.size(), " spawn tiles")

func init_pheromon_map_DEPRECATED():
	for x in range(WORLD_SIZE_X):
		pheromon_house_map.append([])
		pheromon_food_map.append([])
		pheromon_decay_map.append([])
		pheromon_display.append([])
		for y in range(WORLD_SIZE_Y):
			pheromon_house_map[x].append(0)
			pheromon_food_map[x].append(0)
			pheromon_decay_map[x].append(-1)
			var tmp_sprite: Sprite2D = Sprite2D.new()
			tmp_sprite.texture = load("res://pheromon.png")
			tmp_sprite.position = Vector2(x*8+4,y*8+4)
			tmp_sprite.modulate = Color(1.0,1.0,1.0,0.0)
			pheromon_display[x].append(tmp_sprite)
			$Pheromons.add_child(tmp_sprite)
			check_spawn_tiles(x,y)
	print("Found ", spawn_tiles.size(), " spawn tiles")

func check_spawn_tiles(x: int, y: int):
	if $TileMap.get_cell_alternative_tile(0, Vector2i(x,y)) == 1:
		spawn_tiles.append(Vector2i(x,y))

func _process(delta):
	timeFromLastTick += delta
	if timeFromLastTick >= 0.1:
		timeFromLastTick -= 0.1
		for i in range(0,pheromon_house_map.size()):
			for j in range(0,pheromon_house_map[0].size()):
				pheromon_house_map[i][j] = max(0, pheromon_house_map[i][j] - $Camera2D/GUI/PheromonDecay.value)
				pheromon_food_map[i][j] = max(0, pheromon_food_map[i][j] - $Camera2D/GUI/PheromonDecay.value)
				modulate_pheromon_display(i, j)

func modulate_pheromon_display(tmp_x: int, tmp_y: int) -> void:
	var house_mod: Color = Color(0.0,0.0,1.0,pheromon_house_map[tmp_x][tmp_y] / 1000.0)
	var food_mod: Color = Color(0.0,1.0,0.0,pheromon_food_map[tmp_x][tmp_y] / 1000.0)
	var house_present: float = clamp(pheromon_house_map[tmp_x][tmp_y], 0, 1)
	var food_present: float = clamp(pheromon_food_map[tmp_x][tmp_y], 0, 1)
	pheromon_display[tmp_x][tmp_y].modulate = house_mod + food_mod
	pheromon_display[tmp_x][tmp_y].modulate = Color(0.0, food_mod.b*food_mod.a, house_mod.b*house_mod.a, house_mod.a+food_mod.a)
	pheromon_display[tmp_x][tmp_y].modulate = house_mod.blend(food_mod)

func set_pheromon_displayed(is_displayed: bool) -> void:
	for sprite in get_node("Pheromons").get_children():
		sprite.visible = is_displayed
		
func _on_pheromon_spawn(tmp_x: int, tmp_y: int, type: int):
	if type == 0:
		if pheromon_house_map[tmp_x][tmp_y] < 0:
			pheromon_house_map[tmp_x][tmp_y] = 200
		else:
			pheromon_house_map[tmp_x][tmp_y] += 200
	elif type == 1:
		if pheromon_food_map[tmp_x][tmp_y] < 0:
			pheromon_food_map[tmp_x][tmp_y] = 200
		else:
			pheromon_food_map[tmp_x][tmp_y] += 200
	modulate_pheromon_display(tmp_x, tmp_y)
