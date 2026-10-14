extends StRotationBase
## Turn halflife rotation towards the object.targetRotation.
class_name StRotationTargetTHF

#region Signals

#endregion

#region Exports
## Turn halflife, seconds to halve the remaining angle to target direction.
@export var thf: float = 0.12
#endregion

#region State

#endregion

#region Methods
#region System
func _ready() -> void:
	super._ready()
#endregion

#region Interface
func physics_update(delta: float) -> void:
	var angle: float = _thf_target_angle_align(object.rotation, object.targetRotation, thf, delta)

	# Compute the angular velocity
	var d: float = wrapf(object.targetRotation - object.rotation, -PI, PI)
	object.angularVelocity = log(2.) / max(thf, 1e-5) * d
	
	object.rotation = angle
#endregion

#region Private
	
#endregion
#endregion
