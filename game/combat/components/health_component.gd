@tool
extends Node
## Stores health state and translates attacks received by configured hurtboxes
## into health changes. The owner decides how to react when health is depleted.
class_name HealthComponent

#region Signals
signal health_changed(previousHealth: float, currentHealth: float, maxHealth: float)
signal damage_received(appliedDamage: float, atkContext: AttackContext)
signal health_depleted(atkContext: AttackContext)
#endregion

#region Exports
## Hurtboxes that forward received attacks to this health component.
@export var hurtboxes: Array[Hurtbox2D] = []

## Maximum and initial health.
@export var maxHealth: float = 100.
#endregion

#region State
var currentHealth: float = 0.
#endregion

#region Methods
#region System
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	assert(maxHealth > 0., "HealthComponent maxHealth must be greater than zero.")
	currentHealth = maxHealth

	for hurtbox: Hurtbox2D in hurtboxes:
		assert(hurtbox != null, "HealthComponent has an invalid Hurtbox2D reference.")
		if not hurtbox.attack_received.is_connected(receive_attack):
			hurtbox.attack_received.connect(receive_attack)
#endregion

#region Interface
## Applies the damage carried by an attack context.
func receive_attack(atkContext: AttackContext) -> void:
	if not atkContext:
		return

	apply_damage(atkContext.damage, atkContext)

## Removes health and returns the amount that was actually removed.
func apply_damage(amount: float, atkContext: AttackContext = null) -> float:
	if amount <= 0. or is_depleted():
		return 0.

	var previousHealth: float = currentHealth

	currentHealth = maxf(currentHealth - amount, 0.)
	var appliedDamage: float = previousHealth - currentHealth

	health_changed.emit(previousHealth, currentHealth, maxHealth)
	damage_received.emit(appliedDamage, atkContext)

	if is_depleted():
		health_depleted.emit(atkContext)

	return appliedDamage

## Restores health and returns the amount that was actually restored.
func restore_health(amount: float) -> float:
	if amount <= 0.:
		return 0.
	
	if currentHealth >= maxHealth:
		currentHealth = maxHealth
		return 0.

	var previousHealth: float = currentHealth

	currentHealth = minf(currentHealth + amount, maxHealth)
	health_changed.emit(previousHealth, currentHealth, maxHealth)

	return currentHealth - previousHealth

func is_depleted() -> bool:
	return currentHealth <= 0.

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if maxHealth <= 0.:
		warnings.append("Maximum health must be greater than zero.")

	for hurtbox: Hurtbox2D in hurtboxes:
		if not hurtbox:
			warnings.append("All configured hurtbox references must be valid Hurtbox2D nodes.")
			break

	return warnings
#endregion

#region Private

#endregion
#endregion
