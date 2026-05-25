extends TileMapLayer

var map_width: int = 8	
var map_height: int = 8

var dirt_weight: float = 0.5
var stone_weight: float = 0.2

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

var terrain = {}

var power: int = 1

func _ready() -> void:
	generate_noise(map_width, map_height)
	
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
		
			if variation_noise_normalized <= 0.33:
				terrain = TERRAINS["DIRT"]
				set_cells_terrain_connect([Vector2i(x - cell_x, y - cell_y)], 0, TERRAINS["DIRT"])
			elif variation_noise_normalized <= 0.66:
				terrain = TERRAINS["STONE"]
				set_cells_terrain_connect([Vector2i(x - cell_x, y - cell_y)], 0, TERRAINS["STONE"])
			else:
				terrain = TERRAINS["CLAY"]
				set_cells_terrain_connect([Vector2i(x - cell_x, y - cell_y)], 0, TERRAINS["CLAY"])
				
			await animate_tile(Vector2i(x - cell_x, y - cell_y), terrain)
		
func animate_tile(cell: Vector2i, _terrain_set: int):
	var tween = create_tween()
	var tmp_sprite = Sprite2D.new()
	tmp_sprite.texture = load('res://sprites/particles/dust.png')
	tmp_sprite.position = cell * 8
	tmp_sprite.scale = Vector2.ZERO
	
	add_child(tmp_sprite)
	
	tween.tween_property(tmp_sprite, "scale", Vector2.ONE * 1.4, 0.04)
	tween.tween_property(tmp_sprite, "scale", Vector2.ONE, 0.1)
	await get_tree().create_timer(0.14).timeout
	tmp_sprite.queue_free()

#func damage_tile(cell: Vector2i, damage: int):
#	pass
	
	
