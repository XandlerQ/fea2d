extends RefCounted
## Provides continuous 2D collision queries.
class_name TunnellingDetection2D

#region Signals

#endregion

#region Exports

#endregion

#region State

#endregion

#region Methods
#region System

#endregion

#region Interface
## Casts a ray along the desired motion and returns collision info
static func raycast_check(
	spaceState: PhysicsDirectSpaceState2D,
	initialTransform: Transform2D,
	desiredMotion: Vector2,
	exclude: Array[RID] = [],
	collisionMask: int = 0xFFFFFFFF,
	collideWithBodies: bool = true,
	collideWithAreas: bool = true
) -> TunnellingCheckInfo2D:
	var tunnelInfo: TunnellingCheckInfo2D = TunnellingCheckInfo2D.new(desiredMotion, initialTransform)

	if not spaceState or desiredMotion.is_zero_approx():
		return tunnelInfo

	# Get the start and end positions
	var from: Vector2 = initialTransform.origin
	var to: Vector2 = from + desiredMotion

	# Create the query
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to, collisionMask, exclude)
	query.collide_with_areas = collideWithAreas
	query.collide_with_bodies = collideWithBodies

	var hit: Dictionary = spaceState.intersect_ray(query)

	if hit.is_empty():
		return tunnelInfo

	# Compute fractions
	var safeFraction: float = from.distance_to(hit.position) / desiredMotion.length()
	safeFraction = clampf(safeFraction, 0., 1.)

	tunnelInfo.collided = true
	tunnelInfo.safeFraction = safeFraction
	tunnelInfo.unsafeFraction = safeFraction
	tunnelInfo.safeMotion = safeFraction * desiredMotion
	tunnelInfo.impactTransform = initialTransform
	tunnelInfo.impactTransform.origin = hit.position
	tunnelInfo.hits.append(hit)

	return tunnelInfo

## Sweeps a shape along the desired motion and returns collision info
static func sweep_check(
	spaceState: PhysicsDirectSpaceState2D,
	shape: Shape2D,
	initialTransform: Transform2D,
	desiredMotion: Vector2,
	exclude: Array[RID] = [],
	collisionMask: int = 0xFFFFFFFF,
	collideWithBodies: bool = true,
	collideWithAreas: bool = true,
	maxResults: int = 8,
	margin: float = 0.
) -> TunnellingCheckInfo2D:
	var tunnelInfo: TunnellingCheckInfo2D = TunnellingCheckInfo2D.new(desiredMotion, initialTransform)

	if not spaceState or not shape or desiredMotion.is_zero_approx():
		return tunnelInfo

	# Create the query
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = initialTransform
	query.motion = desiredMotion
	query.margin = margin
	query.collision_mask = collisionMask
	query.collide_with_areas = collideWithAreas
	query.collide_with_bodies = collideWithBodies
	query.exclude = exclude

	# Cast motion
	var motionResult: PackedFloat32Array = spaceState.cast_motion(query)

	if motionResult.is_empty() or motionResult[0] >= 1.:
		return tunnelInfo

	# motionResult[0] -- safe fraction
	# motionResult[1] -- unsafe fraction
	var safeFraction: float = motionResult[0]
	var unsafeFraction: float = motionResult[1]

	# Move the query shape further to ensure intersection detection
	var hitTransform: Transform2D = initialTransform
	var epsilon: float = max(1e-3, desiredMotion.length() * 1e-3)
	hitTransform.origin += unsafeFraction * desiredMotion + epsilon * desiredMotion.normalized()
	query.transform = hitTransform
	query.motion = Vector2.ZERO

	var hits: Array[Dictionary] = spaceState.intersect_shape(query, maxResults)

	tunnelInfo.collided = true
	tunnelInfo.safeFraction = safeFraction
	tunnelInfo.unsafeFraction = unsafeFraction
	tunnelInfo.safeMotion = safeFraction * desiredMotion
	tunnelInfo.impactTransform = initialTransform
	tunnelInfo.impactTransform.origin += unsafeFraction * desiredMotion
	tunnelInfo.hits = hits

	return tunnelInfo

#endregion

#region Private

#endregion
#endregion
