extends StEntityLocomotionBase
class_name StEntityLocomotionIdle

#region Signals

#endregion

#region Exports
## Friction
@export var friction: float = 460.
#endregion

#region State

#endregion

#region Methods
#region System

#endregion

#region Interface
func physics_update(delta: float) -> void:
	# Decelerate due to friction
	object.velocity = _decelerate(object.velocity, friction, delta)
#endregion

#region Private

#endregion
#endregion
