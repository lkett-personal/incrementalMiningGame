extends TileMapLayer

var map_width: int = 16
var map_height: int = 16

var dirt_weight: float = 0.33
var stone_weight: float = 0.66

const TERRAINS = {
	"DIRT": 0,
	"CLAY": 1,
	"STONE": 2
}

const TILE_HEALTH = {
	"DIRT": 3,
	"CLAY": 5,
	"STONE": 8
}

var terrain: int;
var tile_health: Dictionary[Vector2i, int] = {}

var power: int = 1

func _ready() -> void:
	generate_noise(map_width, map_height)
	
func _physics_process(_delta: float) -> void:
	mine_tile(power)

func generate_noise(width: int, height: int) -> void:
	var variation_noise := FastNoiseLite.new()
	
	variation_noise.seed = randi()
	variation_noise.frequency = 0.05
	
	for x in width:
		for y in height:
			var variation_noise_raw := variation_noise.get_noise_2d(x, y)
			var variation_noise_normalized := (variation_noise_raw + 1.0) / 2.0
			
			var cell_x = (width / 2)
			var cell_y = (height / 2)
			
			var cell = Vector2i(x - cell_x, y - cell_y)
		
			if variation_noise_normalized <= dirt_weight:
				terrain = TERRAINS["DIRT"]
				init_tile_health(Vector2i(cell), terrain)
				set_cells_terrain_connect([cell], 0, TERRAINS["DIRT"])
			elif variation_noise_normalized <= stone_weight:
				terrain = TERRAINS["STONE"]
				init_tile_health(Vector2i(cell), terrain)
				set_cells_terrain_connect([cell], 0, TERRAINS["STONE"])
			else:
				terrain = TERRAINS["CLAY"]
				init_tile_health(Vector2i(cell), terrain)
				set_cells_terrain_connect([cell], 0, TERRAINS["CLAY"])
				
			await animate_tile(Vector2i(cell), terrain)	
			
func animate_tile(cell: Vector2i, _terrain_set: int) -> void:
	var tween = create_tween()
	var tmp_sprite = Sprite2D.new()
	
	var source_id := get_cell_source_id(cell)
	
	if source_id == -1:
		return
		
	var source : TileSetAtlasSource = tile_set.get_source(source_id)
	
	var atlas_coords = get_cell_atlas_coords(cell)
	var tile_region: Rect2i = source.get_tile_texture_region(atlas_coords)
	var full_tex: Texture2D = source.texture
	var full_image: Image = full_tex.get_image()
	var tile_image: Image = full_image.get_region(tile_region)
	var image_tex := ImageTexture.create_from_image(tile_image)
	
	tmp_sprite.texture = image_tex
	tmp_sprite.position = map_to_local(cell)
	tmp_sprite.scale = Vector2.ZERO 
	
	add_child(tmp_sprite)
	
	tween.tween_property(tmp_sprite, "scale", Vector2.ONE * 1.4, 0.04)
	tween.tween_property(tmp_sprite, "scale", Vector2.ONE, 0.1)
	await tween.finished
	
	tmp_sprite.queue_free()
	
func mine_tile(damage: int) -> void:
	var mouse_pos_global: Vector2 = get_global_mouse_position()
	var mouse_pos_local: Vector2 = to_local(mouse_pos_global)
	var mouse_pos_tile: Vector2i = local_to_map(mouse_pos_local)
	
	if mouse_pos_tile in tile_health:
		damage_tile(mouse_pos_tile, damage)
		print("kill dat boy!!")

func damage_tile(cell: Vector2i, damage: int) -> void:
	var health = get_tile_health(cell)
	
	tile_health[cell] -= damage
	
	if health <= 0:
		break_tile(cell)
	
func break_tile(cell: Vector2i):
	tile_health.erase(cell)
	set_cells_terrain_connect([cell], 0, -1, false)
	
func init_tile_health(cell: Vector2i, terrain_id: int) -> void:
	if terrain_id == TERRAINS["DIRT"]:
		tile_health[cell] = 3
	elif terrain_id == TERRAINS["CLAY"]:
		tile_health[cell] = 4
	elif terrain_id == TERRAINS["STONE"]:
		tile_health[cell] = 5
	
func set_tile_health(cell: Vector2i, health: int) -> void:
	if cell in tile_health:
		tile_health[cell] = health
		
func get_tile_health(cell: Vector2i) -> int:
	if cell in tile_health:
		return tile_health[cell]
	else:
		return -1
