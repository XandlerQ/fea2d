@tool
extends Node
# Player rotation controller.
# Controls Player rotation via controling entity rotation component of the Player.
# Controls Player rotation state changes.
# Controls the Player rotation.
class_name CPlayerRotationController

const STATE_TARGET: StringName = &"target_thf"
const STATE_LOOK_AT: StringName = &"look_at_thf"

#region Signals

#endregion

#region Exports
## CEntityRotation node reference
@export var cer: CEntityRotation = null

## CEntityLocomotion node reference
@export var cel: CEntityLocomotion = null

## CPlayerActionInput node reference
@export var cpai: CPlayerActionInput = null
#endregion

#region State

#endregion

#region Methods
#region System
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	assert(cer != null, 
		("CEntityRotation cer of CPlayerRotationController must be non null.")
	)
	assert(cel != null, 
		("CEntityLocomotion cer of CPlayerRotationController must be non null.")
	)
	assert(cpai != null,
		("CPlayerActionInput cpai of CPlayerRotationController must be non null.")
	)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# Get attack input
	var attackInput = cpai.get_attack_pressed()

	if attackInput:
		cer.globTarget = cpai.get_targetted_point()
		cer.request_state_change(STATE_LOOK_AT)
	else:
		cer.targetRotation = cel._lnzDirection.angle()
		cer.request_state_change(STATE_TARGET)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not cer:
		warnings.append("An entity rotation component is required.")
	if not cel:
		warnings.append("An entity locomotion component is required.")
	if not cpai:
		warnings.append("A player action input component is required.")
	return warnings
#endregion

#region Interface

#endregion

#region Private

#endregion
#endregion
