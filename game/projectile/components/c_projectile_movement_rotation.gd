extends Node
## Defines projectile movement and rotaiton behavior
class_name CProjectileMovementRotation

#region Signals

#endregion

#region Exports
## Controlled projectile reference
@export var projectile: Projectile = null

## Movement finite state machine reference
@export var fsmlM: FSML
## Rotation finite state machine reference
@export var fsmlR: FSML
#endregion

#region State
## Projectile position (gobal)
var position: Vector2 = Vector2.ZERO
## Full projectile current velocity
var velocity: Vector2 = Vector2.ZERO
## Launch direction (does not take inherited valocity into account,
## only the intended launch direction)
var launchDirection: Vector2 = Vector2.RIGHT
## Inherited intitial velocity
var inhInitVelocity: Vector2 = Vector2.ZERO

## Projectile rotation
var rotation: float = 0.
## Target rotation
var targetRotation: float = 0.
## Angular velocity
var angularVelocity: float = 0.

## Previous position helper
var prevPosition: Vector2 = Vector2.ZERO

## Launched flag
var launched: bool = false
#endregion

#region Methods
#region System
func _physics_process(delta: float) -> void:
	fsmlR.physics_update(delta)
	fsmlM.physics_update(delta)
	_control_object()
#endregion

#region Interface
func request_movement_state_change(newState: String, data: Dictionary = {}) -> void:
	if fsmlM.state.is_interruptible() or (not fsmlM.state.is_interruptible() and fsmlM.state.completed):
		fsmlM.change_state(fsmlM.state, newState, data)

func request_rotation_state_change(newState: String, data: Dictionary = {}) -> void:
	if fsmlR.state.is_interruptible() or (not fsmlR.state.is_interruptible() and fsmlR.state.completed):
		fsmlR.change_state(fsmlR.state, newState, data)

func launch(direction: Vector2, initialVelocity: Vector2 = Vector2.ZERO, initialInheritedVelocity: Vector2 = Vector2.ZERO) -> void:
	# Save launch direction
	launchDirection = direction.normalized()
	# Set the initial velocity
	velocity = initialInheritedVelocity + initialVelocity
	# Switch the launch flag
	launched = true
#endregion

#region Private
func _control_object() -> bool:
	projectile.global_rotation = rotation
	# TODO: add collision handling and tunnelling
	prevPosition = projectile.global_position
	projectile.global_position = position
	return true
#endregion
#endregion
