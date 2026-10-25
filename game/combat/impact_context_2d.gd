extends RefCounted
## Describes a contact impact for gameplay and presentation systems.
class_name ImpactContext2D

#region Signals

#endregion

#region Exports

#endregion

#region State
## Gameplay object that caused the impact.
var source: Node = null
## Gameplay object that received the impact.
var target: Node = null

## Global contact position.
var globalPosition: Vector2 = Vector2.ZERO
## World-space contact normal pointing from the target toward the source.
var normal: Vector2 = Vector2.ZERO

## Source velocity at the contact point before collision response.
var cpVelS: Vector2 = Vector2.ZERO
## Target velocity at the contact point before collision response.
var cpVelT: Vector2 = Vector2.ZERO
#endregion

#region Methods
#region System

#endregion

#region Interface

#endregion

#region Private

#endregion
#endregion
