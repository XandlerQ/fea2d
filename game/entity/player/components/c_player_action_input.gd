@tool
extends Node
## Defines an interface to get inputs
## for player actions.
class_name CPlayerActionInput

#region Signals

#endregion

#region Exports
## Player reference
@export var player: Player = null
#endregion

#region State

#endregion

#region Methods
#region System

#endregion

#region Interface
func get_attack_pressed() -> bool:
	return Input.is_action_pressed("Attack")

func get_targetted_point() -> Vector2:
	return player.get_global_mouse_position()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not player:
		warnings.append("A Player reference is required.")
	return warnings

#endregion

#region Private

#endregion
#endregion
