# FeA2D Architecture Reference

This is a compact map of the project's current implementation. It describes
what the major systems do and how they communicate. For rules about extending
them, see [Coding Guidelines](CODING_GUIDELINES.md).

## Project purpose

FeA2D is currently a top-down physics-combat prototype. Its most developed
feature is a spring-simulated melee weapon whose movement, collision response,
and damage depend on physical velocity.

The repository is not yet a complete RPG. Health consumption, enemies,
projectile casting, inventory, progression, UI, saving, and authored levels are
either incomplete or absent.

## Top-level layout

```text
core/   Reusable state, motion, collision, math, and visual-effect systems
game/   FeA2D-specific entities, combat, weapons, objects, and world scenes
ext/    Runtime art plus original and intermediate art assets
util/   Godot script templates
docs/   Internal architecture and development documentation
```

`game/` may depend on `core/`. `core/` should not depend on concrete game
objects such as `Player` or `Weapon`.

## Runtime entry point

`game/world/level.tscn` is the main scene configured in `project.godot`.

The current level contains:

```text
Level
├── Repeated debug-grid background
├── Player
│   └── Camera2D
└── PhysicsObject2D
    └── Hurtbox2D
```

`level.gd` only handles the `End Simulation` input and quits the application.
The level is a mechanics sandbox rather than a gameplay level.

## Player scene

`game/entity/player/player.tscn` composes the current player:

```text
Player: CharacterBody2D
├── CollisionShape2D
├── Sprite2D
├── CPlayerActionInput
├── CPlayerLocomotionInput
├── CPlayerLocomotionController
├── CEntityLocomotion
│   └── LocomotionFSML
│       ├── Idle
│       ├── Walk
│       ├── Sprint
│       └── Dash
├── CPlayerRotationController
├── CEntityRotation
│   └── RotationFSML
│       ├── TargetTHF
│       └── LookatTHF
├── Hand
│   └── Weapon
└── CPlayerWeaponController
```

`Player` inherits `Entity`. Its own script currently adds no behavior; the
scene's components provide the implementation.

## Input and controller flow

Player input is isolated behind two small interfaces:

- `CPlayerLocomotionInput` reads WASD movement, sprint, and dash.
- `CPlayerActionInput` reads attack input and the mouse target position.

Controllers convert that raw input into generic component commands:

```text
Input
  → Player controller
    → State request / target value
      → Generic entity or weapon component
        → Active state updates simulation values
          → Component applies values to the Godot node
```

This separation allows future AI controllers to drive the same locomotion,
rotation, and weapon components without emulating player input.

## Entity locomotion

`CEntityLocomotion` owns an entity's simulated linear velocity and intended
movement direction. Its manually driven state machine updates the velocity,
after which the component copies it to the `CharacterBody2D` and calls
`move_and_slide()`.

Implemented player locomotion states:

- `idle`: decelerates using friction.
- `walk`: accelerates toward walking speed.
- `sprint`: accelerates toward a higher speed.
- `dash`: applies a curve-shaped, temporarily non-interruptible velocity burst.

The component remembers the last non-zero movement direction for facing while
the player is stationary.

### Entity collision modes

The locomotion component supports four response modes:

- `MoveAndSlide`: use only Godot's normal kinematic response.
- `Force`: push contacted rigid bodies using an applied force.
- `PhysicsTarget`: run the custom impulse solver for the target only.
- `FullPhysics`: apply the custom result to both participants.

Entity-to-entity custom resolution is currently disabled to avoid resolving the
same collision pair twice.

## Entity rotation

`CEntityRotation` owns rotation, target rotation, angular velocity, and an
optional global look target.

The player uses two manually driven states:

- `target_thf`: smoothly faces the last movement direction.
- `look_at_thf`: smoothly faces the mouse while attacking.

THF means turn half-life: the configured duration is the time required to
halve the remaining angular error. This produces frame-rate-independent
exponential smoothing.

Additional generic rotation states exist under `core/motion`, including direct,
spring, and velocity-aligned rotation, but are not used by the current player.

## State machines

`core/state_machine/state.gd` defines the state interface:

- Input, frame, and physics update callbacks
- Entry and exit callbacks
- Completion and interruptibility
- A `finished` transition signal
- A stable `StringName stateId`

`FSM` contains the implementation. It registers state descendants by ID,
validates IDs and the initial state, performs transitions, and emits the new
state ID.

It supports two execution styles:

- Automatic: Godot callbacks are forwarded directly to the active state.
- Manual: another component calls `handle_input()`, `update()`, and
  `physics_update()` at the desired point in its own update order.

`FSML` is a small compatibility subclass that enables manual execution by
default. It contains no separate transition implementation.

Node names are not transition identifiers. Live state IDs are declared in the
player and weapon scenes and use lowercase `snake_case`.

## Weapon scene

`game/weapon/weapon.tscn` currently represents a shortsword:

```text
Weapon
├── TrailMarker
├── Handle
├── Sprite2D
├── CWeaponMovementRotation
│   └── MovementFSML
│       ├── Idle
│       ├── Return
│       └── Attack
├── Hitbox2D
│   └── CollisionShape2D
└── VisualTrailVelocity
    └── VisualTrailSegment template
```

The weapon becomes `top_level`, so its transform is simulated in global space
instead of rigidly inheriting the hand transform.

`CWeaponMovementRotation` owns the weapon's simulated position, linear
velocity, rotation, angular velocity, target point, and return status.

Its states are:

- `idle`: keeps the handle at the wielder's hand and adds small visual drag.
- `attack`: uses damped linear and angular springs to pull the handle toward a
  limited target point; it inherits some wielder motion and limits reach.
- `return`: springs the displaced weapon back to the hand before idle resumes.

Because child `_ready()` callbacks run before the parent's, the movement
component waits for `Weapon.ready` before reading the weapon's scene-owned
handle. Its physics processing remains disabled through an initialization flag
until this setup is complete.

The hitbox is monitored only while the movement state ID is `attack`.

## Combat event flow

The current melee-hit path is:

```text
Weapon enters attack
  → Hitbox2D monitoring is enabled
  → Hitbox overlaps Hurtbox2D
  → CollisionInfo2D captures the shape pair
  → Contact geometry is computed
  → PhysicsCollisionInfo2D receives physical properties for both sides
  → PhysicsCollisionHandling2D calculates the impulse result
  → Weapon and target receive their collision responses
  → Weapon creates AttackContext from relative contact velocity
  → Hurtbox emits attack_received
```

`Hitbox2D` keeps a short per-hurtbox cooldown to suppress immediate repeated
hits. `Hurtbox2D` does not decide damage or movement behavior; it forwards typed
attack and collision events to listeners.

Weapon damage is currently calculated as:

```text
WeaponStats.damage × relative contact velocity magnitude
```

`HealthComponent` is still empty, so no system currently consumes the attack
event and subtracts health.

## Custom collision subsystem

`core/physics/collision/` contains the custom 2D contact pipeline:

- `CollisionInfo2D`: colliders, shapes, contact point, normal, and depth.
- `PhysicsCollisionInfo2D`: adds mass, inertia, velocities, restitution, and
  friction for both sides.
- `PhysicsCollisionHandling2D`: stateless impulse and position-correction math.
- `PhysicsCollisionResult2D`: impulses, velocity changes, separation state,
  and positional corrections.
- `TunnellingDetection2D`: ray and swept-shape continuous collision queries.
- `TunnellingCheckInfo2D`: result data for continuous collision checks.

The solver accounts for linear and angular contact velocity, effective mass,
restitution, friction, angular impulse, and inverse-mass-weighted penetration
correction.

Tunnelling utilities exist but are not yet integrated into projectile or weapon
movement.

## Physics objects

`PhysicsObject2D` extends `RigidBody2D` and connects to its scene-owned hurtbox.
It can supply physics data to the custom solver and apply returned impulses.

Positional correction is accumulated and consumed from `_integrate_forces()`
rather than changing the rigid body's transform at an unsafe time.

The object in the current level is the only implemented combat target.

## Visual trails

`VisualTrailVelocity` monitors a velocity-bearing owner. Above a threshold, it
adds points to an active `VisualTrailSegment`. Finished segments linger while a
small reusable segment pool permits a new trail to begin.

The child `VisualTrailSegment` in the weapon scene is a hidden template that is
duplicated for the pool. Its reference is scene-owned and accessed through a
unique node name.

`visual_trail_simple.gd` and the older `visual_trail_backu.gd` are alternative
or legacy implementations and are not used by the current weapon scene.

## Projectile scaffolding

Projectile code is present but not connected to a scene or gameplay loop:

- `Projectile` owns a lifetime timer and despawns when it expires.
- `ProjectileContainer` registers itself as a target container group.
- `CProjectileCaster` can locate a container, but actual casting is stubbed.
- `CProjectileMovementRotation` defines launch and state-machine data, but does
  not yet implement collision or tunnelling handling.

Treat this folder as scaffolding rather than a working feature.

## Configuration and validation

Fixed internal scene nodes are accessed through unique names. Replaceable,
cross-component, and cross-scene collaborators remain exported.

Reusable configured nodes implement editor warnings for missing references,
resources, collision shapes, state IDs, and other structural requirements.
These scripts use `@tool`, with gameplay lifecycle methods guarded by
`Engine.is_editor_hint()` so editor validation does not run the simulation.

Runtime assertions enforce required invariants, while public request methods
guard legitimate calls made before initialization.

## Current extension points

The clearest next systems to build on top of the existing architecture are:

- A health component listening to `Hurtbox2D.attack_received`
- Enemy controllers that drive existing locomotion, rotation, and weapons
- A complete projectile scene using the existing movement and tunnelling types
- Entity-to-entity collision-pair deduplication
- Reusable base entity scenes
- Authored world scenes and tilemaps
- Automated scene-instantiation and state-transition tests

