extends State
class_name StMovementBase

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
		("Object controlled by StMovementBase must be non null.")
	)
	assert(object.get_property_list().any(func(p): return p.name == "position"), 
		("Object controlled by StMovementBase must have [Vector2 position] field.")
	)
	assert(object.get_property_list().any(func(p): return p.name == "velocity"), 
		("Object controlled by StMovementBase must have [Vector2 velocity] field.")
	)
#endregion

#region Interface
func physics_update(_delta: float) -> void:
	# This method has to update position and velocity fields
	# of the the controlled object.
	pass
#endregion

#region Private

#endregion
#endregion
