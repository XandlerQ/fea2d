extends StEntityLocomotionBase
class_name StEntityLocomotionWalk

#region Signals

#endregion

#region Exports
## Friction
@export var friction: float = 460.
## Acceleration
@export var acceleration: float = 420.
## Max velocity magnitude
@export var targetMagnitude: float = 80.
#endregion

#region State

#endregion

#region Methods
#region System

#endregion

#region Interface
func physics_update(delta: float) -> void:
	# Accelerate in the desired direction
	object.velocity = _accelerate(object.velocity, acceleration, friction, object.direction, targetMagnitude, delta)
#endregion

#region Private

#endregion
#endregion
