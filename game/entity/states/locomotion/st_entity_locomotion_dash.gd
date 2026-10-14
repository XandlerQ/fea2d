extends StEntityLocomotionBase
class_name StEntityLocomotionDash

#region Signals

#endregion

#region Exports
## Dash duration
@export var dashDuration: float = 0.15
## Scalar that defines the velocity of the dash
@export var dashMagnitude: float = 240.
## Curve that defines the velocity magnitude during the dash
@export var dashSpeedCurve: Curve = null

## Dash angular turn speed, defines how much control the player has over the dash direction
@export var dashTurnSpeed: float = 2. * PI
#endregion

#region State
## Dash duration timer
var dashTimer: Timer = null
## Dash direction
var dashDirection: Vector2 = Vector2.ZERO
#endregion

#region Methods
#region System
func _ready() -> void:
	super._ready()

	assert(dashSpeedCurve != null, 
		("Dash curve for StEntityLocomotionDash must be non null.")
	)
	
	dashTimer = Timer.new()
	dashTimer.wait_time = dashDuration
	dashTimer.one_shot = true
	self.add_child(dashTimer)
	
	dashTimer.timeout.connect(_on_dash_timer_timeout)

func physics_update(delta: float) -> void:
	if not dashTimer:
		return

	# Update the dash direction according to the input
	if dashTurnSpeed > 1e-5:
		var targetAngle: float = dashDirection.angle_to(object.direction)
		if abs(targetAngle) < 15. * PI / 16.:
			var angleLimit: float = delta * dashTurnSpeed

			dashDirection = dashDirection.rotated(
				clamp(targetAngle, -angleLimit, angleLimit)
			)
	
	# Get the current progress of the dash
	var t: float = clamp(1. - dashTimer.time_left / dashDuration, 0., 1.)
	# Get the supposed velocity magnitude
	var vMag: float = dashSpeedCurve.sample_baked(t) * dashMagnitude
	# Compute the actual velocity
	var dash: Vector2 = vMag * dashDirection
	
	object.velocity = dash

func enter(_previousState: String, _data := {}) -> void:
	completed = false
	dashDirection = object.direction
	dashTimer.start()
#endregion

#region Interface
## An interruptability flag interface override
func is_interruptible() -> bool:
	return false
#endregion

#region Private
func _on_dash_timer_timeout():
	completed = true
#endregion
#endregion
