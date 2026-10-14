extends Node2D
class_name VisualTrailVelocity


#region Exports
## The reference to the node that defines the emission point
@export var emitterPoint: Node2D = null

## The owner object to monitor velocity field of
@export var velOwner: Node = null

## The minimum velocity for the tral to form
@export var minVelocity: float = 250.0

## Reference segment used to create the trail segments
@export var refSegment: VisualTrailSegment = null

## Maximum number of trail segments
@export var maxSegments: int = 3

## Seconds to continue emitting after high->low velocity transition
@export var lingerTime: float = 0.15
#endregion


#region State
## The flag for enabling/disabling adding new points
var enabled: bool = true

## Whether the segment is currently created
var segmentInProgress: bool = false

## Currently active segment
var activeSegment: VisualTrailSegment = null

## Emission timer for continuing trail after high->low velocity transition
var lTimer: float = 0.0

## An array of reusable segments
var segments: Array[VisualTrailSegment] = []

## A running index for alternating between segments
var runningIndex: int = 0
#endregion

#region System
func _ready() -> void:
	assert(
		emitterPoint != null,
		("VisualTrailVelocity: emitterPoint must be non-null.")
	)
	assert(
		velOwner != null,
		("VisualTrailVelocity: velOwner must be non-null.")
	)
	assert(
		refSegment != null,
		("VisualTrailVelocity: refSegment must be non-null.")
	)
	assert(
		velOwner.get_property_list().any(func(p): return p.name == "velocity"),
		("VisualTrailVelocity: velOwner must have a Vector2 velocity property.")
	)

	maxSegments = max(maxSegments, 1)

	# Make sure that the template segment is not rendered
	# and not processed
	refSegment.visible = false
	refSegment.set_physics_process(false)

	# Create all of the reusable segments
	for i in range(maxSegments):
		var segment := _instantiate_segment()
		segments.append(segment)


func _physics_process(delta: float) -> void:
	if not enabled:
		if activeSegment:
			_finish_active_segment()

		segmentInProgress = false
		lTimer = 0.0
		return

	var vel: Vector2 = velOwner.velocity
	var aboveThreshold: bool = vel.length() >= minVelocity

	if aboveThreshold:
		lTimer = maxf(lingerTime, 0.0)
	else:
		lTimer = maxf(lTimer - delta, 0.0)

	var emitting: bool = aboveThreshold or lTimer > 0.0

	if emitting and not segmentInProgress:
		_start_segment()
	elif not emitting and segmentInProgress:
		_finish_active_segment()

	if emitting and activeSegment:
		activeSegment.add_timed_point(emitterPoint.global_position)

	segmentInProgress = emitting

#endregion


#region Interface
func clear_trail() -> void:
	activeSegment = null
	segmentInProgress = false
	runningIndex = 0
	lTimer = 0.

	for segment in segments:
		segment.reset()
		segment.visible = false
		segment.set_physics_process(false)
#endregion


#region Private

func _start_segment() -> void:
	# Make sure to end the previous segment if it's active
	if activeSegment:
		_finish_active_segment()

	# Get next segment to use
	var segment: VisualTrailSegment = segments[runningIndex]
	# Update the running index
	runningIndex = (runningIndex + 1) % segments.size()

	# Reset the segment even if it is still fading
	segment.reset()
	segment.visible = true

	activeSegment = segment


func _finish_active_segment() -> void:
	if not activeSegment:
		return
	activeSegment.finish()
	activeSegment = null


func _instantiate_segment() -> VisualTrailSegment:
	var segment := refSegment.duplicate() as VisualTrailSegment

	assert(
		segment != null,
		("VisualTrailVelocity: failed to duplicate refSegment.")
	)

	add_child(segment)

	# Keep the segment inactive
	segment.visible = false
	segment.set_physics_process(false)

	return segment

#endregion
