extends RefCounted
## Provides stateless physical 2D collision handling.
class_name PhysicsCollisionHandling2D

#region Signals

#endregion

#region Exports
## Small allowed penetration used for positional correction
const DEPTH_ALLOWANCE: float = 0.
## Ratio of the remaining penetration corrected in one step
const CORRECTION_RATIO: float = 1.
#endregion

#region State

#endregion

#region Methods
#region System

#endregion

#region Interface
## Resolves a physical collision without modifying colliding objects.
static func process_collision(collisionInfo: PhysicsCollisionInfo2D) -> PhysicsCollisionResult2D:
	var result: PhysicsCollisionResult2D = PhysicsCollisionResult2D.new(collisionInfo)

	if not collisionInfo:
		return result
	if not collisionInfo.hasContactGeometry:
		return result
	if not collisionInfo.hasSourcePhysicsInfo:
		return result
	if not collisionInfo.hasTargetPhysicsInfo:
		return result
	if collisionInfo.normal.length_squared() < 1e-10:
		return result

	# Ensure the safety of values used in the calculations
	var normal: Vector2 = collisionInfo.normal.normalized()
	var invMassS: float = maxf(collisionInfo.sourceInvMass, 0.)
	var invMassT: float = maxf(collisionInfo.targetInvMass, 0.)
	var invInertiaS: float = maxf(collisionInfo.sourceInvInertia, 0.)
	var invInertiaT: float = maxf(collisionInfo.targetInvInertia, 0.)

	# Collision point relative positions
	var rS: Vector2 = collisionInfo.globalPosition - collisionInfo.sourceCoM
	var rT: Vector2 = collisionInfo.globalPosition - collisionInfo.targetCoM

	# Fill positional correction
	_compute_position_correction(result, normal, invMassS, invMassT)

	# Compute the velocities of both objects at the collision point
	var cpVelS: Vector2 = collisionInfo.sourceVelocity
	cpVelS += _angular_velocity_at_rel_point(collisionInfo.sourceAngularVelocity, rS)

	var cpVelT: Vector2 = collisionInfo.targetVelocity
	cpVelT += _angular_velocity_at_rel_point(collisionInfo.targetAngularVelocity, rT)

	var relVel: Vector2 = cpVelS - cpVelT
	var relVelN: float = relVel.dot(normal)

	result.relVel = relVel

	# Check if objects are separating
	if relVelN >= 0.:
		result.separating = true
		result.resolved = true
		return result

	# Calculate the normal effective mass
	var rtnS: float = VectorMath.cross_2d(rS, normal)
	var rtnT: float = VectorMath.cross_2d(rT, normal)

	var denomN: float = (
		invMassS
		+ invMassT
		+ rtnS * rtnS * invInertiaS
		+ rtnT * rtnT * invInertiaT
	)

	if denomN <= 1e-5:
		return result

	# Use the lower restitution to avoid adding more energy than the
	# less elastic object allows.
	var cS: float = clampf(collisionInfo.sourceRestitution, 0., 1.)
	var cT: float = clampf(collisionInfo.targetRestitution, 0., 1.)
	var c: float = minf(cS, cT)

	# Calculate the normal impulse
	var Jn: float = -(1. + c) * relVelN / denomN
	var impulse: Vector2 = Jn * normal

	# Calculate the tangential friction impulse
	var relVelT: Vector2 = relVel - relVelN * normal
	var Jt: float = 0.

	if relVelT.length_squared() > 1e-10:
		var tangent: Vector2 = relVelT.normalized()
		var rttS: float = VectorMath.cross_2d(rS, tangent)
		var rttT: float = VectorMath.cross_2d(rT, tangent)
		
		var denomT: float = (
			invMassS
			+ invMassT
			+ rttS * rttS * invInertiaS
			+ rttT * rttT * invInertiaT
		)

		if denomT > 1e-5:
			Jt = -relVel.dot(tangent) / denomT

			var nuS: float = maxf(collisionInfo.sourceFriction, 0.)
			var nuT: float = maxf(collisionInfo.targetFriction, 0.)
			
			var friction: float = sqrt(nuS * nuT)
			
			# Limit the maximum friction impulse
			var maxImpT: float = friction * Jn
			
			Jt = clampf(Jt, -maxImpT, maxImpT)
			
			impulse += Jt * tangent

	# Store impulses
	result.Jn = Jn
	result.Jt = Jt
	
	result.ImpLinS = impulse
	result.ImpLinT = -impulse

	# Angular impulses
	result.ImpAngS = VectorMath.cross_2d(rS, result.ImpLinS)
	result.ImpAngT = VectorMath.cross_2d(rT, result.ImpLinT)

	# Precompute the velocity changes
	result.dVelS = invMassS * result.ImpLinS
	result.dVelT = invMassT * result.ImpLinT
	
	result.dAngVelS = invInertiaS * result.ImpAngS
	result.dAngVelT = invInertiaT * result.ImpAngT

	result.resolved = true
	
	return result
#endregion

#region Private
static func _angular_velocity_at_rel_point(angularVelocity: float, point: Vector2) -> Vector2:
	return angularVelocity * Vector2(-point.y, point.x)

static func _compute_position_correction(
	result: PhysicsCollisionResult2D,
	normal: Vector2,
	invMassS: float,
	invMassT: float
) -> void:

	var collisionInfo: PhysicsCollisionInfo2D = result.collisionInfo

	if not collisionInfo.hasDepth:
		return

	# Compute the pos correction based proportional to the inverse of mass
	# Total inv mass
	var totalInvMass: float = invMassS + invMassT

	# Ensure numerical safety
	if totalInvMass <= 1e-5:
		return

	var correctedDepth: float = maxf(collisionInfo.depth - DEPTH_ALLOWANCE, 0.)
	correctedDepth *= CORRECTION_RATIO

	# Compute correction based on the inv of mass
	result.posCorrS = normal * correctedDepth * invMassS / totalInvMass
	result.posCorrT = -normal * correctedDepth * invMassT / totalInvMass
#endregion
#endregion
