extends StRotationBase
class_name StRotationDirect

#region Signals

#endregion

#region Exports

#endregion

#region State
var prevRotation: float = 0.
#endregion

#region Methods
#region System
func _ready() -> void:
	super._ready()
	assert(object.get_property_list().any(func(p): return p.name == "targetRotation"), 
		("Object controlled by StWeaponRotationDirect must have [float targetRotation] field.")
	)

	prevRotation = object.rotation
#endregion

#region Interface
func physics_update(delta: float) -> void:
	prevRotation = object.rotation
	object.rotation = object.targetRotation
	
	# Estimate the angular velocity using finite differences
	var d: float = object.rotation - prevRotation
	object.angularVelocity = d / delta
#endregion

#region Private

#endregion
#endregion
