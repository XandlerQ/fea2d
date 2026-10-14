extends Node
## Virtual base class for all states.
class_name State

#region Signals
## Emitted when the state finishes and wants to transition to another state.
## For state driven transitions.
signal finished(oldState: State, targetStatePath: String, data: Dictionary)
#endregion

#region Exports

#endregion

#region State
## State completion flag, used for non-interruptible states to define completion
var completed: bool = false
#endregion

#region Methods
#region System

#endregion

#region Interface
## Called by the state machine when receiving unhandled input events.
func handle_input(_event: InputEvent) -> void:
	pass

## Called by the state machine on the engine's main loop tick.
func update(_delta: float) -> void:
	pass

## Called by the state machine on the engine's physics update tick.
func physics_update(_delta: float) -> void:
	pass

## Called by the state machine upon changing the active state. The `data` parameter
## is a dictionary with arbitrary data the state can use to initialize itself.
func enter(_previousState: String, _data: Dictionary = {}) -> void:
	completed = false
	pass

## Called by the state machine before changing the active state. Use this function
## to clean up the state.
func exit() -> void:
	completed = true
	pass

## An interruptability flag interface
func is_interruptible() -> bool:
	return true
#endregion

#region Private

#endregion
#endregion
