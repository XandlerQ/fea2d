extends Node
## Defines an interface to get inputs
## for player movement.
class_name CPlayerLocomotionInput

#region Signals

#endregion

#region Exports

#endregion

#region State

#endregion

#region Methods
#region System

#endregion

#region Interface
func get_movement_direction_input() -> Vector2:
	return Input.get_vector("MLeft", "MRight", "MForward", "MBackward")

func get_sprint_pressed() -> bool:
	return Input.is_action_pressed("MSprint")

func get_dash_just_pressed() -> bool:
	return Input.is_action_just_pressed("MDash")
#endregion

#region Private

#endregion
#endregion
