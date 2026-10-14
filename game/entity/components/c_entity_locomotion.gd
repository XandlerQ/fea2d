extends Node
## Entity locomotion component.
## Defines entity locomotion state.
## Directly changes the [entity]'s
## [Vector2D velocity] field.
class_name CEntityLocomotion

#region Signals

#endregion

#region Exports
## Collision handling methods
enum CollisionMethod {
	## Move and slide only, the default engine behavior
	MoveAndSlide,
	## Applies force on contact to be able to push objects
	Force,
	## Computes the full collision physics, but applies the impulse to
	## the other object only
	PhysicsTarget,
	## Computes the full collision physics, and applies the impulse to
	## both the entity and the other object
	FullPhysics
}
## Selected collision handling method
@export var collisionMethod: CollisionMethod = CollisionMethod.Force

## Whether to copy the resolved velocity after move_and_slide
## back to the locomotion component
@export var copyMnsVelBack: bool = false

## Force per closing speed
@export var pushForceCoeff: float = 10.
## Maximum pushing force that can be applied
@export var maxPushForce: float = 50000.

## Controlled entity.
@export var entity: Entity = null
## Locomotion Finite State Machine.
@export var fsml: FSML = null

## Rotation component
@export var rcRef: CEntityRotation = null
#endregion

#region State
## Current velocity.
var velocity: Vector2 = Vector2.ZERO
## Current movement direction (intent)
var direction: Vector2 = Vector2.RIGHT:
	set(dir):
		if dir.length_squared() > 1e-10:
			direction = dir.normalized()
			_lnzDirection = direction
		else:
			direction = dir
	get:
		return direction
## Last non-zero movement direction (intent)
var _lnzDirection: Vector2 = Vector2.RIGHT
#endregion

#region Methods
#region System
func _ready() -> void:
	assert(entity != null, 
		("Entity controlled by CEntityLocomotion must be non null.")
	)
	assert(fsml != null, 
		("Finite State Machine of CEntityLocomotion must be non null.")
	)
	assert(rcRef != null, 
		("Rotation component reference of CEntityLocomotion must be non null.")
	)

	# Register existing component wiring without requiring scene-file changes.
	entity.lcRef = self
	entity.rcRef = rcRef

func _physics_process(delta: float) -> void:
	fsml.physics_update(delta)
	var hasCollision: bool = _control_object()
	
	if not hasCollision:
		return

	_handle_collisions()

	# Copy post-move_and_slide velocity
	if copyMnsVelBack:
		velocity = entity.velocity
#endregion

#region Interface
func request_state_change(newState: String, data: Dictionary = {}) -> void:
	if fsml.state.is_interruptible() or (not fsml.state.is_interruptible() and fsml.state.completed):
		fsml.change_state(fsml.state, newState, data)
#endregion

#region Private
func _control_object() -> bool:
	entity.velocity = velocity
	return entity.move_and_slide()

func _handle_collisions() -> void:
	if collisionMethod == CollisionMethod.MoveAndSlide:
		return

	var handledIds: Dictionary = {}

	for i in range(entity.get_slide_collision_count()):
		var collision: KinematicCollision2D = entity.get_slide_collision(i)
		var target: Object = collision.get_collider()

		# Handle collisions only with rigid and static bodies
		if target is not RigidBody2D and target is not StaticBody2D:
			continue

		# Save the id of the target object to ensure
		# that the collision is handled only once
		var targetId: int = target.get_instance_id()
		
		if handledIds.has(targetId):
			continue
		
		handledIds[targetId] = true

		# Create the physics collision object
		var phColInfo: PhysicsCollisionInfo2D = PhysicsCollisionInfo2D.new()
		# Fill from the built-in kinematic collision
		phColInfo.fill_from_kinematic_collision(collision, entity)

		# Fill the source from the owning entity
		if not entity.fill_collision_physics_info(phColInfo, PhysicsCollisionInfo2D.Side.SOURCE):
			continue
		
		# Check if target has a custom method and call it if so
		if target.has_method("fill_collision_physics_info"):
			if target.call("fill_collision_physics_info", phColInfo, PhysicsCollisionInfo2D.Side.TARGET) != true:
				continue
		# Else try the fallback defined in the PhysicsCollisionInfo2D
		elif not phColInfo.fill_from_body(target as PhysicsBody2D, PhysicsCollisionInfo2D.Side.TARGET):
			continue

		# Handle the collision
		_process_physics_collision(phColInfo)

func _process_physics_collision(phCollision: PhysicsCollisionInfo2D) -> bool:
	# TODO: Enable entity-to-entity responses after adding shared collision-pair
	# deduplication so both entities cannot resolve the same impact twice.
	if phCollision.target is Entity:
		return false

	if collisionMethod == CollisionMethod.Force:
		# Cast to RigidBody
		var target: RigidBody2D = phCollision.target as RigidBody2D

		# Return if it is frozen or if cast failed
		if not target or target.freeze:
			return false

		# Get the push direction
		var pushDir: Vector2 = -phCollision.normal.normalized()
		# Check if moving into the object
		if phCollision.sourceVelocity.dot(pushDir) <= 0.:
			return false

		# Compute collision point velocity of target
		var targetR: Vector2 = phCollision.globalPosition - phCollision.targetCoM
		var targetPVel: Vector2 = phCollision.targetVelocity
		targetPVel += phCollision.targetAngularVelocity * Vector2(-targetR.y, targetR.x)

		var nVelMagn: float = maxf((phCollision.sourceVelocity - targetPVel).dot(pushDir), 0.)
		var fMagn: float = minf(nVelMagn * maxf(pushForceCoeff, 0.), maxf(maxPushForce, 0.))
		
		if fMagn <= 0.:
			return false

		# Apply force
		target.apply_force(fMagn * pushDir, phCollision.globalPosition - target.global_position)
		return true
	else:
		# Cast to physics body
		var target: PhysicsBody2D = phCollision.target as PhysicsBody2D

		# Return if failed
		if not target:
			return false

		# Process the collision
		var result: PhysicsCollisionResult2D = PhysicsCollisionHandling2D.process_collision(phCollision)

		# Separating contacts may still need positional correction by the receiver.
		if not result.resolved:
			return false

		# Apply changes to entity
		if collisionMethod == CollisionMethod.FullPhysics:
			entity.apply_collision_response(result, PhysicsCollisionInfo2D.Side.SOURCE)

		# Let custom objects apply the response to their own movement state.
		if target.has_method("apply_collision_response"):
			target.call("apply_collision_response", result, PhysicsCollisionInfo2D.Side.TARGET)
		# Plain engine bodies retain the direct impulse fallback.
		elif target is RigidBody2D and not result.separating:
			var rigidTarget: RigidBody2D = target as RigidBody2D
			
			if not rigidTarget.freeze:
				var targetCollisionPoint: Vector2 = phCollision.globalPosition - rigidTarget.global_position
				rigidTarget.apply_impulse(result.ImpLinT, targetCollisionPoint)

		return true
#endregion
#endregion
