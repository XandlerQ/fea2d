@tool
extends PhysicsObject2D
## Physics object that removes itself when its health is depleted.
class_name BreakablePhysicsObject2D

#region Signals

#endregion

#region Exports
## Scene-owned health component.
@onready var healthComponent: HealthComponent = get_node_or_null("%HealthComponent") as HealthComponent
#endregion

#region State

#endregion

#region Methods
#region System
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	super()

	assert(
		healthComponent != null,
		"BreakablePhysicsObject2D requires a unique HealthComponent child."
	)

	if not healthComponent.health_depleted.is_connected(_on_health_depleted):
		healthComponent.health_depleted.connect(_on_health_depleted)
#endregion

#region Interface
func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = super()

	if not (get_node_or_null("%HealthComponent") is HealthComponent):
		warnings.append("A unique HealthComponent child is required.")

	return warnings
#endregion

#region Private
func _on_health_depleted(_atkContext: AttackContext) -> void:
	queue_free()
#endregion
#endregion
