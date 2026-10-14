extends RefCounted
## Class that describes a concrete attack.
## Created by an attacking object and passed
## to a hurtbox to process being hit.
class_name AttackContext

#region Signals

#endregion

#region Exports

#endregion

#region State
## The attackingObject object.
## Holds the reference to the exact object that caused the attack,
## unlike the collision info that holds reference to CollisionObject2D's
## that collided.
var attackingObject: Node = null

## The attacked target object
var target: Node = null

## Attack stats used to create the attack.
## Note that the final damage and impulse may have different values
## compared to the base raw values in the WeaponStats
var attackStats: WeaponStats = null

## Final damage of the attack as seen by the attackingObject, i.e.
## before computing all of the resistances of the target.
var damage: float = 0.
#endregion

#region Methods
#region System

#endregion

#region Interface

#endregion

#region Private

#endregion
#endregion
