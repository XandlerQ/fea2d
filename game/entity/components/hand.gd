extends Node2D
class_name Hand

#region Signals

#endregion

#region Exports

#endregion

#region State
## Previous hand global position
var prevGlobPos: Vector2 = Vector2.ZERO
## Estimated linear velocity of the hand
var velocity: Vector2 = Vector2.ZERO
#endregion

#region Methods
#region System
func _ready() -> void:
	# Set the previous position to be the same as initial position
	prevGlobPos = global_position

func _physics_process(delta: float) -> void:
	# Estimate the velocity of the hand
	var d: Vector2 = global_position - prevGlobPos
	velocity =  d / delta

	# Save current location for the next physics frame
	prevGlobPos = global_position
#endregion

#region Interface

#endregion

#region Private

#endregion
#endregion
