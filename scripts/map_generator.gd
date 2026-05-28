extends TileMapLayer

const TERRAINS = {
	"DIRT": 0,
	"CLAY": 1,
	"STONE": 2,

	"MOSS": 3,
	"FUNGAL_STONE": 4,
	"MYCELIUM": 5,

	"ASH": 6,
	"BASALT": 7,
	"MAGMA_ROCK": 8
}

const TILE_HEALTH = {
	"DIRT": 2,
	"CLAY": 3,
	"STONE": 4,

	"MOSS": 8,
	"FUNGAL_STONE": 12,
	"MYCELIUM": 16,

	"ASH": 24,
	"BASALT": 46,
	"MAGMA_ROCK": 64
}

const LAYERS = {
	"CAVERN": {
		"terrains": {
			"DIRT": 0.33,
			"STONE": 0.66,
			"CLAY": 1.0
		},
		"ores": [
			Vector2i(1, 12),
			Vector2i(2, 12),
			Vector2i(3, 12)
		],
		"ore_chance": 0.1
	},

	"FUNGAL": {
		"terrains": {
			"MOSS": 0.33,
			"FUNGAL_STONE": 0.66,
			"MYCELIUM": 1.0
		},
		"ores": [
			Vector2i(5, 12)
		],
		"ore_chance": 0.1
	},

	"MAGMA": {
		"terrains": {
			"ASH": 0.33,
			"BASALT": 0.66,
			"MAGMA_ROCK": 1.0
		},
		"ores": [
			Vector2i(9, 12)
		],
		"ore_chance": 0.15
	}
}

var tile_health: Dictionary[Vector2i, int] = {}
var broken_tiles: Dictionary[Vector2i, Array] = {}
var tile_terrain: Dictionary[Vector2i, int] = {}

var map_width: int = 16
var map_height: int = 16

var power: int = 1
var mine_cooldown: float = 0.1

var variation_noise := FastNoiseLite.new()

var current_layer = "MAGMA"

func _ready() -> void:
	variation_noise.seed = randi()
	variation_noise.frequency = 0.05

	generate_map(map_width, map_height)

func _physics_process(delta: float) -> void:
	try_mine_tile(delta)

	var refill_queue: Array[Vector2i] = []

	for cell in broken_tiles:
		broken_tiles[cell][0] -= delta

		if broken_tiles[cell][0] <= 0:
			refill_queue.append(cell)

	for cell in refill_queue:
		broken_tiles.erase(cell)

		refill_tile(cell)
		await animate_tile(cell)

func generate_tile_data(cell: Vector2i) -> Dictionary:
	var noise_val := (
		variation_noise.get_noise_2d(cell.x, cell.y) + 1.0
	) / 2.0

	# allows terrain mutation over time
	noise_val += randf_range(-0.2, 0.2)
	noise_val = clamp(noise_val, 0.0, 1.0)

	var layer_data = LAYERS[current_layer]

	var terrain_id = TERRAINS["DIRT"]

	for terrain_name in layer_data["terrains"]:
		if noise_val <= layer_data["terrains"][terrain_name]:
			terrain_id = TERRAINS[terrain_name]
			break

	var is_ore = randf() <= layer_data["ore_chance"]

	var ore_atlas = null

	if is_ore:
		ore_atlas = layer_data["ores"].pick_random()

	return {
		"terrain": terrain_id,
		"ore": is_ore,
		"ore_atlas": ore_atlas
	}

func generate_map(width: int, height: int) -> void:
	var cell_x = width / 2
	var cell_y = height / 2

	var wave_cells: Dictionary = {}

	for x in width:
		for y in height:
			var cell := Vector2i(x - cell_x, y - cell_y)

			var dist = max(abs(cell.x), abs(cell.y))

			if not wave_cells.has(dist):
				wave_cells[dist] = []

			wave_cells[dist].append(cell)

	for dist in wave_cells.keys():
		for cell in wave_cells[dist]:

			var tile_data = generate_tile_data(cell)

			init_tile_health(cell, tile_data["terrain"])

			generate_tile(
				cell,
				tile_data["terrain"],
				tile_data["ore"],
				tile_data["ore_atlas"]
			)

			animate_tile(cell)

		await get_tree().create_timer(0.1).timeout

func generate_tile(
	cell: Vector2i,
	terrain_id: int,
	is_ore: bool,
	ore_atlas
) -> void:

	if not is_ore:
		set_cells_terrain_connect([cell], 0, terrain_id)
	else:
		set_cell(cell, 0, ore_atlas)

func refill_tile(cell: Vector2i) -> void:
	var tile_data = generate_tile_data(cell)

	init_tile_health(cell, tile_data["terrain"])

	generate_tile(
		cell,
		tile_data["terrain"],
		tile_data["ore"],
		tile_data["ore_atlas"]
	)

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

	tween.tween_property(
		tmp_sprite,
		"scale",
		Vector2.ONE * 1.4,
		0.04
	)

	tween.tween_property(
		tmp_sprite,
		"scale",
		Vector2.ONE,
		0.04
	)

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

func place_tile(cell: Vector2i, terrain: int) -> void:
	set_cells_terrain_connect([cell], 0, terrain)

func init_tile_health(cell: Vector2i, terrain_id: int) -> void:
	var terrain_name = TERRAINS.find_key(terrain_id)

	if terrain_name and terrain_name in TILE_HEALTH:
		tile_health[cell] = TILE_HEALTH[terrain_name]
		tile_terrain[cell] = terrain_id

func get_tile_health(cell: Vector2i) -> int:
	if cell in tile_health:
		return tile_health[cell]

	return -1
