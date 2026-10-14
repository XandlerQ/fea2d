@tool
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
## Scene-owned rotation finite state machine.
@onready var fsml: FSML = get_node_or_null("%RotationFSML") as FSML
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
	if Engine.is_editor_hint():
		return

	assert(entity != null,
		("CharacterBody2D controlled by CEntityRotation must be non null.")
	)
	assert(fsml != null,
		("Finite State Machine of CEntityRotation must be non null.")
	)

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	fsml.physics_update(delta)
	_control_object()
#endregion

#region Interface
func request_state_change(newStateId: StringName, data: Dictionary = {}) -> void:
	if not fsml or not fsml.state:
		return
	if fsml.state.is_interruptible() or (not fsml.state.is_interruptible() and fsml.state.completed):
		fsml.change_state(fsml.state, newStateId, data)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not entity:
		warnings.append("A controlled CharacterBody2D is required.")
	if not (get_node_or_null("%RotationFSML") is FSML):
		warnings.append("A unique RotationFSML child is required.")
	return warnings
#endregion

#region Private
func _control_object() -> void:
	entity.rotation = rotation
#endregion
#endregion
