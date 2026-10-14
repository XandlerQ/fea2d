@tool
extends Node
# Player locomotion controller.
# Controls Player locomotion via controling entity locomotion component of the Player.
# Controls Player locomotion state changes.
# Controls the Player locomotion direction.
class_name CPlayerLocomotionController

const STATE_IDLE: StringName = &"idle"
const STATE_WALK: StringName = &"walk"
const STATE_SPRINT: StringName = &"sprint"
const STATE_DASH: StringName = &"dash"

#region Signals

#endregion

#region Exports
## CPlayerLocomotionInput node reference
@export var pli: CPlayerLocomotionInput = null
## CEntityLocomotion node reference
@export var cel: CEntityLocomotion = null
#endregion

#region State

#endregion

#region Methods
#region System
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	assert(pli != null, 
		("CPlayerLocomotionInput pli of CPlayerLocomotionController must be non null.")
	)
	assert(cel != null, 
		("CEntityLocomotion cel of CPlayerLocomotionController must be non null.")
	)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Get input direction
	var inDir: Vector2 = pli.get_movement_direction_input()
	# If some input
	if inDir.length_squared() > 1e-10:
		# Pass the input direction to the locomotion component
		cel.direction = inDir
	else:
		cel.direction = Vector2.ZERO
		cel.request_state_change(STATE_IDLE)
		return

	# Handle dash
	if pli.get_dash_just_pressed():
		cel.request_state_change(STATE_DASH)
		return
	# If sprint key is held
	if pli.get_sprint_pressed():
		cel.request_state_change(STATE_SPRINT)
		return
	# Walk
	cel.request_state_change(STATE_WALK)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not pli:
		warnings.append("A player locomotion input component is required.")
	if not cel:
		warnings.append("An entity locomotion component is required.")
	return warnings
#endregion

#region Interface

#endregion

#region Private

#endregion
#endregion
