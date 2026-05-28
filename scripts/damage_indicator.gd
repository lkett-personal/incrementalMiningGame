extends Node2D

@onready var label = $Label

func setup(text_value: String) -> void:
	label.text = text_value

	var tween = create_tween()

	tween.tween_property(
		self,
		"position:y",
		position.y - 24,
		0.5
	)

	tween.parallel().tween_property(
		self,
		"modulate:a",
		0.0,
		0.5
	)

	tween.finished.connect(queue_free)
