@tool
extends Node
class_name CProjectileCaster

#region Signals

#endregion

#region Exports
## Test projectile to cast
@export var projectilePackedScene: PackedScene
## Projectile spawn point
@export var projectileSpawnPoint: Marker2D
## Container for the spawned projectiles
@export var projectileContainer: ProjectileContainer
#endregion

#region State

#endregion

#region Methods
#region System
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Search for the prjectile container in the tree
	if not projectileContainer:
		var containers := get_tree().get_nodes_in_group("projectile_containers")

		for node in containers:
			if node is ProjectileContainer:
				projectileContainer = node

#endregion

#region Interface
func cast_projectile(attacker: Node, initialVelocity: Vector2 = Vector2.ZERO) -> void:
	pass
	# # Create a new instance of a projectile
	# var projectile: Projectile = projectilePackedScene.instantiate() as Projectile

	# # Set up all of the information for the launch
	# var origin: Vector2 = projectileSpawnPoint.global_position
	# var launch_direction: Vector2 = projectileSpawnPoint.global_transform.x.normalized()
	
	# projectileContainer.add_child(projectile)
	# projectile.launch(origin, launch_direction, initialVelocity, attacker)

	# # Make sure that the initial orientation is correct
	# projectile.look_at(origin + launch_direction)

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if not projectilePackedScene:
		warnings.append("A projectile PackedScene is required.")
	if not projectileSpawnPoint:
		warnings.append("A projectile spawn point is required.")
	return warnings

#endregion

#region Private

#endregion
#endregion
