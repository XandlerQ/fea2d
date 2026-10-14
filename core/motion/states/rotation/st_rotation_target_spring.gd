extends StRotationBase
## Spring-based rotation towards the object.targetRotation.
class_name StRotationTargetSpring

#region Signals

#endregion

#region Exports
## Rotation spring strength for the rotation
@export var k: float = 100.
## Spring damping ratio relative to critical damping
@export var dr: float = 1.
#endregion

#region State

#endregion

#region Methods
#region System
func _ready() -> void:
	super._ready()
	assert(object.get_property_list().any(func(p): return p.name == "targetRotation"), 
		("Object controlled by StRotationTargetSpring must have [float targetRotation] field.")
	)
	assert(object.get_property_list().any(func(p): return p.name == "inertia"), 
		("Object controlled by StRotationTargetSpring must have [float inertia] field.")
	)
#endregion

#region Interface
func physics_update(delta: float) -> void:
	# Shortest signed angular distance to the target
	var d: float = wrapf(object.targetRotation - object.rotation, -PI, PI)
	

	var sInertia: float = max(object.inertia, 1e-5)
	
	var damp: float = dr * 2. * sqrt(max(k, 0.) * sInertia)
	var aAcc: float = (k * d - damp * object.angularVelocity) / sInertia

	object.angularVelocity += aAcc * delta
	
	object.rotation += object.angularVelocity * delta
	
#endregion

#region Private
	
#endregion
#endregion
