extends RigidBody2D
## Describes a rigid object affected by physics.
## An extension of an existing RigidBody2D class
class_name PhysicsObject2D

#region Signals

#endregion

#region Exports
@export var hurtbox: Hurtbox2D = null
#endregion

#region State
## Positional correction consumed safely during the physics integration.
## Instead of changing the position agressively, do it using the built-in
## overridable function _integrate_forces
var _pendingPosCor: Vector2 = Vector2.ZERO

#endregion

#region Methods
#region System
func _ready() -> void:
	if hurtbox:
		if not hurtbox.collision_impact_received_pcr2d.is_connected(_on_hurtbox_collision_impact_received_pcr2d):
			hurtbox.collision_impact_received_pcr2d.connect(_on_hurtbox_collision_impact_received_pcr2d)


## Override the function to apply the positional correction
## during the engine physics integration
func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if not freeze:
		var trfm: Transform2D = state.transform
		trfm.origin += _pendingPosCor
		
		state.transform = trfm
	
	_pendingPosCor = Vector2.ZERO

#endregion

#region Interface
## Applies an impulse at the contact point; its offset already supplies torque.
func apply_collision_response(result: PhysicsCollisionResult2D, side: PhysicsCollisionInfo2D.Side = PhysicsCollisionInfo2D.Side.TARGET) -> void:
	if not result or not result.resolved or freeze:
		return
	
	var isSource: bool = side == PhysicsCollisionInfo2D.Side.SOURCE
	
	var correction: Vector2 = result.posCorrS if isSource else result.posCorrT
	_pendingPosCor += correction
	
	if not correction.is_zero_approx():
		sleeping = false
	
	if result.separating or not result.collisionInfo or not result.collisionInfo.hasContactGeometry:
		return
	
	var impulse: Vector2 = result.ImpLinS if isSource else result.ImpLinT
	
	apply_impulse(impulse, result.collisionInfo.globalPosition - global_position)
	# apply_impulse(Vector2(1., 0.), result.collisionInfo.globalPosition - global_position)
	print("Applied impulse")
	print(impulse)

## Uses the the fall-back filler
func fill_collision_physics_info(info: PhysicsCollisionInfo2D, side: PhysicsCollisionInfo2D.Side) -> bool:
	return info.fill_from_body(self, side)

#endregion

#region Private
func _on_hurtbox_collision_impact_received_pcr2d(collisionResult: PhysicsCollisionResult2D) -> void:
	apply_collision_response(collisionResult, PhysicsCollisionInfo2D.Side.TARGET)
#endregion
#endregion
