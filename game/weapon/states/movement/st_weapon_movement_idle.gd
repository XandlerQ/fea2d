extends StWeaponMovementBase
class_name StWeaponMovementIdle

#region Signals

#endregion

#region Exports
## Drag magnitude
@export var dragMagn: float = 2.5
## Max drag
@export var maxDrag: float = 3.
## Drag curve
@export var dragCurve: Curve = null
## Drag reference velocity magnitude
@export var dragRefVelMagn: float = 360

## Rotation spring strength for the rotation
@export var kAng: float = 12000.
## Spring damping ratio relative to critical damping
@export var drAng: float = 1.
## Wielder angular velocity inheritance ratio
@export var wielderAngInh: float = 0.2
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
	# Update the position
	# Align the handle with the hand + the artificial visual drag
	# Get the drag
	var drag: Vector2 = _get_drag(object.weapon.hand.velocity, dragRefVelMagn, 
		dragCurve, dragMagn, maxDrag, delta)
	
	# Compute the weapon position to be so that handle aligns with hand + drag
	var handleOffset: Vector2 = object.get_handle_offset()
	object.wPosition = object.weapon.hand.global_position - handleOffset + drag

	# Set the velocity to the hand velocity (ignores drag-based movement velocity)
	object.wVelocity = object.weapon.hand.velocity

	# Handle the rotation
	_perform_rotation_target_spring_wielder(delta, kAng, drAng, wielderAngInh)
#endregion

#region Private

#endregion
#endregion
