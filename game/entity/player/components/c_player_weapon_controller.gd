extends Node
class_name CPlayerWeaponController

#region Signals

#endregion

#region Exports
## Player reference
@export var player: Player

## Weapon node reference
@export var weapon: Weapon = null

## CPlayerActionInput node reference
@export var cpai: CPlayerActionInput = null

## Interpolation ratio between the target rotation from the input
## and the target rotation from the weapon current position.
## For 0.0 only the weapon position is used.
## For 1.0 only the input is used
@export var tRRatio: float = 0.4

# @export var weaponIdleRotation: float = PI / 8.
#endregion

#region State

#endregion

#region Methods
#region System
func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	if not weapon:
		return
	# Handle the weapon movement state change
	
	# Get attack input
	var attackInput = cpai.get_attack_pressed()

	if not attackInput:
		if not weapon.wmrc.returned:
			weapon.wmrc.request_movement_state_change("Return")
			# print("Return")
		else:
			weapon.wmrc.request_movement_state_change("Idle")
			# print("Idle")
	else:
		# For the player the weapon target is the global mouse position
		# Save the target for the weapon movement stated to use
		# TODO: move to the player input component to handle controller input as well
		weapon.wmrc.wTarget = cpai.get_targetted_point()

		weapon.wmrc.request_movement_state_change("Attack")
		# print("Attack")
	

	# Handle the weapon rotation
	# Single state, spring-based target angle rotation
	if not attackInput:
		# Align the handle orientation with the hand during idle and return.
		weapon.wmrc.target_rotation(weapon.hand.global_rotation)
		# weapon.wmrc.target_rotation(player.rcRef.targetRotation)
	else:
		# Compute a rotation as a ratia of targeted point rotation
		# and the rotation derived from weapon location
		var targetPRotation: float = (cpai.get_targetted_point() - player.global_position).angle()
		var weaponPosRotation: float = (weapon.global_position - player.global_position).angle()

		var targetRotation: float = lerp_angle(weaponPosRotation, targetPRotation, tRRatio)

		weapon.wmrc.target_rotation(targetRotation)

	
#endregion

#region Interface

#endregion

#region Private

#endregion
#endregion
