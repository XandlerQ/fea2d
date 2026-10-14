extends StWeaponMovementBase
class_name StWeaponMovementReturn

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

## Return spring strength
@export var kLin: float = 40
## Return spring damping ratio (relative to critical)
@export var drLin: float = 0.92

## Max weapon velocity
@export var maxVelocityMagn: float = 1500

## Rotation spring strength for the rotation
@export var kAng: float = 12000.
## Spring damping ratio relative to critical damping
@export var drAng: float = 1.
## Wielder angular velocity inheritance ratio
@export var wielderAngInh: float = 0.2
#endregion

#region State
## Damping coefficient
var damp: float = 0.

## The initial return displacement.
var initialReturnD: Vector2 = Vector2.ZERO
## The current return displacement.
## Set on state entry, decreased during state,
## [completed] is set to true after the weapon is returned.
## NOTE THAT THIS STATE IS STILL INTERRUPTIBLE!
var returnD: Vector2 = Vector2.ZERO
## Current return velocity
var returnVel: Vector2 = Vector2.ZERO
#endregion

#region Methods
#region System
func _ready() -> void:
	super._ready()
	damp = drLin * 2. * sqrt(object.weapon.movementMass * kLin)
	assert(object.get_property_list().any(func(p): return p.name == "returned"), 
		("Object controlled by StWeaponMovementBase must have [bool returned] field.")
	)

func physics_update(delta: float) -> void:
	# Update the position
	returnD -= delta * returnVel

	# If the length of the return displacement is small
	# indicate that the return is done
	if returnD.length_squared() < 1e-6:
		object.returned = true

	# Get the drag
	var drag: Vector2 = _get_drag(object.weapon.hand.velocity, dragRefVelMagn, 
		dragCurve, dragMagn, maxDrag, delta)

	# Ease into the drag to avoid snapping
	var t: float = 1.
	if initialReturnD.length_squared() >= 1e-6:
		t = clamp(2. * (1. - returnD.length() / initialReturnD.length()), 0., 1.)
	object.wPosition = object.weapon.hand.global_position - object.get_handle_offset() + t * drag - returnD

	# Update the velocity using the return spring
	var sF: Vector2 = kLin * returnD
	var dF: Vector2 = -damp * returnVel

	var acc: Vector2 = (sF + dF) / object.weapon.movementMass

	returnVel += delta * acc

	# Limit length of the return velocity
	returnVel = returnVel.limit_length(maxVelocityMagn)

	# Compute the actual velocity of the weapon
	# Set it to be the sum of the hand velocity and the return velocity
	object.wVelocity = object.weapon.hand.velocity + returnVel

	# Handle the rotation
	_perform_rotation_target_spring_wielder(delta, kAng, drAng, wielderAngInh)

func enter(_previousState: String, _data := {}) -> void:
	object.returned = false
	initialReturnD = object.weapon.hand.global_position - object.get_handle_offset() - object.wPosition
	returnD = initialReturnD
	# If the length of the return displacement is small
	# change to idle state
	if returnD.length_squared() < 1e-6:
		object.returned = true
		returnVel = Vector2.ZERO
	else:
		returnVel = object.wVelocity - object.weapon.hand.velocity
#endregion

#region Interface

#endregion

#region Private

#endregion
#endregion
