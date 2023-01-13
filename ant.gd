extends Node2D

const World = preload("res://world1.gd")

enum ACTION_STATE {SEEK_FOOD, GATHER_FOOD, RETURN_HOME}
@onready var world = get_tree().get_root().get_node("World")
@onready var tile_map: TileMap = get_tree().get_root().get_node("World/TileMap")
var tileX = 0
var tileY = 0
var path_start_position: Vector2
var path_end_position: Vector2
var path_factor: float
var direction: int = 0

var current_state: ACTION_STATE = ACTION_STATE.SEEK_FOOD
var carrying_food: bool = false
signal pheromon_spawn

func _ready():
	var world = get_tree().get_root().get_node("World")
	self.pheromon_spawn.connect(Callable(world, "_on_pheromon_spawn"))
	$Label.text = ACTION_STATE.keys()[current_state]

func pick_new_state(start_pos):
	if current_state == ACTION_STATE.SEEK_FOOD:
		var food_position: Vector2i = check_food_neighbouring_cells(start_pos, get_possible_directions(start_pos))
		if food_position != Vector2i(-1,-1):
			tile_map.erase_cell(1, food_position)
			carrying_food = true
			current_state = ACTION_STATE.RETURN_HOME
			direction = (direction+4 + 8) % 8
			$Label.text = ACTION_STATE.keys()[current_state]
			update_visuals()
	if current_state == ACTION_STATE.RETURN_HOME:
		if tile_map.get_cell_alternative_tile(0, Vector2i(path_start_position.x,path_start_position.y)) == 1:
			carrying_food = false
			current_state = ACTION_STATE.SEEK_FOOD
			direction = (direction+4 + 8) % 8
			update_visuals()

func _process(delta):
	if direction % 2 == 1:
		path_factor += delta*4/sqrt(2)
	else:
		path_factor += delta*4
	if path_factor >= 1:
		path_factor -= 1
		if path_factor >= 1:
			print("ERROR")
		path_start_position = path_end_position
	if path_start_position == path_end_position:
		var cell_position: Vector2i = Vector2i(path_start_position.x, path_start_position.y)
		pick_new_state(cell_position)
		if current_state == ACTION_STATE.SEEK_FOOD:
			pheromon_spawn.emit(path_start_position.x, path_start_position.y, 0)
			#var dir_off = random_next_direction_offset(path_start_position)
			#path_end_position.x = path_start_position.x + direction_to_position_offset(direction, dir_off).x
			#path_end_position.y = path_start_position.y + direction_to_position_offset(direction, dir_off).y
			path_end_position = follow_food_pheromons()
			#direction = (direction+dir_off+8) % 8
			direction = 8 * (path_end_position-path_start_position).angle() / (2*PI)
		if current_state == ACTION_STATE.RETURN_HOME:
			pheromon_spawn.emit(path_start_position.x, path_start_position.y, 1)
			path_end_position = follow_house_pheromons()
			direction = 8 * (path_end_position-path_start_position).angle() / (2*PI)
			for el in $PheromonArea.get_overlapping_areas():
				el.get_parent().modulate = Color(1.0,0.0,0.0)
		update_visuals()
	position = 8.0*path_start_position.lerp(path_end_position, path_factor) + Vector2(4,4)
	
	$EndPosition.global_position = path_end_position*8 + Vector2(4,4)

func follow_house_pheromons() -> Vector2:
	var possible_tiles: Array = []
	var result: Vector2 = Vector2(0,0)
	for i in range(-2, 3):
		for j in range(-2, 3):
			if Vector2(i,j).length() > 1.5 and i+path_start_position.x >= 0 and i+path_start_position.x < World.WORLD_SIZE_X and j+path_start_position.y >= 0 and j+path_start_position.y < World.WORLD_SIZE_Y:
				possible_tiles.append(path_start_position + Vector2(i,j))
	var tmp_intensity = 10000
	for el in possible_tiles:
		if world.pheromon_house_map[el.x][el.y] > 0:
			if world.pheromon_house_map[el.x][el.y] < tmp_intensity:
				if abs(direction - angle_to_direction((el - path_start_position).angle())) <= 10:
					tmp_intensity = world.pheromon_house_map[el.x][el.y]
					result = el
	
	if result != Vector2(0,0):
		if abs(direction - angle_to_direction((result - path_start_position).angle())) <= 1:
			var tmp_x = round(0.5 * (result.x + path_start_position.x))
			var tmp_y = round(0.5 * (result.y + path_start_position.y))
			return Vector2(tmp_x, tmp_y)
		else:
			var dir_off = random_next_direction_offset(path_start_position)
			var tmp_x = path_start_position.x + direction_to_position_offset(direction, dir_off).x
			var tmp_y = path_start_position.y + direction_to_position_offset(direction, dir_off).y
			return Vector2(tmp_x, tmp_y)
	else:
		var dir_off = random_next_direction_offset(path_start_position)
		var tmp_x = path_start_position.x + direction_to_position_offset(direction, dir_off).x
		var tmp_y = path_start_position.y + direction_to_position_offset(direction, dir_off).y
		return Vector2(tmp_x, tmp_y)

func follow_food_pheromons() -> Vector2:
	var possible_tiles: Array = []
	var result: Vector2 = Vector2(0,0)
	for i in range(-2, 3):
		for j in range(-2, 3):
			if Vector2(i,j).length() > 1.5 and i+path_start_position.x >= 0 and i+path_start_position.x < World.WORLD_SIZE_X and j+path_start_position.y >= 0 and j+path_start_position.y < World.WORLD_SIZE_Y:
				possible_tiles.append(path_start_position + Vector2(i,j))
	var tmp_intensity = 10000
	for el in possible_tiles:
		if world.pheromon_food_map[el.x][el.y] > 0:
			if world.pheromon_food_map[el.x][el.y] < tmp_intensity:
				if abs(direction - angle_to_direction((el - path_start_position).angle())) <= 10:
					tmp_intensity = world.pheromon_food_map[el.x][el.y]
					result = el
	
	if result != Vector2(0,0):
		if abs(direction - angle_to_direction((result - path_start_position).angle())) <= 1:
			var tmp_x = round(0.5 * (result.x + path_start_position.x))
			var tmp_y = round(0.5 * (result.y + path_start_position.y))
			return Vector2(tmp_x, tmp_y)
		else:
			var dir_off = random_next_direction_offset(path_start_position)
			var tmp_x = path_start_position.x + direction_to_position_offset(direction, dir_off).x
			var tmp_y = path_start_position.y + direction_to_position_offset(direction, dir_off).y
			print("Food pheromon trail is unreachable")
			return Vector2(tmp_x, tmp_y)
	else:
		var dir_off = random_next_direction_offset(path_start_position)
		var tmp_x = path_start_position.x + direction_to_position_offset(direction, dir_off).x
		var tmp_y = path_start_position.y + direction_to_position_offset(direction, dir_off).y
		print("No food pheromon trail")
		return Vector2(tmp_x, tmp_y)

func angle_to_direction(angle: float):
	return int((8*angle / (2*PI)) + 8) % 8

func random_next_direction_offset(start_pos: Vector2) -> int:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var directionOffset = rng.randi_range(-1, 1)
	var position_offset: Vector2i = direction_to_position_offset(direction, directionOffset)
	var possible_directions = get_possible_directions(start_pos)
	
	while possible_directions.find((direction+directionOffset+8)%8) == -1:
		directionOffset += 2*rng.randi_range(0,1) - 1
	
	return directionOffset

func get_possible_directions(start_pos: Vector2) -> Array:
	# Return array of possible directions according to terrain
	var possible_directions = [0,1,2,3,4,5,6,7]
	if start_pos.x < 1 or start_pos.x >= World.WORLD_SIZE_X-1 or start_pos.y < 1 or start_pos.y >= World.WORLD_SIZE_Y-1:
		if start_pos.x < 1:
			possible_directions.erase(3)
			possible_directions.erase(4)
			possible_directions.erase(5)
		if start_pos.x >= World.WORLD_SIZE_X-1:
			possible_directions.erase(7)
			possible_directions.erase(0)
			possible_directions.erase(1)
		if start_pos.y < 1:
			possible_directions.erase(5)
			possible_directions.erase(6)
			possible_directions.erase(7)
		if start_pos.y >= World.WORLD_SIZE_Y-1:
			possible_directions.erase(1)
			possible_directions.erase(2)
			possible_directions.erase(3)
	
	var direction_to_remove: Array
	for tmp_dir in possible_directions:
		var cell_position: Vector2i = Vector2i(start_pos.x + direction_to_position_offset(tmp_dir, 0).x, start_pos.y + direction_to_position_offset(tmp_dir, 0).y)
		tile_map.get_cell_tile_data(0, cell_position).get_custom_data("ground")
		if !tile_map.get_cell_tile_data(0, cell_position).get_custom_data("ground"):
			direction_to_remove.append(tmp_dir)
	
	for el in direction_to_remove:
		possible_directions.erase(el)
	
	return possible_directions

func check_food_neighbouring_cells(start_pos: Vector2i, possible_directions: Array) -> Vector2i:
	# Return tile coords of nearest food or else (-1,-1)
	var food_list: Array = []
	for dir in possible_directions:
		
		if tile_map.get_cell_tile_data(1, start_pos + direction_to_position_offset(dir, 0)) != null:
			if tile_map.get_cell_tile_data(1, start_pos + direction_to_position_offset(dir, 0)).get_custom_data("food"):
				food_list.append(start_pos + direction_to_position_offset(dir, 0))
	
	var closest_to_direction: float = 100
	var closest_food: Array = []
	for el in food_list:
		var distance = sqrt(pow(el.x - start_pos.x - direction_to_position_offset(direction, 0).x,2) + pow(el.y - start_pos.y - direction_to_position_offset(direction, 0).y,2))
		if distance <= closest_to_direction:
			if distance < closest_to_direction:
				closest_food.clear()
			closest_to_direction = distance
			closest_food.append(el)
	if closest_food.size() >= 1:
		return closest_food[randi() % closest_food.size()]
	else:
		return Vector2i(-1,-1)

func update_visuals() -> void:
	$AntSprite.rotation = 2*PI * direction / 8.0
	$AntSprite/FoodSprite.visible = carrying_food
	$PheromonArea.rotation = 2*PI * direction / 8.0

func direction_to_position_offset(tmpDirection, tmpDirectionOffset):
	var xOffset = 0
	var yOffset = 0
	match (tmpDirection+tmpDirectionOffset+8) % 8:
		0:
			xOffset = 1
			yOffset = 0
		1:
			xOffset = 1
			yOffset = 1
		2:
			xOffset = 0
			yOffset = 1
		3:
			xOffset = -1
			yOffset = 1
		4:
			xOffset = -1
			yOffset = 0
		5:
			xOffset = -1
			yOffset = -1
		6:
			xOffset = 0
			yOffset = -1
		7:
			xOffset = 1
			yOffset = -1
	var offset: Vector2i = Vector2i(xOffset, yOffset)
	return offset

func set_tile_pos(tmp_x: int, tmp_y: int) -> void:
	path_start_position = Vector2i(tmp_x,tmp_y)
	path_end_position = Vector2i(tmp_x,tmp_y)

func setTilePos(tmpX, tmpY):
	self.tileX = tmpX
	self.tileY = tmpY

func get_tile_x():
	return tileX

func get_tile_y():
	return tileY
