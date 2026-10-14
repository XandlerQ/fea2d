extends StRotationBase
class_name StRotationLookatTHF

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

	assert(object.get_property_list().any(func(p): return p.name == "globTarget"), 
		("Object controlled by StEntityRotationLookatTHF must have [Vector2 globTarget] field.")
	)
#endregion

#region Interface
func physics_update(delta: float) -> void:
	var dir: Vector2 = object.globTarget - object.entity.global_position
	if dir.length_squared() < 1e-10:
		return

	var target: float = dir.angle()

	# Pass the target angle to the rotation component
	object.targetRotation = target
	
	var angle: float = _thf_target_angle_align(object.rotation, target, thf, delta)

	# Compute the angular velocity
	var d: float = wrapf(target - object.rotation, -PI, PI)
	object.angularVelocity = log(2.) / max(thf, 1e-5) * d

	object.rotation = angle
#endregion

#region Private

#endregion
#endregion
