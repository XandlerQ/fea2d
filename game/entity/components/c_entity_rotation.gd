extends Node
# Entity rotation component.
# Defines entity rotaiion state.
# Directly changes the [entity]'s
# [float rotation] field.
class_name CEntityRotation

#region Signals

#endregion

#region Exports
## Controlled entity
@export var entity: CharacterBody2D = null
## Locomotion Finite State Machine
@export var fsml: FSML = null
#endregion

#region State
## Current rotation
var rotation: float = 0.
## Target rotation
var targetRotation: float = 0.
## Current angular velocity
var angularVelocity: float = 0.
## Target global point
var globTarget: Vector2 = Vector2.ZERO
#endregion

#region Methods
#region System
func _ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	fsml.physics_update(delta)
	_control_object()
#endregion

#region Interface
func request_state_change(newState: String, data: Dictionary = {}) -> void:
	if fsml.state.is_interruptible() or (not fsml.state.is_interruptible() and fsml.state.completed):
		fsml.change_state(fsml.state, newState, data)
#endregion

#region Private
func _control_object() -> void:
	entity.rotation = rotation
#endregion
#endregion
