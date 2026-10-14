extends Node2D
class_name Projectile

#region Signals

#endregion

#region Exports
## Lifetime timer node
@onready var lifetimeTimer: Timer = $LifetimeTimer
## Lifetime
@export var lifetime: float = 20.
#endregion

#region State

#endregion

#region Methods
#region System
func _ready() -> void:
	# Lifetime timer setup
	lifetimeTimer.wait_time = lifetime
	lifetimeTimer.one_shot = true
	lifetimeTimer.timeout.connect(_on_lifetime_timer_timeout)
	lifetimeTimer.start()
#endregion

#region Interface

#endregion

#region Private
func _on_lifetime_timer_timeout() -> void:
	_despawn()

func _despawn() -> void:
	queue_free()
#endregion
#endregion
