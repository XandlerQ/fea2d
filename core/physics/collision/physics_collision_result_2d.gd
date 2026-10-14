extends RefCounted
## Holds the result of resolving a physical 2D collision.
class_name PhysicsCollisionResult2D

#region Signals

#endregion

#region Exports

#endregion

#region State
## Physical collision information used to produce this result
var collisionInfo: PhysicsCollisionInfo2D = null

## Whether the collision was successfully resolved
var resolved: bool = false
## Whether the objects were already moving apart
var separating: bool = false

## Relative velocity of the collision points
var relVel: Vector2 = Vector2.ZERO

## Magnitude of the resolved normal impulse
var Jn: float = 0.
## Magnitude of the resolved tangential friction impulse
var Jt: float = 0.

## Linear impulse to apply to the source
var ImpLinS: Vector2 = Vector2.ZERO
## Linear impulse to apply to the target
var ImpLinT: Vector2 = Vector2.ZERO


# sourceAngularImpulse = cross(rA, sourceImpulse)
# targetAngularImpulse = cross(rB, targetImpulse)
## Angular impulse to apply to the source
var ImpAngS: float = 0.
## Angular impulse to apply to the target
var ImpAngT: float = 0.


# dvS = sourceInverseMass * sourceImpulse
# dvT = targetInverseMass * targetImpulse

# domegaS = sourceInverseInertia * sourceAngularImpulse
# domegaT = targetInverseInertia * targetAngularImpulse

## Linear velocity change of the source
var dVelS: Vector2 = Vector2.ZERO
## Linear velocity change of the target
var dVelT: Vector2 = Vector2.ZERO


## Angular velocity change of the source
var dAngVelS: float = 0.
## Angular velocity change of the target
var dAngVelT: float = 0.

## Positional correction to apply to the source
var posCorrS: Vector2 = Vector2.ZERO
## Positional correction to apply to the target
var posCorrT: Vector2 = Vector2.ZERO
#endregion

#region Methods
#region System
func _init(pCollisionInfo: PhysicsCollisionInfo2D = null) -> void:
	collisionInfo = pCollisionInfo
#endregion

#region Interface

#endregion

#region Private

#endregion
#endregion
