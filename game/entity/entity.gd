extends CharacterBody2D
class_name Entity

#region Signals

#endregion

#region Exports
## Physics state providers, registered by the locomotion component at startup.
var lcRef: CEntityLocomotion = null
var rcRef: CEntityRotation = null
## Inverse mass
@export var invMass: float = 1.
## Inverse inertia
@export var invInertia: float = 1.

## Local center of mass coordinate
@export var com: Vector2 = Vector2.ZERO

## Restitution for collision handling
@export var restitution: float = 1.
## Friction for collision handling
@export var friction: float = 0.
#endregion

#region State

#endregion

#region Methods
#region System

#endregion

#region Interface
## Applies the physics collision to the correct properties
func apply_collision_response(result: PhysicsCollisionResult2D, side: PhysicsCollisionInfo2D.Side = PhysicsCollisionInfo2D.Side.TARGET) -> void:
	if not result or not result.resolved:
		return

	if not is_instance_valid(lcRef) or not is_instance_valid(rcRef):
		return

	if side == PhysicsCollisionInfo2D.Side.SOURCE:
		global_position += result.posCorrS
		
		if not result.separating:
			lcRef.velocity += result.dVelS
			rcRef.angularVelocity += result.dAngVelS
			
	else:
		global_position += result.posCorrT
		
		if not result.separating:
			lcRef.velocity += result.dVelT
			rcRef.angularVelocity += result.dAngVelT
	
	velocity = lcRef.velocity

## A custom method that fills PhysicsCollisionInfo2D according to the
## Entity class dynamics
func fill_collision_physics_info(info: PhysicsCollisionInfo2D, side: PhysicsCollisionInfo2D.Side) -> bool:
	# Clear
	info.clear_physics_side(side)
	
	# Make sure that components are valid
	if not is_instance_valid(lcRef) or not is_instance_valid(rcRef):
		return false
	
	# Fill the collision information
	info.fill_physics_side(side, to_global(com), lcRef.velocity, rcRef.angularVelocity,
		invMass, invInertia, restitution, friction)
	
	return true

#endregion

#region Private

#endregion
#endregion
