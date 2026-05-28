class_name TerrainDatabase

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
			{
				"atlas": Vector2i(1, 12),
				"value": 1
			},
			{
				"atlas": Vector2i(2, 12),
				"value": 2
			},
			{
				"atlas": Vector2i(3, 12),
				"value": 4
			}
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
			{
				"atlas": Vector2i(5, 12),
				"value": 8
			}
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
			{
				"atlas": Vector2i(9, 12),
				"value": 16
			}
		],
		"ore_chance": 0.15
	}
}
