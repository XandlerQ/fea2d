@tool
extends Node
## Finite state machine.
## Used for controlling a parrent:
## has _process and _physics_process itself
class_name FSM 

#region Signals
## Emitted after entering the initial state or a new state.
signal state_changed(stateId: StringName)

#endregion

#region Exports
@export var initialState: State
## When enabled, the owner decides when to call handle_input, update, and
## physics_update. When disabled, the state machine uses Godot's callbacks.
@export var manuallyDriven: bool = false
#endregion

#region State
var states: Dictionary = {}
var state: State
var previousState: State
#endregion

#region Methods
#region System
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	states.clear()
	for state_node: State in find_children("*", "State"):
		if state_node.stateId == &"":
			push_error("%s: State '%s' has an empty state ID." % [_get_context_name(), state_node.name])
			continue
		if states.has(state_node.stateId):
			push_error("%s: Duplicate state ID '%s'." % [_get_context_name(), state_node.stateId])
			continue
		states[state_node.stateId] = state_node
		state_node.finished.connect(change_state)

	if owner and not owner.is_node_ready():
		await owner.ready

	if initialState:
		if states.get(initialState.stateId) != initialState:
			push_error("%s: The initial state is not registered with a unique, non-empty state ID." % _get_context_name())
			return
		state = initialState
	elif not states.is_empty():
		state = states.values()[0] as State
	else:
		push_error("%s: No valid states are configured." % _get_context_name())
		return

	state.enter(&"")
	state_changed.emit(state.stateId)

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or manuallyDriven:
		return
	handle_input(event)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or manuallyDriven:
		return
	update(delta)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or manuallyDriven:
		return
	physics_update(delta)
#endregion

#region Interface
func handle_input(event: InputEvent) -> void:
	if not state:
		return
	state.handle_input(event)

func update(delta: float) -> void:
	if not state:
		return
	state.update(delta)

func physics_update(delta: float) -> void:
	if not state:
		return
	state.physics_update(delta)

func change_state(oldState: State, targetStateId: StringName, data: Dictionary = {}, forceExitEnter: bool = false) -> void:
	if state and targetStateId == state.stateId and not forceExitEnter:
		return

	if oldState != state:
		printerr("%s: Trying to transition from state '%s', but the current state is '%s'." % [_get_context_name(), oldState.name, state.name])
		return

	if not states.has(targetStateId):
		printerr("%s: Trying to transition to state ID '%s' but it does not exist." % [_get_context_name(), targetStateId])
		return

	var previousStateId: StringName = state.stateId
	if state:
		state.exit()
	previousState = state
	state = states[targetStateId]
	state.enter(previousStateId, data)
	state_changed.emit(state.stateId)

func get_state_id() -> StringName:
	if state:
		return state.stateId
	else:
		return &""

func get_previous_state_id() -> StringName:
	if previousState:
		return previousState.stateId
	else:
		return &""

func has_state(stateId: StringName) -> bool:
	return states.has(stateId)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	var foundIds: Dictionary = {}
	var stateNodes: Array[Node] = find_children("*", "State")

	if stateNodes.is_empty():
		warnings.append("The state machine requires at least one State descendant.")
	if not initialState:
		warnings.append("An initial state should be assigned.")
	elif not is_ancestor_of(initialState):
		warnings.append("The initial state must be a descendant of this state machine.")

	for node: Node in stateNodes:
		var stateNode: State = node as State
		if stateNode.stateId == &"":
			warnings.append("State '%s' requires a non-empty state ID." % stateNode.name)
		elif foundIds.has(stateNode.stateId):
			warnings.append("State ID '%s' is used more than once." % stateNode.stateId)
		else:
			foundIds[stateNode.stateId] = true

		if stateNode.get_property_list().any(func(property: Dictionary): return property.name == "object"):
			if stateNode.get("object") == null:
				warnings.append("State '%s' requires a controlled object." % stateNode.name)

	return warnings
#endregion

#region Private
func _get_context_name() -> String:
	return owner.name if owner else name

#endregion
#endregion
