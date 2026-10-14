extends Node2D
class_name Level

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("End Simulation"):
		get_tree().quit();
