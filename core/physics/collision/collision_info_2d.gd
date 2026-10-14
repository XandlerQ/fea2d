extends RefCounted
## General collision data object with optional contact geometry.
## Used for the unified collision detection interface.
class_name CollisionInfo2D

#region State
## The two collided objects
## Source is the object that reports the collision
## Target is the object that source collided with
var source: CollisionObject2D = null
var target: CollisionObject2D = null

## Object-wide registration shape indices
## -1 means unknown (including ambiguous multiple shape kinematic source owners)
var sourceShapeIndex: int = -1
var targetShapeIndex: int = -1

## Shapes that took part in the collision.
## Note that these may be unavailable if CollisionInfo2D is created
## from a KinematicCollision2D instance
var sourceShape: Shape2D = null
var targetShape: Shape2D = null

## World transforms of the collision shapes at the moment of the collision.
## Not changed after the collision has happened.
## Note that these may be unavailable if CollisionInfo2D is created
## from a KinematicCollision2D instance
var sourceShapeTransform: Transform2D = Transform2D.IDENTITY
var targetShapeTransform: Transform2D = Transform2D.IDENTITY

## Collision global position, for shape collisions is the midpoint of the reported
## collision point pair
var globalPosition: Vector2 = Vector2.ZERO

## World normal of the collision, points target -> source
var normal: Vector2 = Vector2.ZERO

## Collision depth, can be used to push object out of each other
var depth: float = 0.

## A flag that shows if the collision point and normal are available
var hasContactGeometry: bool = false

## A flag that shows if the collision depth is available
var hasDepth: bool = false
#endregion

#region Interface
## Fils collision info from a shape pair.
## DOES NOT check for the collision and does not compute the collision geometry.
## Can be used to fill the CollisionInfo2D from the Area2D-like collision detections.
func fill_from_shape_pair(
	pSource: CollisionObject2D, pTarget: CollisionObject2D,
	pSourceShapeIndex: int, pTargetShapeIndex: int
) -> void:
	# Set source and target objects
	source = pSource
	target = pTarget

	# Save the shape indexes (as returned by the Area2D-like collision detection)
	sourceShapeIndex = pSourceShapeIndex
	targetShapeIndex = pTargetShapeIndex

	# Get the Shape2D's and their transforms for the indexes for both source and target
	var sShapeData: Dictionary = _resolve_shape_from_index(source, sourceShapeIndex)
	var tShapeData: Dictionary = _resolve_shape_from_index(target, targetShapeIndex)

	sourceShape = sShapeData.get("shape", null)
	targetShape = tShapeData.get("shape", null)
	
	sourceShapeTransform = sShapeData.get("transform", Transform2D.IDENTITY)
	targetShapeTransform = tShapeData.get("transform", Transform2D.IDENTITY)
	
	# Clear the possible remaining contact geometry
	_clear_contact_geometry()

## Fills the collision info from the given KinematicCollision2D and saves the given 
## CollisionObject2D as source
func fill_from_kinematic_collision(collision: KinematicCollision2D, pSource: CollisionObject2D) -> void:
	# If the collision object is invalid, fill as empty
	if not collision:
		fill_from_shape_pair(null, null, -1, -1)
		return
	
	# Otherwise fill with source and target.
	# It is not necessary to pass the shape indices as the collision
	# geometry is provided by the KinematicCollision2D
	fill_from_shape_pair(
		pSource, 
		collision.get_collider() as CollisionObject2D, 
		-1,
		-1
		# _find_single_shape_index(pSource, collision.get_local_shape()),
		# collision.get_collider_shape_index()
	)

	# Fill the collision geometry information
	globalPosition = collision.get_position()
	normal = collision.get_normal()
	depth = collision.get_depth()

	# Set the flags
	hasContactGeometry = normal.length_squared() > 1e-10
	hasDepth = true

## Queries captured shapes/transforms, keeps existing geometry if
## already available. Returns false for missing shapes, no overlap, 
## or no usable normal
func compute_contact_geometry() -> bool:
	# Keep the contact geometry if available already
	if hasContactGeometry:
		return true
	
	# If no geometry available and the shapes are also not provided,
	# then return false as there is no way to infer collision
	# geometry
	if not sourceShape or not targetShape:
		return false
	
	# Clear the geometry before filling it
	_clear_contact_geometry()

	# Get contact point pairs of the saved colliding shapes
	var contacts: PackedVector2Array = sourceShape.collide_and_get_contacts(
		sourceShapeTransform, targetShape, targetShapeTransform
	)

	# Define the variable for the deepest collision search
	var dMax: float = -1.

	for i in range(0, contacts.size() - 1, 2):
		# Get contact points of the pair
		var sourceP: Vector2 = contacts[i]
		var targetP: Vector2 = contacts[i + 1]
		

		var d: Vector2 = targetP - sourceP
		var dMagn: float = d.length()
		
		if dMagn <= dMax:
			continue
		
		# Update the deepest collision pair info
		dMax = dMagn
		
		# Global collision point as the middle point
		globalPosition = (sourceP + targetP) * 0.5
		depth = dMagn
		
		hasDepth = true
		hasContactGeometry = dMagn > 1e-5
		
		if hasContactGeometry:
			normal = d / dMagn
		else:
			normal = Vector2.ZERO
	
	return hasContactGeometry

## Copies data from another CollisionInfo2D
func copy_from(other: CollisionInfo2D) -> void:
	assert(other != null)
	source = other.source
	target = other.target
	sourceShapeIndex = other.sourceShapeIndex
	targetShapeIndex = other.targetShapeIndex
	sourceShape = other.sourceShape
	targetShape = other.targetShape
	sourceShapeTransform = other.sourceShapeTransform
	targetShapeTransform = other.targetShapeTransform
	globalPosition = other.globalPosition
	normal = other.normal
	depth = other.depth
	hasContactGeometry = other.hasContactGeometry
	hasDepth = other.hasDepth
#endregion

#region Private
func _clear_contact_geometry() -> void:
	globalPosition = Vector2.ZERO
	normal = Vector2.ZERO
	depth = 0.
	hasContactGeometry = false
	hasDepth = false

## From a given CollisionObject2D and a shape index
## Returns a dictionary with:
## - The Shape2D that corresponds to that index
## - Global transform of this Shape2D
static func _resolve_shape_from_index(collisionObject: CollisionObject2D, shapeIndex: int) -> Dictionary:
	# Check if collision object is still valid and if index is valid
	if not is_instance_valid(collisionObject) or shapeIndex < 0:
		return {}

	# Go over all of the shape owners of the collision object
	for ownerId in collisionObject.get_shape_owners():
		# Go over all shapes for each owner
		for i in range(collisionObject.shape_owner_get_shape_count(ownerId)):
			# Find the shape with the given shapeIndex and return
			# - The actual Shape2D for the given shape index
			# - Global transform of this Shape2D
			if collisionObject.shape_owner_get_shape_index(ownerId, i) == shapeIndex:
				return {
					"shape": collisionObject.shape_owner_get_shape(ownerId, i),
					"transform": collisionObject.global_transform * collisionObject.shape_owner_get_transform(ownerId)
				}
	return {}

# ## KinematicCollision2D exposes the source owner object, not its exact index.
# ## Resolve only a single-shape owner; never guess a piece of a multi-shape owner.
# static func _find_single_shape_index(collisionObject: CollisionObject2D, ownerObject: Object) -> int:
# 	if not is_instance_valid(collisionObject) or not is_instance_valid(ownerObject):
# 		return -1
# 	for ownerId in collisionObject.get_shape_owners():
# 		if collisionObject.shape_owner_get_owner(ownerId) == ownerObject:
# 			if collisionObject.shape_owner_get_shape_count(ownerId) == 1:
# 				return collisionObject.shape_owner_get_shape_index(ownerId, 0)
# 			return -1
# 	return -1
#endregion
