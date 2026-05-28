extends TileMapLayer

@export var economy: EconomyManager
@export var upgrades: UpgradeManager

@onready var floating_layer = (
	$"../../Effects/FloatingTextLayer"
)

const FLOATING_TEXT = preload(
	"res://scenes/damage_indicator.tscn"
)

signal tile_broken(cell, tile_data)

var mine_cooldown := 0.0

var tiles: Dictionary[Vector2i, CellData] = {}

var map_width := 16
var map_height := 16

var current_layer := "CAVERN"

var variation_noise := FastNoiseLite.new()

func _ready() -> void:
	variation_noise.seed = randi()
	variation_noise.frequency = 0.05

	generate_map(map_width, map_height)

func _physics_process(delta: float) -> void:
	try_mine_tile(delta)
	update_respawns(delta)

func update_respawns(delta: float) -> void:
	for cell in tiles:
		var tile: CellData = tiles[cell]

		if tile.health > 0:
			continue

		tile.respawn_timer -= delta

		if tile.respawn_timer <= 0:
			refill_tile(cell)

func generate_map(width: int, height: int) -> void:
	var cell_x = width / 2
	var cell_y = height / 2

	var wave_cells := {}

	for x in width:
		for y in height:
			var cell := Vector2i(x - cell_x, y - cell_y)

			var dist = max(abs(cell.x), abs(cell.y))

			if not wave_cells.has(dist):
				wave_cells[dist] = []

			wave_cells[dist].append(cell)

	for dist in wave_cells.keys():
		for cell in wave_cells[dist]:
			create_tile(cell)

			animate_tile(cell)

		await get_tree().create_timer(0.1).timeout

func create_tile(cell: Vector2i) -> void:
	var tile := generate_tile_data(cell)

	tiles[cell] = tile

	if tile.is_ore:
		set_cell(cell, 0, tile.ore_atlas)
	else:
		set_cells_terrain_connect(
			[cell],
			0,
			tile.terrain
		)

func refill_tile(cell: Vector2i) -> void:
	create_tile(cell)

	animate_tile(cell)

func generate_tile_data(cell: Vector2i) -> CellData:
	var tile := CellData.new()

	var noise_val := (
		variation_noise.get_noise_2d(cell.x, cell.y) + 1.0
	) / 2.0

	noise_val += randf_range(-0.2, 0.2)
	noise_val = clamp(noise_val, 0.0, 1.0)

	var layer_data = TerrainDatabase.LAYERS[current_layer]

	var terrain_id = TerrainDatabase.TERRAINS["DIRT"]

	for terrain_name in layer_data["terrains"]:
		if noise_val <= layer_data["terrains"][terrain_name]:
			terrain_id = TerrainDatabase.TERRAINS[terrain_name]
			break

	tile.terrain = terrain_id

	var terrain_name = TerrainDatabase.TERRAINS.find_key(
		terrain_id
	)

	tile.health = TerrainDatabase.TILE_HEALTH[
		terrain_name
	]

	var ore_valid_terrains = [
		TerrainDatabase.TERRAINS["STONE"],
		TerrainDatabase.TERRAINS["FUNGAL_STONE"],
		TerrainDatabase.TERRAINS["BASALT"]
	]

	var is_ore = (
		terrain_id in ore_valid_terrains
		and randf() <= layer_data["ore_chance"]
	)

	if is_ore:
		var ore_data = layer_data["ores"].pick_random()

		tile.is_ore = true
		tile.ore_atlas = ore_data["atlas"]
		tile.ore_value = ore_data["value"]

	return tile

func try_mine_tile(delta: float) -> void:
	if mine_cooldown > 0:
		mine_cooldown -= delta
	else:
		mine_cooldown = upgrades.mining_speed
		mine_tile(upgrades.mining_power)

func mine_tile(damage: int) -> void:
	var mouse_pos_global := get_global_mouse_position()

	var mouse_pos_local := to_local(
		mouse_pos_global
	)

	var mouse_pos_tile := local_to_map(
		mouse_pos_local
	)

	if mouse_pos_tile in tiles:
		damage_tile(mouse_pos_tile, damage)

func damage_tile(cell: Vector2i, damage: int) -> void:
	var tile: CellData = tiles[cell]

	if tile.health <= 0:
		return
		
	spawn_damage_number(cell, damage)

	tile.health -= damage

	if tile.health <= 0:
		break_tile(cell)
	else:
		animate_tile(cell)

func break_tile(cell: Vector2i) -> void:
	var tile: CellData = tiles[cell]

	tile_broken.emit(cell, tile)

	if tile.is_ore:
		economy.add_coins(tile.ore_value)

	set_cells_terrain_connect(
		[cell],
		0,
		-1,
		false
	)

	tile.health = 0
	tile.respawn_timer = 3.0

func animate_tile(cell: Vector2i) -> void:
	var source_id := get_cell_source_id(cell)

	if source_id == -1:
		return

	var tween = create_tween()

	var source: TileSetAtlasSource = (
		tile_set.get_source(source_id)
	)

	var atlas_coords = get_cell_atlas_coords(cell)

	var tile_region: Rect2i = (
		source.get_tile_texture_region(atlas_coords)
	)

	var full_tex: Texture2D = source.texture

	var full_image: Image = full_tex.get_image()

	var tile_image: Image = (
		full_image.get_region(tile_region)
	)

	var image_tex := (
		ImageTexture.create_from_image(tile_image)
	)

	var tmp_sprite := Sprite2D.new()

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

	tween.finished.connect(
		func():
			tmp_sprite.queue_free()
	)
	
func spawn_damage_number(
	cell: Vector2i,
	damage: int
) -> void:

	var popup = FLOATING_TEXT.instantiate()

	popup.position = map_to_local(cell)

	floating_layer.add_child(popup)

	popup.setup(str(damage))
