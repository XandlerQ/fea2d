extends State
## Base class for states that control
## entity movement. Has an export variable
## [object] for a node that MUST have the [Vector2
## velocity] and [Vector2 direction] fields
## that are being changed by this state.
class_name StEntityLocomotionBase

#region Signals

#endregion

#region Exports
## Controlled object. MUST have [Vector2 velocity] and
## [Vector2 direction] fields.
@export var object: Node
#endregion

#region State

#endregion

#region Methods
#region System
func _ready() -> void:
	assert(object != null, 
		("Object controlled by StEntityLocomotionBase must be non null.")
	)
	assert(object.get_property_list().any(func(p): return p.name == "velocity"), 
		("Object controlled by StEntityLocomotionBase must have [Vector2D velocity] field.")
	)
	assert(object.get_property_list().any(func(p): return p.name == "direction"), 
		("Object controlled by StEntityLocomotionBase must have [Vector2D direction] field.")
	)
#endregion

#region Interface

#endregion

#region Private
func _decelerate(velocity: Vector2, friction: float, delta: float) -> Vector2:
	# Define result velocity
	var vRes: Vector2 = Vector2.ZERO

	# Magnitude
	var vM: float = velocity.length()
	# Magnitude change
	var dVM: float = delta * friction

	# If stationary or close to stationary return ZERO
	if vM <= dVM or vM <= 1e-5:
		return Vector2.ZERO
	
	# Else decelerate due to friction
	vRes = velocity - dVM * (velocity / vM)
	return vRes

func _accelerate(velocity: Vector2, acceleration: float, friction: float, direction: Vector2, targetMagnitude: float, delta: float) -> Vector2:
	# Define result velocity
	var vRes: Vector2 = Vector2.ZERO

	# Magnitude
	var vM: float = velocity.length()

	# Compute the magnitude limiting value
	var limVal: float = max(vM - friction * delta, targetMagnitude)

	if direction.length_squared() > 1e-10:
		# If stationary or close to stationary just accelerate in the given direction
		if vM <= 1e-5:
			vRes = velocity + delta * acceleration * direction
		# Else do the computations
		else:
			vRes = velocity
			# Velocity direction
			var vDir: Vector2 = velocity / vM
			
			var vDirDotDirection: float = vDir.dot(direction)
			# If current velocity is opposite to desired direction
			if vDirDotDirection < 0.:
				# Decelerate first
				vRes += delta * friction * vDirDotDirection * vDir
			
			# Accelerate in the desired direction
			vRes += delta * acceleration * direction
	
	# Limit velocity length
	vRes = vRes.limit_length(limVal)

	return vRes
		
#endregion
#endregion
