extends CanvasLayer

@onready var coins_label = $CoinsLabel
@export var upgrades: UpgradeManager
@export var power_button: Button
@export var upgrade_ui: Control

func update_coins(amount: int) -> void:
	coins_label.text = "coins: " + str(amount)
	
func _on_power_pressed() -> void:
	upgrades.buy_power()
	
	power_button.text = (
		"power lv." + str(upgrades.power_level)
		+ "\ncost: " + str(upgrades.power_cost)
	)
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_accept"):
		upgrade_ui.visible = !upgrade_ui.visible
