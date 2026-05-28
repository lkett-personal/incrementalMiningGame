class_name EconomyManager
extends Node

signal coins_changed(new_amount)

var coins: int = 0

func add_coins(amount: int) -> void:
	coins += amount

	coins_changed.emit(coins)
