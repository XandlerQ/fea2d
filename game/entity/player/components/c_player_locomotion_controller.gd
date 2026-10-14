extends Node
# Player locomotion controller.
# Controls Player locomotion via controling entity locomotion component of the Player.
# Controls Player locomotion state changes.
# Controls the Player locomotion direction.
class_name CPlayerLocomotionController

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
	assert(pli != null, 
		("CPlayerLocomotionInput pli of CPlayerLocomotionController must be non null.")
	)
	assert(cel != null, 
		("CEntityLocomotion cel of CPlayerLocomotionController must be non null.")
	)


func _physics_process(_delta: float) -> void:
	# Get input direction
	var inDir: Vector2 = pli.get_movement_direction_input()
	# If some input
	if inDir.length_squared() > 1e-10:
		# Pass the input direction to the locomotion component
		cel.direction = inDir
	else:
		cel.direction = Vector2.ZERO
		cel.request_state_change("Idle")
		return

	# Handle dash
	if pli.get_dash_just_pressed():
		cel.request_state_change("Dash")
		return
	# If sprint key is held
	if pli.get_sprint_pressed():
		cel.request_state_change("Sprint")
		return
	# Walk
	cel.request_state_change("Walk")
#endregion

#region Interface

#endregion

#region Private

#endregion
#endregion
