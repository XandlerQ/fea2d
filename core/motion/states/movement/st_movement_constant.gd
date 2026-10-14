extends StMovementBase
class_name StMovementConstant

#region Signals

#endregion

#region Exports

#endregion

#region State

#endregion

#region Methods
#region System

#endregion

#region Interface
func physics_update(delta: float) -> void:
	# Update position
	object.position += delta * object.velocity
	pass
#endregion

#region Private

#endregion
#endregion
