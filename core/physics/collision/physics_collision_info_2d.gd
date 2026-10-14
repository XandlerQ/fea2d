extends CollisionInfo2D
## Holds the physical state required to resolve a 2D collision.
class_name PhysicsCollisionInfo2D

#region Signals

#endregion

#region Exports

#endregion

#region State
## Whether physical information about the source is available
var hasSourcePhysicsInfo: bool = false
## Whether physical information about the target is available
var hasTargetPhysicsInfo: bool = false

## Global center of mass of the source
var sourceCoM: Vector2 = Vector2.ZERO
## Linear velocity of the source
var sourceVelocity: Vector2 = Vector2.ZERO
## Angular velocity of the source
var sourceAngularVelocity: float = 0.
## Inverse mass of the source. Zero represents infinite mass.
var sourceInvMass: float = 0.
## Inverse moment of inertia of the source. Zero prevents angular response.
var sourceInvInertia: float = 0.
## Coefficient of restitution of the source
var sourceRestitution: float = 0.
## Friction coefficient of the source
var sourceFriction: float = 0.

## Global center of mass of the target
var targetCoM: Vector2 = Vector2.ZERO
## Linear velocity of the target
var targetVelocity: Vector2 = Vector2.ZERO
## Angular velocity of the target
var targetAngularVelocity: float = 0.
## Inverse mass of the target. Zero represents infinite mass.
var targetInvMass: float = 0.
## Inverse moment of inertia of the target. Zero prevents angular response.
var targetInvInertia: float = 0.
## Coefficient of restitution of the target
var targetRestitution: float = 0.
## Friction coefficient of the target
var targetFriction: float = 0.
#endregion

#region Methods
#region System

#endregion

#region Interface
## Selects which participant's physics fields to fill.
enum Side { SOURCE, TARGET }

## Filss one physics side with the given values
func fill_physics_side(side: PhysicsCollisionInfo2D.Side, com: Vector2, velocity: Vector2,
	angularVelocity: float, invMass: float, invInertia: float,
	restitution: float, friction: float) -> void:
	if side == Side.SOURCE:
		sourceCoM = com
		sourceVelocity = velocity
		sourceAngularVelocity = angularVelocity
		sourceInvMass = invMass
		sourceInvInertia = invInertia
		sourceRestitution = restitution
		sourceFriction = friction
		hasSourcePhysicsInfo = true
	else:
		targetCoM = com
		targetVelocity = velocity
		targetAngularVelocity = angularVelocity
		targetInvMass = invMass
		targetInvInertia = invInertia
		targetRestitution = restitution
		targetFriction = friction
		hasTargetPhysicsInfo = true

## Clears one side of physics info
func clear_physics_side(side: PhysicsCollisionInfo2D.Side) -> void:
	fill_physics_side(side, Vector2.ZERO, Vector2.ZERO, 0., 0., 0., 0., 0.)
	if side == Side.SOURCE:
		hasSourcePhysicsInfo = false
	else:
		hasTargetPhysicsInfo = false

## Fills the physics collision info from on the given side
## with collision info for a generic virtual static object
func fill_generic(side: PhysicsCollisionInfo2D.Side) -> void:
	fill_physics_side(side, Vector2.ZERO, Vector2.ZERO, 0., 0., 0., 0.5, 0.5)
	if side == Side.SOURCE:
		hasSourcePhysicsInfo = true
	else:
		hasTargetPhysicsInfo = true


## Fills the physics collision info from the given Node2D.
## Defines behavior for built-in classes
func fill_from_body(body: Node2D, side: PhysicsCollisionInfo2D.Side) -> bool:
	# Clear physics at the given side
	clear_physics_side(side)

	# Check if the instance is valid
	if not is_instance_valid(body):
		return false

	# Intialize defaults
	var com: Vector2 = body.global_position
	var velocity: Vector2 = Vector2.ZERO
	var angularVelocity: float = 0.
	
	var invMass: float = 0.
	var invInertia: float = 0.
	
	var material: PhysicsMaterial = null

	# Handle RigidBody2D case
	if body is RigidBody2D:
		var rBody: RigidBody2D = body as RigidBody2D
		var dState: PhysicsDirectBodyState2D = PhysicsServer2D.body_get_direct_state(rBody.get_rid())
		
		# If state is not available, keep defaults
		if not dState:
			return false

		# Compute center of mass
		com = dState.transform.origin + dState.center_of_mass
		
		# Grab the engine velocities values
		velocity = rBody.linear_velocity
		angularVelocity = rBody.angular_velocity
		
		# Grab the mass and inertia if the object is not frozen
		if not rBody.freeze:
			invMass = 1. / maxf(rBody.mass, 1e-5)

			if not rBody.lock_rotation:
				invInertia = dState.inverse_inertia
		
		# Grab material if available
		material = rBody.physics_material_override
	
	# Handle StaticBody2D case
	elif body is StaticBody2D:
		var sBody: StaticBody2D = body as StaticBody2D

		# Grab constant velocities and material
		velocity = sBody.constant_linear_velocity
		angularVelocity = sBody.constant_angular_velocity
		material = sBody.physics_material_override
	
	# Handle CharacterBody2D case 
	elif body is CharacterBody2D:
		var cBody: CharacterBody2D = body as CharacterBody2D
		velocity = cBody.velocity
	
	# Unknown body type handled as a generic StaticBody2D
	# else:
	# 	return false
	
	fill_physics_side(side, com, velocity, angularVelocity, invMass, invInertia,
		material.bounce if material else 0.5, material.friction if material else 0.5)
	
	return true

## Fills the physical information
func fill_physics_info(
	pSourceCoM: Vector2,
	pSourceVelocity: Vector2,
	pSourceAngularVelocity: float,
	pSourceInvMass: float,
	pSourceInvInertia: float,
	pSourceRestitution: float,
	pSourceFriction: float,

	pTargetCoM: Vector2,
	pTargetVelocity: Vector2,
	pTargetAngularVelocity: float,
	pTargetInvMass: float,
	pTargetInvInertia: float,
	pTargetRestitution: float,
	pTargetFriction: float
) -> void:
	fill_physics_side(Side.SOURCE, pSourceCoM, pSourceVelocity, pSourceAngularVelocity,
		pSourceInvMass, pSourceInvInertia, pSourceRestitution, pSourceFriction)
	fill_physics_side(Side.TARGET, pTargetCoM, pTargetVelocity, pTargetAngularVelocity,
		pTargetInvMass, pTargetInvInertia, pTargetRestitution, pTargetFriction)

#endregion

#region Private

#endregion
#endregion
