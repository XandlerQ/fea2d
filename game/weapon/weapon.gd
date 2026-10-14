extends Node2D
class_name Weapon

#region Signals

#endregion

#region Exports
## Weapon movement and rotation component reference
@export var wmrc: CWeaponMovementRotation = null

## Weapon hitbox reference
@export var hitbox: Hitbox2D = null
## Handle Marker2D reference, used to infer idle weapon position.
## Namely the position of CoM is computed in a way so that the handle
## marker lies on in the hand of the wielder
@export var handle: Marker2D = null

## Hand reference
@export var hand: Hand = null
## Wielding entity locomotion component reference
@export var lcRef: CEntityLocomotion = null
## Wielding entity rotation component reference
@export var rcRef: CEntityRotation = null

## Stats used by attacks made with this weapon
@export var weaponStats: WeaponStats = null

## Weapon movement mass
@export var movementMass: float = 1.
## Weapon movement rotation inertia
@export var movementInertia: float = 1. * 22.5 * 22.5 / 12.

## Restitution for collision handling
@export var restitution: float = 1.
## Friction for collision handling
@export var friction: float = 0.
#endregion

#region State
## Current velocity, filled by the movement component.
## Can be used for computations that require the weapon
## velocity
var velocity: Vector2 = Vector2.ZERO
## Current angular velocity, filled by the movement component.
## Can be used for computations that require the weapon
## angular velocity
var angularVelocity: float = 0.
#endregion

#region Methods
#region System
func _ready() -> void:
	top_level = true
	assert(handle != null, 
		("Marker2D handle of Weapon must be non null.")
	)
	assert(wmrc != null, 
		("CWeaponMovementRotation wmrc of Weapon must be non null.")
	)
	assert(hitbox != null,
		("Hitbox of Weapon must be non null.")
	)
	assert(hand != null, 
		("Hand hand of Weapon must be non null.")
	)
	assert(weaponStats != null, 
		("Attack stats of Weapon must be non null.")
	)
	if not hitbox.hurtbox_collision_detected.is_connected(_on_hitbox_hurtbox_collision_detected):
		hitbox.hurtbox_collision_detected.connect(_on_hitbox_hurtbox_collision_detected)
	if not wmrc.fsmlM.state_changed.is_connected(_on_movement_state_changed):
		wmrc.fsmlM.state_changed.connect(_on_movement_state_changed)
	_on_movement_state_changed(wmrc.fsmlM.get_state_name())

	
# func _physics_process(delta: float) -> void:
# 	print(velocity.length())
#endregion

#region Interface
## Delegates the selected collision side to the movement/rotation component.
func apply_collision_response(result: PhysicsCollisionResult2D, side: PhysicsCollisionInfo2D.Side = PhysicsCollisionInfo2D.Side.SOURCE) -> void:
	if is_instance_valid(wmrc):
		wmrc.apply_collision_response(result, side)

## Supplies weapon state with its origin as the center of mass.
func fill_collision_physics_info(info: PhysicsCollisionInfo2D, side: PhysicsCollisionInfo2D.Side) -> bool:
	# Clear
	info.clear_physics_side(side)
	
	# Check the validity of movement and rotation component
	if not is_instance_valid(wmrc):
		return false
	
	# Fill the PhysicsCollisionInfo2D
	info.fill_physics_side(side, global_position, wmrc.wVelocity, wmrc.angularVelocity,
		1. / maxf(weaponStats.attackMass, 1e-5), 1. / maxf(weaponStats.attackInertia, 1e-5),
		# 1. / maxf(movementMass, 1e-5), 1. / maxf(movementInertia, 1e-5),
		restitution, friction)

	return true

func generate_attack_context(targetObject: Node2D, relVel: Vector2) -> AttackContext:
	var attackContext: AttackContext = AttackContext.new()

	# Fill in the attacker
	attackContext.attackingObject = self
	# Fill in the target
	attackContext.target = targetObject

	# Pass the attack stats directly
	attackContext.attackStats = weaponStats

	# TODO: more complicated damage computation system
	# Compute the damage based on the relative velocity at the collisiom
	attackContext.damage = weaponStats.damage * relVel.length()
	
	return attackContext


func get_velocity_at_point(point: Vector2) -> Vector2:
	var localPoint: Vector2 = point - global_position
	return velocity + angularVelocity * Vector2(-localPoint.y, localPoint.x)
#endregion

#region Private
func _on_movement_state_changed(stateName: String) -> void:
	hitbox.set_detection_enabled(stateName == "Attack")

func _handle_collision_hit_physics(collisionInfo: CollisionInfo2D) -> PhysicsCollisionResult2D:
	var result: PhysicsCollisionResult2D = PhysicsCollisionResult2D.new()

	# First extract the Hurtbox
	var hurtbox: Hurtbox2D = collisionInfo.target as Hurtbox2D
	if not hurtbox:
		return result

	# Get the target object (can be null)
	var targetObject = hurtbox.hbOwner



	# Create the physics collsion info object
	var physicsCollisionInfo: PhysicsCollisionInfo2D = PhysicsCollisionInfo2D.new()
	
	# Copy over the collision info from the Hitbox
	physicsCollisionInfo.copy_from(collisionInfo)
	
	# Fill info for weapon (source)
	if not fill_collision_physics_info(physicsCollisionInfo, PhysicsCollisionInfo2D.Side.SOURCE):
		return result
	
	# Check if the target object is valid
	if not targetObject:
		return result

	# If the physics body has the custom method for filling collision info
	# call it
	if targetObject.has_method("fill_collision_physics_info"):
		if targetObject.call("fill_collision_physics_info", physicsCollisionInfo, PhysicsCollisionInfo2D.Side.TARGET) != true:
			return result
	# Otherwise use the fall-back version
	elif not physicsCollisionInfo.fill_from_body(targetObject, PhysicsCollisionInfo2D.Side.TARGET):
		return result

	
	result = PhysicsCollisionHandling2D.process_collision(physicsCollisionInfo)

	# Make no position correction for the weapon-based collisions
	result.posCorrS = Vector2.ZERO
	result.posCorrT = Vector2.ZERO

	return result

func _on_hitbox_hurtbox_collision_detected(collisionInfo: CollisionInfo2D) -> void:
	if not collisionInfo or not is_instance_valid(collisionInfo.target):
		return
	
	# Since the collision comes from the Hitbox for the collision geometry
	# we need to explicitly compute the contact geometry
	if not collisionInfo.compute_contact_geometry():
		return
	
	# First extract the Hurtbox
	var hurtbox: Hurtbox2D = collisionInfo.target as Hurtbox2D
	if not hurtbox:
		return

	# Get the target object (can be null)
	var targetObject = hurtbox.hbOwner

	# Handle the collision physics
	var collisionResult: PhysicsCollisionResult2D = _handle_collision_hit_physics(collisionInfo)

	# Apply the collision result to the weapon
	apply_collision_response(collisionResult)

	# Pass the collision result to the Hurtbox
	hurtbox.receive_collision_impact_pcr2d(collisionResult)

	if collisionResult.resolved and collisionResult.separating:
		return

	# Generate the attack context
	var relVel: Vector2 = Vector2.ZERO

	if collisionResult.resolved:
		relVel = collisionResult.relVel
	else:
		relVel = get_velocity_at_point(collisionInfo.globalPosition)

	var attackContext: AttackContext = generate_attack_context(targetObject, relVel)

	# Pass the attack context to the Hurtbox
	hurtbox.receive_attack_context(attackContext)
#endregion
#endregion
