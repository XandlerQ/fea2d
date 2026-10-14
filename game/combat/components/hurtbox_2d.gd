@tool
extends Area2D
## Universal 2D hurtbox class.
## Receives attack contexts and forwards them to interested systems.
class_name Hurtbox2D

#region Signals
signal attack_received(atkContext: AttackContext)

signal collision_impact_received_pcr2d(collisionResult: PhysicsCollisionResult2D)
#endregion

#region Exports
## Owner of this hitbox
@export var hbOwner: Node2D = null
#endregion

#region State

#endregion

#region Methods
#region System

#endregion

#region Interface
## Passes a valid attack context to the listeners
func receive_attack_context(atkContext: AttackContext) -> bool:
	if not atkContext:
		return false

	attack_received.emit(atkContext)
	return true

func receive_collision_impact_pcr2d(collisionResult: PhysicsCollisionResult2D) -> bool:
	if not collisionResult:
		return false
	
	collision_impact_received_pcr2d.emit(collisionResult)
	return true

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not hbOwner:
		warnings.append("A hurtbox owner is required.")
	if not get_children().any(func(child: Node): return child is CollisionShape2D or child is CollisionPolygon2D):
		warnings.append("A collision shape or polygon child is required.")
	return warnings
#endregion

#region Private

#endregion
#endregion
