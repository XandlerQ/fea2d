@tool
extends FSM
## Backwards-compatible manually driven finite state machine preset.
## The implementation lives in FSM; owners retain explicit control over when
## input, frame, and physics updates are forwarded to the active state.
class_name FSML

func _init() -> void:
	manuallyDriven = true
