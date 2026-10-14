extends StRotationBase
class_name StRotationVelocityAligned

#region Signals

#endregion

#region Exports

#endregion

#region State

#endregion

#region Methods
#region System
func _ready() -> void:
	super._ready()

	assert(object.get_property_list().any(func(p): return p.name == "velocity"), 
		("Object controlled by StRotationVelocityAligned must have [Vector2 velocity] field.")
	)
#endregion

#region Interface
func physics_update(_delta: float) -> void:
	# Do nothing if velocity is close to zero
	if object.velocity.length_squared() < 1e-10:
		object.angularVelocity = 0.
		return
	
	# Otherwise align with the velocity
	var target: float = object.velocity.angle()

	# Pass the target angle to the rotation component
	object.targetRotation = target

	# Simple alignment
	object.rotation = target
#endregion

#region Private

#endregion
#endregion
