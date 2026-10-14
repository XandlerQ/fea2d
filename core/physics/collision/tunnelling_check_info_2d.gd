extends RefCounted
## Holds the result of a continuous 2D collision query.
class_name TunnellingCheckInfo2D

#region Signals

#endregion

#region Exports

#endregion

#region State
## Collision detected flag
var collided: bool = false

## Safe fraction of the desired motion
var safeFraction: float = 1.
## Collision fraction of the desired motion
var unsafeFraction: float = 1.

## Safe motion
var safeMotion: Vector2 = Vector2.ZERO
## Transform of the handled hitbox at the collision point
var impactTransform: Transform2D = Transform2D.IDENTITY

## Collision query results
var hits: Array[Dictionary] = []

#endregion

#region Methods
#region System
func _init(desiredMotion: Vector2 = Vector2.ZERO, initialTransform: Transform2D = Transform2D.IDENTITY) -> void:
	safeMotion = desiredMotion
	impactTransform = initialTransform.translated(desiredMotion)
#endregion

#region Interface

#endregion

#region Private

#endregion
#endregion
