extends StWeaponMovementBase
class_name StWeaponMovementAttack

#region Signals

#endregion

#region Exports
## Attack spring strength
@export var kLin: float = 53
## Attack spring damping ratio (relative to critical)
@export var drLin: float = 0.92
## Max target point reach.
## Limits the distance from the wielder to the handle target position
@export var targetReach: float = 30.
## Max weapon reach.
## Limits the distance from the wielder to the weapon handle
@export var wReach: float = 35.

## Wielder linear velocity inheritance ratio
@export var wielderLinInh: float = 0.8
## Wielder tangential velocity inheritance ratio
@export var wielderTanInh: float = 0.2

## Max weapon velocity
@export var maxVelocityMagn: float = 5000.

## Max linear force
@export var maxForce: float = 500000.
## Max torque
@export var maxTorque: float = 500000.

## Rotation spring strength for the rotation
@export var kAng: float = 12000.
## Spring damping ratio relative to critical damping
@export var drAng: float = 0.92
## Wielder angular velocity inheritance ratio
@export var wielderAngInh: float = 0.2
#endregion

#region State
## Damping coefficient
var damp: float = 0.

## Attack spring-based velocity component
var attackVel: Vector2 = Vector2.ZERO
#endregion

#region Methods
#region System
func _ready() -> void:
	super._ready()
	damp = drLin * 2. * sqrt(max(object.weapon.movementMass, 1e-5) * max(kLin, 0.))
	assert(object.get_property_list().any(func(p): return p.name == "returned"), 
		("Object controlled by StWeaponMovementBase must have [bool returned] field.")
	)

func physics_update(delta: float) -> void:
	# Handle the target point by limiting the distance
	# Get the target position and the wielder global position
	var target: Vector2 = object.wTarget
	var entGPos: Vector2 = object.weapon.lcRef.entity.global_position

	# Get the distance to entity
	var entTargetD: Vector2 = target - entGPos
	var entTargetDMagn: float = entTargetD.length()

	if entTargetDMagn > targetReach:
		target = entGPos + targetReach * entTargetD / entTargetDMagn
	

	# Get current handle state

	# Compute the displacement from the handle to the target
	var handleOffset: Vector2 = object.get_handle_offset()
	# Handle position
	var handlePosition: Vector2 = object.wPosition + handleOffset
	var relativeHandleVel: Vector2 = attackVel + object.springAngularVelocity * Vector2(-handleOffset.y, handleOffset.x)

	# Handle position and velocity
	# Compute the contribution from the linear motion spring
	var d: Vector2 = target - handlePosition

	# Handle the attack spring velocity
	var sF: Vector2 = max(kLin, 0.) * d
	# Compute damping from the attack velocity
	var dF: Vector2 = -damp * relativeHandleVel

	# Compute the final force
	var fF: Vector2 = sF + dF
	fF = fF.limit_length(maxForce)

	# Compute the linear acceleration
	var acc: Vector2 = fF / max(object.weapon.movementMass, 1e-5)

	# Apply the acceleration to the attack velocity
	attackVel += delta * acc

	# Compute the additional velocity component from the wielder movement
	var angularVelocity3: Vector3 = Vector3(0., 0., object.weapon.rcRef.angularVelocity)
	var r: Vector2 = handlePosition - entGPos
	var r3: Vector3 = Vector3(r.x, r.y, 0.)
	
	var tangVel3: Vector3 = angularVelocity3.cross(r3)
	var tangVel: Vector2 = Vector2(tangVel3.x, tangVel3.y)

	var wielderMomentum: Vector2 = wielderLinInh * object.weapon.lcRef.velocity + wielderTanInh * tangVel

	# Compute the velocity as the sum of sping and inherited velocity
	object.wVelocity = wielderMomentum + attackVel
	object.wVelocity = object.wVelocity.limit_length(maxVelocityMagn)

	# Update the position
	# In the attack state the full velocity of the weapon is used
	object.wPosition += delta * object.wVelocity

	# Limit the handle reach, then convert back to the weapon origin position.
	object.wPosition = _limit_to_reach(object.wPosition + handleOffset, entGPos, wReach) - handleOffset



	# Handle rotation and angular velocity
	# Compute the torque from linear force
	var fTorque: float = VectorMath.cross_2d(handleOffset, fF)
	# print(handleOffset)
	# var fTorque: float = 0

	# Compute the torque from the rotation sprin
	var springTorque: float = _compute_angular_spring_torque(kAng, drAng)
	springTorque = clampf(springTorque, -maxTorque, maxTorque)
	
	# Compute final torque
	var torque: float = fTorque + springTorque
	
	# Get safe inertia
	var sInertia: float = max(object.inertia, 1e-5)

	# Compute angular acceleration
	var aAcc: float = torque / sInertia

	# Integrate into the spring angular velocity component
	object.springAngularVelocity += aAcc * delta

	# Additionally inherit the wielder angular velocity
	object.angularVelocity = object.springAngularVelocity + wielderAngInh * object.weapon.rcRef.angularVelocity
	
	# Update the rotation
	object.rotation += object.angularVelocity * delta

# func physics_update(delta: float) -> void:
# 	# Get the target position and the wielder global position
# 	var target: Vector2 = object.wTarget
# 	var entGPos: Vector2 = object.weapon.lcRef.entity.global_position

# 	# Get the distance to entity
# 	var entTargetD: Vector2 = target - entGPos
# 	var entTargetDMagn: float = entTargetD.length()

# 	if entTargetDMagn > targetReach:
# 		target = entGPos + targetReach * entTargetD / entTargetDMagn
	
# 	# Compute the displacement from the handle to the target
# 	var handleOffset: Vector2 = object.weapon.handle.global_position - object.weapon.global_position
# 	var d: Vector2 = target - (object.wPosition + handleOffset)

# 	# Handle the attack spring velocity
# 	var sF: Vector2 = max(kLin, 0.) * d
# 	var dF: Vector2 = -damp * attackVel

# 	var acc: Vector2 = (sF + dF) / max(object.weapon.movementMass, 1e-5)
# 	attackVel += delta * acc

# 	# Compute the additional velocity component from the wielder movement
# 	var angularVelocity3: Vector3 = Vector3(0., 0., object.weapon.rcRef.angularVelocity)
# 	var r: Vector2 = object.wPosition - entGPos
# 	var r3: Vector3 = Vector3(r.x, r.y, 0.)
# 	var tangVel3: Vector3 = angularVelocity3.cross(r3)
# 	var tangVel: Vector2 = Vector2(tangVel3.x, tangVel3.y)

# 	var wielderMomentum: Vector2 = wielderLinInh * object.weapon.lcRef.velocity + wielderTanInh * tangVel

# 	# Compute the velocity as the sum of sping and inherited velocity
# 	object.wVelocity = wielderMomentum + attackVel
# 	object.wVelocity = object.wVelocity.limit_length(maxVelocityMagn)

# 	# Update the position
# 	# In the attack state the full velocity of the weapon is used
# 	object.wPosition += delta * object.wVelocity

# 	# Limit the handle reach, then convert back to the weapon origin position.
# 	object.wPosition = _limit_to_reach(object.wPosition + handleOffset, entGPos, wReach) - handleOffset

# 	# Handle the rotation
# 	_perform_rotation_target_spring_wielder(delta, kAng, drAng, wielderAngInh)

func enter(_previousState: String, _data := {}) -> void:
	object.returned = false
	attackVel = Vector2.ZERO
	object.springAngularVelocity = 0.
#endregion

#region Interface

#endregion

#region Private

#endregion
#endregion
