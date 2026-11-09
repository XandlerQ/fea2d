@tool
extends Control
class_name WeaponControlVisualizer

#region Signals

#endregion

#region Exports
## Input component whose normalized target and control-circle geometry are shown.
@export var cpai: CPlayerActionInput = null

## Enables the visualization. Can be changed by an options menu at runtime.
@export var displayEnabled: bool = true
## Only displays the visualization while attack input is held.
@export var showOnlyWhileAttacking: bool = false

## Control-circle outline color.
@export var circleColor: Color = Color(0.8, 0.85, 1., 0.65)
## Control-circle outline width.
@export var circleLineWidth: float = 2.
## Number of line segments used to draw the control circle.
@export_range(16, 256, 1) var circlePointCount: int = 96

## Normalized target marker fill color.
@export var targetColor: Color = Color(0.95, 0.95, 1., 0.9)
## Normalized target marker outline color.
@export var targetOutlineColor: Color = Color(0.15, 0.2, 0.3, 0.95)
## Normalized target marker radius in viewport pixels.
@export var targetRadius: float = 5.
## Normalized target marker outline width.
@export var targetOutlineWidth: float = 2.
#endregion

#region State

#endregion

#region Methods
#region System
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	assert(cpai != null,
		("CPlayerActionInput cpai of WeaponControlVisualizer must be non null.")
	)

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var shouldDisplay: bool = displayEnabled

	if showOnlyWhileAttacking and cpai:
		shouldDisplay = shouldDisplay and cpai.get_attack_pressed()

	if visible != shouldDisplay:
		visible = shouldDisplay

	if shouldDisplay:
		queue_redraw()

func _draw() -> void:
	if not cpai:
		return

	var circleCenter: Vector2 = cpai.get_target_circle_center()
	var circleRadius: float = cpai.get_target_circle_radius()

	var targetPosition: Vector2 = circleCenter + cpai.get_unit_targetted_point() * circleRadius

	draw_arc(circleCenter, circleRadius, 0., TAU, circlePointCount,
		circleColor, circleLineWidth, true)
	
	draw_circle(targetPosition, targetRadius, targetColor)
	
	draw_arc(targetPosition, targetRadius, 0., TAU, circlePointCount,
		targetOutlineColor, targetOutlineWidth, true)
#endregion

#region Interface
func set_display_enabled(enabled: bool) -> void:
	displayEnabled = enabled

func toggle_display() -> void:
	displayEnabled = not displayEnabled

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not cpai:
		warnings.append("A player action input component is required.")
	return warnings
#endregion

#region Private

#endregion
#endregion
