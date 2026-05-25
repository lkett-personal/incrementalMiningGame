extends TileMapLayer

var map_width: int = 4
var map_height: int = 4

const TERRAINS = {
	"DIRT": 0,
	"CLAY": 1,
	"STONE": 2
}

func _ready() -> void:
	generate_map(map_width, map_height)
	
func generate_map(width: int, height: int) -> void:
	for x in width:
		for y in height:
			set_cells_terrain_connect([Vector2i(x, y)], 0, TERRAINS["DIRT"])
			
