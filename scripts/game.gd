extends Node

@onready var economy = $Managers/EconomyManager
@onready var ui = $UI

func _ready() -> void:
	print_tree_pretty()
	
	economy.coins_changed.connect(
		ui.update_coins
	)

	ui.update_coins(economy.coins)
