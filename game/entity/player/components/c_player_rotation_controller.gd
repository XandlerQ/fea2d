extends Node
# Player rotation controller.
# Controls Player rotation via controling entity rotation component of the Player.
# Controls Player rotation state changes.
# Controls the Player rotation.
class_name CPlayerRotationController

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
	assert(cer != null, 
		("CEntityRotation cer of CPlayerRotationController must be non null.")
	)
	assert(cel != null, 
		("CEntityLocomotion cer of CPlayerRotationController must be non null.")
	)


func _physics_process(_delta: float) -> void:
	# Get attack input
	var attackInput = cpai.get_attack_pressed()

	if attackInput:
		cer.globTarget = cpai.get_targetted_point()
		cer.request_state_change("LookatTHF")
	else:
		cer.targetRotation = cel._lnzDirection.angle()
		cer.request_state_change("TargetTHF")
#endregion

#region Interface

#endregion

#region Private

#endregion
#endregion
