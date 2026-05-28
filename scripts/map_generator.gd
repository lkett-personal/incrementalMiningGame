extends TileMapLayer

const TERRAINS = {
	"DIRT": 0,
	"CLAY": 1,
	"STONE": 2
}

const TILE_HEALTH = {
	"DIRT": 2,
	"CLAY": 3,
	"STONE": 4
}

var tile_health: Dictionary[Vector2i, int] = {}
var broken_tiles: Dictionary[Vector2i, Array] = {}
var tile_terrain: Dictionary[Vector2i, int] = {}

var map_width: int = 16
var map_height: int = 16
var dirt_weight: float = 0.33
var stone_weight: float = 0.66

var power: int = 1
var mine_cooldown: float = 0.1

func _ready() -> void:
	generate_map(map_width, map_height)
	
func _physics_process(delta: float) -> void:
	try_mine_tile(delta)

func generate_map(width: int, height: int) -> void:
	var variation_noise := FastNoiseLite.new()
	
	variation_noise.seed = randi()
	variation_noise.frequency = 0.05
	
	var cell_x = (width / 2)
	var cell_y = (height / 2)

	for x in width:
		for y in height:
			var noise_val := (variation_noise.get_noise_2d(x, y) + 1.0) / 2.0
			var cell := Vector2i(x - cell_x, y - cell_y)
			var cell_terrain: int  # local, scoped to this iteration

			if noise_val <= dirt_weight:
				cell_terrain = TERRAINS["DIRT"]
			elif noise_val <= stone_weight:
				cell_terrain = TERRAINS["STONE"]
			else:
				cell_terrain = TERRAINS["CLAY"]

			init_tile_health(cell, cell_terrain)
			generate_tile(cell, cell_terrain, false)

			if cell_terrain == TERRAINS["STONE"] and randf() <= 0.1:
				generate_tile(cell, cell_terrain, true)
				
			await animate_tile(Vector2i(cell))
			
func generate_tile(cell: Vector2i, terrain_id: int, is_ore: bool) -> void:
	var ore_decision: int = randi_range(1, 3)
	
	if not is_ore:
		set_cells_terrain_connect([cell], 0, terrain_id)
	else:
		set_cell(cell, 0, Vector2i(ore_decision, 12))
			
func animate_tile(cell: Vector2i) -> void:
	
	var source_id := get_cell_source_id(cell)
	
	if source_id == -1:
		return
	
	var tween = create_tween()
		
	var source : TileSetAtlasSource = tile_set.get_source(source_id)
	
	var atlas_coords = get_cell_atlas_coords(cell)
	var tile_region: Rect2i = source.get_tile_texture_region(atlas_coords)
	var full_tex: Texture2D = source.texture
	var full_image: Image = full_tex.get_image()
	var tile_image: Image = full_image.get_region(tile_region)
	var image_tex := ImageTexture.create_from_image(tile_image)
	
	var tmp_sprite = Sprite2D.new()
	tmp_sprite.texture = image_tex
	tmp_sprite.position = map_to_local(cell)
	tmp_sprite.scale = Vector2.ZERO 
	
	add_child(tmp_sprite)
	
	tween.tween_property(tmp_sprite, "scale", Vector2.ONE * 1.4, 0.04)
	tween.tween_property(tmp_sprite, "scale", Vector2.ONE, 0.04)
	await tween.finished
	
	tmp_sprite.queue_free()
	
func try_mine_tile(delta: float) -> void:
	if mine_cooldown > 0:
		mine_cooldown -= delta
	else:
		mine_cooldown = 0.1
		mine_tile(power)
	
func mine_tile(damage: int) -> void:
	var mouse_pos_global: Vector2 = get_global_mouse_position()
	var mouse_pos_local: Vector2 = to_local(mouse_pos_global)
	var mouse_pos_tile: Vector2i = local_to_map(mouse_pos_local)
	
	if mouse_pos_tile in tile_health:
		damage_tile(mouse_pos_tile, damage)

func damage_tile(cell: Vector2i, damage: int) -> void:
	tile_health[cell] -= damage
	if tile_health[cell] <= 0:
		break_tile(cell)
	else:
		animate_tile(cell)
	
func break_tile(cell: Vector2i) -> void:
	var terrain_id = tile_terrain.get(cell, -1)
	tile_health.erase(cell)
	tile_terrain.erase(cell)
	set_cells_terrain_connect([cell], 0, -1, false)
	if terrain_id != -1:
		broken_tiles[cell] = [3.0, terrain_id]
	
func init_tile_health(cell: Vector2i, terrain_id: int) -> void:
	var terrain_name = TERRAINS.find_key(terrain_id)
	if terrain_name and terrain_name in TILE_HEALTH:
		tile_health[cell] = TILE_HEALTH[terrain_name]
		tile_terrain[cell] = terrain_id
		
func get_tile_health(cell: Vector2i) -> int:
	if cell in tile_health:
		return tile_health[cell]
	else:
		return -1
