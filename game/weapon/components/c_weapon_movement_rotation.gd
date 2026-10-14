extends Node
## Weapon movement/rotation component.
## Holds and controls both wPosition
## and wVelocity of a weapon, as well as
## weapon rotaiton.
class_name CWeaponMovementRotation

#region Signals

#endregion

#region Exports
## Controlled weapon
@export var weapon: Weapon = null

## Weapon movement Finite State Machine
@export var fsmlM: FSML = null
#endregion

#region State
## Weapon wVelocity
var wVelocity: Vector2 = Vector2.ZERO
## Weapon position
var wPosition: Vector2 = Vector2.ZERO

## Weapon return status
var returned: bool = false

## Weapon target position.
## Used by the Attack state to determine the weapon movement
var wTarget: Vector2 = Vector2.ZERO

## Current rotation
var rotation: float = 0.
## Target rotation
var targetRotation: float = 0.
## Angular velocity
var angularVelocity: float = 0.

## Spring angular velocity.
## Used similar to attackVelocity for Attack movement state.
## Needed to avoid stacking of inherited velocity,
## with only springAngularVelocity integrated according to the
## angular acceleration, and then 
## angularVelocity = springAngularVelocity + inheritedAngVelocity
var springAngularVelocity: float = 0.

## Weapon rotation inertia
var inertia: float = 1.
#endregion

#region Methods
#region System
func _ready() -> void:
	# Align the handle orientation before computing the initial origin position.
	rotation = weapon.hand.global_rotation - get_handle_rotation_offset()
	weapon.global_rotation = rotation
	wPosition = weapon.hand.global_position - get_handle_offset()
	weapon.global_position = wPosition

	inertia = weapon.movementInertia

func _physics_process(delta: float) -> void:
	fsmlM.physics_update(delta)
	_control_object()
#endregion

#region Interface
## Returns the current offset of the handle relative to the weapon
## scene origin (CoM)
func get_handle_offset() -> Vector2:
	var handleOffset: Vector2 = weapon.handle.position.rotated(rotation)
	return handleOffset


## Returns the handle rotation offset
func get_handle_rotation_offset() -> float:
	return weapon.handle.rotation


## Sets a given rotation as a target rotation taking the handle rotation
## into account
func target_rotation(pRotation: float) -> void:
	targetRotation = pRotation - get_handle_rotation_offset()

## Applies the selected side of the given PhysicsCollisionResult2D taking
## current movement state into account
func apply_collision_response(result: PhysicsCollisionResult2D, side: PhysicsCollisionInfo2D.Side = PhysicsCollisionInfo2D.Side.SOURCE) -> void:
	# If the collision is not resolved or the result is invalid
	if not result or not result.resolved or not fsmlM:
		return
	# Make sure that we are in the state that can be affected by a collision
	if not fsmlM.get_state_name() == "Attack":
		return

	var attackState: StWeaponMovementAttack = fsmlM.state as StWeaponMovementAttack
	if not attackState:
		return

	# Apply position correction in any case
	var isSource: bool = side == PhysicsCollisionInfo2D.Side.SOURCE
	wPosition += result.posCorrS if isSource else result.posCorrT

	# Change kinematic properties only is not separating
	# NOTE THAT THE UPDATES ARE APPLIED DIRECTLY, SO THEY
	# DEPEND ON THE VALUES OF THE ATTACK MASS AND ATTACK INERTIA,
	# NOT THE VALUES USED FOR MOVEMENT
	if not result.separating:
		# Attack rebuilds wVelocity from attackVel and inherited wielder motion
		# Apply the impulse to both for the impulse change to persist
		var deltaVelocity: Vector2 = result.dVelS if isSource else result.dVelT
		attackState.attackVel += deltaVelocity
		wVelocity += deltaVelocity
		# Apply the angular velocity change
		var deltaAngularVelocity: float = result.dAngVelS if isSource else result.dAngVelT
		angularVelocity += deltaAngularVelocity
		springAngularVelocity += deltaAngularVelocity

	# Call the control object method to apply the changes to the engine kinematic values
	_control_object()

func request_movement_state_change(newState: String, data: Dictionary = {}) -> void:
	if fsmlM.state.is_interruptible() or (not fsmlM.state.is_interruptible() and fsmlM.state.completed):
		fsmlM.change_state(fsmlM.state, newState, data)
#endregion

#region Private
func _control_object() -> bool:
	# Pass the kinematic state
	weapon.velocity = wVelocity
	weapon.angularVelocity = angularVelocity
	weapon.global_rotation = rotation
	weapon.global_position = wPosition
	return true
#endregion
#endregion
