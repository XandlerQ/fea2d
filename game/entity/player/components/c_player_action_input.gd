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

## Center of the fixed mouse control circle, expressed as a ratio of the
## viewport size.
@export var targetCircleCenterRatio: Vector2 = Vector2(0.5, 0.5)
## Radius of the fixed mouse control circle, expressed as a ratio of the
## viewport's shorter side.
@export_range(0.01, 1.) var targetCircleRadiusRatio: float = 0.35
#endregion

#region State
## Cached mouse target position within the unit control circle.
var unitTargettedPoint: Vector2 = Vector2.ZERO
#endregion

#region Methods
#region System
func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var circleCenter: Vector2 = get_target_circle_center()
	var circleRadius: float = get_target_circle_radius()
	var mousePosition: Vector2 = get_viewport().get_mouse_position()

	unitTargettedPoint = ((mousePosition - circleCenter) / maxf(circleRadius, 1e-5)).limit_length(1.)
#endregion

#region Interface
func get_attack_pressed() -> bool:
	return Input.is_action_pressed("Attack")

## Returns the mouse target mapped into the fixed unit control circle.
func get_unit_targetted_point() -> Vector2:
	return unitTargettedPoint

## Returns the center of the fixed mouse control circle in viewport space.
func get_target_circle_center() -> Vector2:
	return get_viewport().get_visible_rect().size * targetCircleCenterRatio

## Returns the radius of the fixed mouse control circle in viewport space.
func get_target_circle_radius() -> float:
	var viewportSize: Vector2 = get_viewport().get_visible_rect().size
	return minf(viewportSize.x, viewportSize.y) * targetCircleRadiusRatio

## Returns the mouse position as a global world-space target point.
func get_global_targetted_point() -> Vector2:
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
