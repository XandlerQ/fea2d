extends Node2D
class_name VisualTrailSimple

#region Signals

#endregion

#region Exports
## The reference to the node that defines the emission point
@export var emitterPoint: Node2D = null

## The controlled visual segment
@export var vtSegment: VisualTrailSegment = null
#endregion

#region State
## The flag for enabling/disabling adding new points
var enabled: bool = true
#endregion

#region Methods
#region System
func _ready() -> void:
	assert(emitterPoint != null, 
		("Emitter point of VisualTrail must be non null.")
	)
	assert(vtSegment != null, 
		("VisualTrailSegment vtSegment of VisualTrail must be non null.")
	)
		

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	# Add the point
	vtSegment.add_timed_point(emitterPoint.global_position)
		

#endregion

#region Interface

#endregion

#region Private

#endregion
#endregion
