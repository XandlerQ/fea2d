extends State
## Base class for states that control weapon movement.
class_name StWeaponMovementBase

#region Signals

#endregion

#region Exports
## Controlled object. MUST have [Vector2 velocity] and
## [Vector2 wPosition] fields.
@export var object: Node
#endregion

#region State

#endregion

#region Methods
#region System
func _ready() -> void:
	assert(object != null, 
		("Object controlled by StWeaponMovementBase must be non null.")
	)
	# Linear movement
	assert(object.get_property_list().any(func(p): return p.name == "weapon"), 
		("Object controlled by StWeaponMovementBase must have [Weapon weapon] field.")
	)
	assert(object.get_property_list().any(func(p): return p.name == "wVelocity"), 
		("Object controlled by StWeaponMovementBase must have [Vector2D wVelocity] field.")
	)
	assert(object.get_property_list().any(func(p): return p.name == "wPosition"), 
		("Object controlled by StWeaponMovementBase must have [Vector2D wPosition] field.")
	)
	# Rotation
	assert(object.get_property_list().any(func(p): return p.name == "rotation"), 
		("Object controlled by StRotationBase must have [float rotation] field.")
	)
	assert(object.get_property_list().any(func(p): return p.name == "angularVelocity"), 
		("Object controlled by StRotationBase must have [float angularVelocity] field.")
	)
	assert(object.get_property_list().any(func(p): return p.name == "springAngularVelocity"), 
		("Object controlled by StRotationBase must have [float springAngularVelocity] field.")
	)
#endregion

#region Interface
func physics_update(_delta: float) -> void:
	# State has to update:
		# - Position of the weapon (to be used for collision detection)
		# - Velocity of the weapon (to be used in the damage calculation)
		# - rotation of the weapon
		# - angularVelocity of the weapon
	pass
#endregion

#region Private
func _get_drag(handVel: Vector2, refVelMagn: float, dragCurve: Curve, 
	dragMagn: float, maxDrag: float, _delta: float) -> Vector2:
	# Compute velocity-based drag
	# Sample drag amount according to the hand velocity
	# and the drag curve
	
	# First check if the hand is moving
	var handVelMagn: float = handVel.length()

	if handVelMagn < 1e-5:
		return Vector2.ZERO
	
	var handVelDir: Vector2 = handVel / handVelMagn

	var t: float = handVelMagn / refVelMagn
	
	if t > 1.:
		t = 1.
	
	# Sample the drag curve
	var val: float = dragCurve.sample_baked(t)

	# Compute the drag
	var drag: Vector2 = -dragMagn * val * handVelDir
	
	drag = drag.limit_length(maxDrag)
	
	return drag


func _limit_to_reach(pos: Vector2, wielderPos: Vector2, reach: float) -> Vector2:
	# Compute the distance to the wielder
	var d: Vector2 = pos - wielderPos
	var dMagn: float = d.length()
	
	# Return unchanged if within reach
	if dMagn <= reach or dMagn < 1e-5:
		return pos
	
	# Normalize otherwise
	var dDir: Vector2 = d / dMagn
	var res: Vector2 = wielderPos + reach * dDir
	
	return res

func _thf_target_angle_align(angle: float, target: float, thf: float, delta: float) -> float:
	# Calculate the new angle
	var lambda: float = log(2.) / max(1e-5, thf)
	var alpha: float = 1. - exp(-lambda * delta)
	return lerp_angle(angle, target, alpha)

func _compute_angular_spring_torque(k: float, dr: float) -> float:
	# Shortest signed angular distance to the target
	var d: float = wrapf(object.targetRotation - object.rotation, -PI, PI)

	var sInertia: float = max(object.inertia, 1e-5)
	
	var damp: float = dr * 2. * sqrt(max(k, 0.) * sInertia)
	var torque: float = k * d - damp * object.springAngularVelocity

	return torque

func _perform_rotation_target_spring_wielder(delta: float, k: float, dr: float, wielderAngInh: float) -> void:
	var torque = _compute_angular_spring_torque(k, dr)
	var sInertia: float = max(object.inertia, 1e-5)
	
	var aAcc: float = torque / sInertia

	# Integrate into the spring angular velocity component
	object.springAngularVelocity += aAcc * delta

	# Additionally inherit the wielder angular velocity
	object.angularVelocity = object.springAngularVelocity + wielderAngInh * object.weapon.rcRef.angularVelocity
	object.rotation += object.angularVelocity * delta

#endregion
#endregion
