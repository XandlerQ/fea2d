# FeA2D Coding Guidelines

This document describes the conventions used to extend FeA2D without making
scene composition brittle. The project favors small components, scene-based
composition, explicit external dependencies, stable state identifiers, and
editor-visible validation.

The rules below are intended for gameplay code under `game/` and reusable
systems under `core/`.

## 1. Architectural boundaries

Place code according to how reusable it is:

- `core/` contains systems that do not depend on FeA2D-specific concepts.
  State machines, generic motion states, collision math, and visual-effect
  primitives belong here.
- `game/` contains domain concepts such as players, entities, weapons,
  attacks, projectiles, and levels.
- `ext/` contains imported art and source assets. Gameplay code should not be
  placed here.
- `util/` contains development helpers and script templates.

A `core/` script must not depend on a concrete player, enemy, or weapon class.
Dependencies should point inward: game code may use core code, but core code
should remain independently reusable.

## 2. Prefer composition over large inheritance trees

Gameplay objects should normally be assembled from focused child components.
For example, the player delegates responsibilities to separate input,
locomotion, rotation, weapon-control, and state-machine nodes.

Use inheritance for a genuine "is a" relationship:

```gdscript
class_name Player
extends Entity
```

Use components for independently replaceable behavior:

```text
Player
├── CPlayerLocomotionInput
├── CPlayerLocomotionController
├── CEntityLocomotion
├── CPlayerRotationController
├── CEntityRotation
└── CPlayerWeaponController
```

Input components read input. Controllers interpret intent. Generic components
perform movement or other simulation. Do not make a reusable locomotion or
weapon component read player input directly.

## 3. Classify every node dependency

Before adding a node reference, classify the relationship as one of the
following.

### Scene-owned implementation detail

Use a unique scene name when the referenced node is an invariant part of the
same reusable scene and changing it independently would make the scene invalid.

Examples include:

- A weapon's handle, hitbox, and movement component
- A locomotion component's state machine
- A physics object's hurtbox
- A trail emitter's template segment

Mark the target node as **Access as Unique Name** in Godot, producing:

```text
unique_name_in_owner = true
```

Resolve it safely in code:

```gdscript
@onready var hitbox: Hitbox2D = \
	get_node_or_null("%Hitbox2D") as Hitbox2D
```

Prefer `get_node_or_null()` over a mandatory `%Node` expression when the script
also reports configuration warnings. This lets an incomplete scene remain
editable long enough for the warning to explain what is missing.

Unique names are scoped to a scene. Do not use a unique-name lookup to reach
inside an unrelated or replaceable scene instance.

### External or replaceable dependency

Keep the reference exported when it crosses a composition boundary or when a
designer may reasonably substitute a differently located implementation.

Examples include:

```gdscript
@export var entity: Entity = null
@export var rcRef: CEntityRotation = null
@export var hand: Hand = null
@export var weaponStats: WeaponStats = null
```

This preserves support for unusual scene layouts. Cross-component references,
controlled objects, wielder references, targets, and configurable resources
are generally external dependencies.

### Runtime-discovered dependency

Use registration or discovery when the relationship is established
dynamically. For example, the locomotion component registers itself and the
rotation component with its entity at startup.

Do not expose a redundant editor field if the value is always overwritten by
runtime registration.

## 4. Treat scene structure as an API

Reusable scenes have two kinds of API:

- Exported properties are the public configuration surface.
- Unique-name nodes are private structural requirements.

When changing a reusable scene:

1. Preserve exported fields that callers legitimately configure.
2. Keep required unique-node names stable.
3. Update `_get_configuration_warnings()` when a requirement changes.
4. Check every scene that instantiates it.

Renaming an ordinary visual node is usually harmless. Renaming a node accessed
through `%UniqueName` is an API change and must be updated in the corresponding
script.

## 5. Respect Godot's ready order

Godot calls `_ready()` on children before their parents. Consequently, a child
must not assume that its parent's `@onready` fields have already initialized.

If a child needs parent-owned scene references during initialization, wait for
the parent and prevent processing until initialization completes:

```gdscript
var initialized: bool = false

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	assert(parentComponent != null)

	if not parentComponent.is_node_ready():
		await parentComponent.ready

	assert(parentComponent.requiredChild != null)
	_initialize_from_parent()
	initialized = true

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not initialized:
		return

	_simulate(delta)
```

This pattern is used by the weapon movement component because it needs the
weapon's scene-owned handle.

Do not solve ready-order problems with arbitrary frame delays. Wait for the
specific lifecycle event that establishes the dependency.

## 6. State-machine conventions

### Stable state IDs

Every concrete state instance must have a non-empty `stateId`:

```gdscript
@export var stateId: StringName = &""
```

Use lowercase `snake_case` identifiers:

```text
idle
walk
sprint
dash
target_thf
look_at_thf
attack
return
```

State IDs are behavior-facing identifiers. Node names are editor-facing labels.
The two may match, but transition logic must never depend on the node name.

Use `StringName` constants at call sites:

```gdscript
const STATE_IDLE: StringName = &"idle"
const STATE_DASH: StringName = &"dash"

locomotion.request_state_change(STATE_DASH)
```

Never transition using paths or display names such as `"Dash"`.

### State-machine registration

`FSM` registers states by `stateId`. It rejects empty IDs and duplicate IDs.
The exported `initialState` remains a direct state reference because selecting
the initial behavior is intentional scene configuration rather than internal
plumbing.

State transitions accept IDs:

```gdscript
stateMachine.change_state(stateMachine.state, &"attack")
```

Query IDs with:

```gdscript
stateMachine.get_state_id()
stateMachine.get_previous_state_id()
stateMachine.has_state(&"attack")
```

### Automatic and manual execution

There is one state-machine implementation: `FSM`.

- With `manuallyDriven == false`, `FSM` forwards Godot input, frame, and
  physics callbacks automatically.
- With `manuallyDriven == true`, the owning component explicitly calls
  `handle_input()`, `update()`, or `physics_update()`.
- `FSML` is a thin compatibility preset that enables `manuallyDriven` by
  default. It must not duplicate transition or registry logic.

Use automatic execution when the state machine independently controls a node.
Use manual execution when a component needs precise ordering, such as updating
state velocity before transferring it to a physics body.

### Interruptibility

Requests must respect the current state's interruptibility:

```gdscript
if not fsml or not fsml.state:
	return

if fsml.state.is_interruptible() or fsml.state.completed:
	fsml.change_state(fsml.state, targetStateId, data)
```

Non-interruptible states must explicitly set `completed` when their operation
finishes. Dash is the current example.

## 7. Editor-time validation

Every reusable node with required configuration should implement
`_get_configuration_warnings()`.

```gdscript
@tool
extends Node

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if not controlledObject:
		warnings.append("A controlled object is required.")
	if not (get_node_or_null("%StateMachine") is FSM):
		warnings.append("A unique StateMachine child is required.")

	return warnings
```

Warnings should cover:

- Required external references
- Required unique children
- Required resources
- Required collision shapes
- State-machine initial state, IDs, duplicates, and controlled objects
- Required properties on loosely typed collaborators

Warnings must be specific enough to tell a scene author how to fix the node.
Prefer `"A unique Hitbox2D child is required"` over `"Invalid configuration"`.

### Tool-script safety

Editor warnings require `@tool`. A tool script can also execute lifecycle and
processing callbacks inside the editor, so gameplay behavior must be guarded:

```gdscript
func _ready() -> void:
	if Engine.is_editor_hint():
		return

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
```

Never spawn runtime objects, move gameplay nodes, connect runtime-only systems,
or mutate scene state from editor execution unless that behavior is explicitly
an editor tool.

## 8. Runtime validation and defensive interfaces

Editor warnings improve authoring but do not replace runtime checks. Required
dependencies should also be asserted at their first mandatory use:

```gdscript
assert(weapon != null, "A controlled Weapon is required.")
```

Public request methods should safely reject calls made before initialization:

```gdscript
func request_state_change(targetStateId: StringName) -> void:
	if not fsml or not fsml.state:
		return
	# Continue with the request.
```

Use this division:

- Configuration warning: helps the scene author before running the game.
- Assertion: identifies a broken invariant immediately during development.
- Guard clause: safely rejects a timing-dependent or optional operation.

Do not silently guard a permanently invalid required dependency everywhere;
that hides broken scenes.

## 9. Signals and data flow

Prefer signals when a component reports an event without owning the response.

Current examples include:

- `Hitbox2D` reports detected hurtbox collisions.
- `Hurtbox2D` reports received attacks and collision impacts.
- State machines report state-ID changes.

Pass typed context objects when an event contains multiple related values.
`AttackContext`, `CollisionInfo2D`, and `PhysicsCollisionResult2D` are examples.
Avoid signals with long, position-dependent argument lists.

The sender should construct the context, while the receiver decides what the
event means for its own health, movement, effects, or AI.

## 10. Data belongs in resources

Use `Resource` classes for reusable designer-authored data such as weapon
statistics:

```gdscript
class_name WeaponStats
extends Resource

@export var damage: float = 0.0
```

Keep runtime state out of shared resources unless the resource is explicitly
duplicated per instance. Runtime velocity, timers, current targets, and current
health belong on nodes or per-instance runtime objects.

## 11. Naming and typing

Follow the established project conventions unless a dedicated style migration
is performed:

- Classes use `PascalCase`: `CEntityLocomotion`, `WeaponStats`.
- Methods and existing fields use `snake_case` and the project's current
  `camelCase` field convention respectively.
- State IDs use lowercase `snake_case` `StringName` values.
- Component scripts use the `c_` prefix.
- State scripts use the `st_` prefix.
- Private helpers begin with `_`.
- Signals describe completed events, such as `attack_received`.

Type parameters, returns, fields, and important local variables:

```gdscript
func generate_attack_context(
	targetObject: Node2D,
	relVel: Vector2
) -> AttackContext:
```

Use concrete types where the dependency truly requires one. Use `Node` only
for deliberately structural interfaces, and validate the required properties
or methods.

## 12. Adding a feature: recommended pipeline

Use this sequence for new gameplay features.

### Step 1: Define the responsibility

Write down what owns the feature and what it does not own. For example, an
enemy attack controller may choose when to attack, but the weapon component
continues to simulate weapon movement and collision.

Decide whether the feature belongs in `core/` or `game/`.

### Step 2: Define data separately from behavior

If designers need reusable values, create or extend a `Resource`. Keep the
component responsible for runtime behavior and the resource responsible for
tuning data.

### Step 3: Define the component interface

Create a focused component with typed methods and signals. Identify each
dependency as scene-owned, external, or runtime-discovered before declaring
the corresponding field.

Avoid reaching through several relatives such as:

```gdscript
get_parent().get_parent().get_node("SomeSibling")
```

Use a unique scene name for a fixed internal node or an exported reference for
a configurable collaborator.

### Step 4: Add states when behavior has modes

Create a state only when behavior has meaningful modes with distinct update or
transition rules. Assign every state a stable `StringName` ID, configure the
initial state, and decide whether execution should be automatic or manually
driven.

Keep input-dependent transition decisions in a controller rather than in a
generic movement state.

### Step 5: Compose the scene

Add the component and its required children. Mark invariant internal nodes as
unique. Wire only external dependencies through exported fields.

After composition, inspect the scene tree for warning icons and resolve all
configuration warnings.

### Step 6: Handle lifecycle ordering

Determine whether a child uses fields initialized by its parent. If so, wait
for that parent's `ready` signal and gate processing with an initialization
flag. Do not assume tree order beyond Godot's documented child-before-parent
ready behavior.

### Step 7: Add editor and runtime validation

Add `_get_configuration_warnings()` for authoring errors, assertions for
mandatory runtime invariants, and guard clauses for legitimate early or
optional calls.

If the script is marked `@tool`, guard every runtime lifecycle callback against
editor execution.

### Step 8: Connect through signals or typed calls

Use direct calls for commands owned by a known collaborator, such as requesting
a state transition. Use signals for observations that may have several or no
listeners, such as receiving an attack.

### Step 9: Verify the complete feature path

At minimum, verify:

1. The scene opens without configuration warnings.
2. The scene instantiates without assertions or parser errors.
3. Every new state can be entered using its ID.
4. Missing optional data is handled safely.
5. Required data fails clearly.
6. Tool scripts do not simulate gameplay in the editor.
7. The feature works when its reusable scene is instantiated inside another
   scene, not only when run by itself.
8. `git diff --check` reports no whitespace errors.

When automated tests are introduced, add a small scene-instantiation test and
state-transition test for every reusable gameplay scene.

## 13. Feature checklist

Before considering a feature complete, answer yes to the applicable items:

- Is the code in the correct architectural folder?
- Is each class responsible for one coherent behavior?
- Are input, control decisions, simulation, and event handling separated?
- Are fixed internal nodes accessed by unique names?
- Are replaceable or cross-boundary dependencies exported?
- Are redundant exported references removed?
- Does every state have a unique non-empty `StringName` ID?
- Are transitions independent of scene node names?
- Is the correct automatic or manual FSM mode used?
- Are parent `@onready` dependencies safe from child-before-parent ready order?
- Does every reusable configured node provide useful editor warnings?
- Are `@tool` runtime callbacks guarded with `Engine.is_editor_hint()`?
- Are mandatory invariants asserted at runtime?
- Are events communicated using signals and typed context objects where useful?
- Does the reusable scene also work when instantiated as a child scene?

