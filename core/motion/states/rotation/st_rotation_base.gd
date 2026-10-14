extends State
class_name StRotationBase

#region Signals

#endregion

#region Exports

#endregion

#region State
## Controlled object
@export var object: Node = null
#endregion

#region Methods
#region System
func _ready() -> void:
	assert(object != null, 
		("Object controlled by StRotationBase must be non null.")
	)
	assert(object.get_property_list().any(func(p): return p.name == "rotation"), 
		("Object controlled by StRotationBase must have [float rotation] field.")
	)
	assert(object.get_property_list().any(func(p): return p.name == "angularVelocity"), 
		("Object controlled by StRotationBase must have [float angularVelocity] field.")
	)
#endregion

#region Interface
func physics_update(_delta: float) -> void:
	# This method has to update rotation and angularVelocity fileds
	# of the the controlled object.
	pass
#endregion

#region Private
func _thf_target_angle_align(angle: float, target: float, thf: float, delta: float) -> float:
	# Calculate the new angle
	var lambda: float = log(2.) / max(1e-5, thf)
	var alpha: float = 1. - exp(-lambda * delta)
	return lerp_angle(angle, target, alpha)
#endregion
#endregion
