extends Area2D
## Universal 2D hitbox class.
## Detects hurtboxes and reports collision information.
class_name Hitbox2D

#region Signals
signal hurtbox_collision_detected(collisionInfo: CollisionInfo2D)
#endregion

#region Exports
## Same hurtbox collision cooldown
@export var hitCooldown: float = 0.02

#endregion

#region State
## Dictionary for the last time hurtboxes were hit
var lastHitTimeDict: Dictionary = {}
## Immediate detection gate while the engine applies deferred monitoring changes.
var _detectionEnabled: bool = true

#endregion

#region Methods
#region System
func _ready() -> void:
	if not area_shape_entered.is_connected(_on_area_shape_entered):
		area_shape_entered.connect(_on_area_shape_entered)
#endregion

#region Interface
## Enables detection safely, including when called during a physics signal.
func set_detection_enabled(enabled: bool) -> void:
	_detectionEnabled = enabled
	set_deferred("monitoring", enabled)

## Clears the remembered hurtboxes
func clear_hit_memory() -> void:
	lastHitTimeDict.clear()

#endregion

#region Private
func _can_hit_hurtbox(hbox: Hurtbox2D) -> bool:
	if hitCooldown <= 0.:
		return true

	var id: int = hbox.get_instance_id()

	if not lastHitTimeDict.has(id):
		return true

	var now: float = Time.get_ticks_msec() / 1000.
	var dt: float = now - float(lastHitTimeDict[id])
	return dt >= hitCooldown

func _remember_hit(hbox: Hurtbox2D) -> void:
	if hitCooldown <= 0.:
		return

	var id: int = hbox.get_instance_id()
	lastHitTimeDict[id] = Time.get_ticks_msec() / 1000.

func _on_area_shape_entered(
	_areaRid: RID,
	area: Area2D,
	areaShapeIndex: int,
	localShapeIndex: int
) -> void:
	if not _detectionEnabled:
		return
	if area is Hurtbox2D:
		if not _can_hit_hurtbox(area):
			return

		# Create the collision info object
		var collisionInfo: CollisionInfo2D = CollisionInfo2D.new()
		# Capture the pair; consumers request contact geometry only when needed.
		collisionInfo.fill_from_shape_pair(self, area, localShapeIndex, areaShapeIndex)

		_remember_hit(area)
		hurtbox_collision_detected.emit(collisionInfo)


#endregion
#endregion
