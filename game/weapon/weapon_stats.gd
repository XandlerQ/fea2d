extends Resource
## A resource that describes the stats 
## of a weapon.
class_name WeaponStats

#region Exports
## Base damage of the attack
@export var damage: float = 0.

## Weapon attack mass (for collision impact computation)
@export var attackMass: float = 1.
## Weapon attack rotation inertia (for collision impact computation)
@export var attackInertia: float = 1. * 22.5 * 22.5 / 12.
#endregion
