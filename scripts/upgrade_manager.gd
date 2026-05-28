class_name UpgradeManager
extends Node

signal upgrades_updated

var mining_power := 1
var mining_speed := 0.1
var ore_luck := 1.0

var power_level := 0
var speed_level := 0
var luck_level := 0

var power_cost := 10
var speed_cost := 25
var luck_cost := 50

@export var economy: EconomyManager

func buy_power() -> void:
	if economy.coins < power_cost:
		return

	economy.coins -= power_cost

	mining_power += 1
	power_level += 1

	power_cost = int(power_cost * 1.5)

	economy.coins_changed.emit(economy.coins)
	upgrades_updated.emit()
