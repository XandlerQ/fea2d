extends Line2D
class_name VisualTrail

#region Signals

#endregion

#region Exports
## The reference to the node that defines the emission point
@export var emitterPoint: Node2D = null

## Point lifetime, defines how long each trail point exists before being removed.
## Set to negative to disable point lifetime tracking
@export var pLifetime: float = 0.3

## Maximum amount of trail points, and a size of running index array
@export var maxPoints: int = 20

@export_group("Velocity Related Control")
## Velocity dependent flag: if true, the visual
## trail will search for the velocity property of the
## owner object, and enable itself according to the velocity
## magnitude
@export_custom(PROPERTY_HINT_GROUP_ENABLE, "")
var velDep: bool = false

## Flag for flushing all points when velocity drops
## below the minimal velocity minVel.
## Keep in mind that if this is set to false, then
## if some trail path exists, but then is interupted
## due to low velocity, and then the velocity rises again
## above the min value, the trail will connect the end of the
## old trail part with the new tral, resulting in broken trails,
## long straight segments, etc.
@export var flushWhenSlow: bool = false

## The owner object to monitor velocity field of
@export var velOwner: Node = null
## The minimum velocity for the tral to form
@export var minVel: float = 250.
#endregion

#region State
## The flag for enabling/disabling adding new points
var enabled: bool = true

## Velocity enabled flag: determines if new points
## should be added according to the velDep logic
var velEnabled: bool = true

## Array that hold lifetimes of points
var pTimes: Array[float] = []

## Running index for lifetime computations
var runningIndex: int = 0
#endregion

#region Methods
#region System
func _ready() -> void:
	top_level = true

	assert(emitterPoint != null, 
		("Emitter point of VisualTrail must be non null.")
	)

	if maxPoints <= 1:
		maxPoints = 2

	pTimes.resize(maxPoints)
	pTimes.fill(-1.)

	if velDep:
		if not velOwner:
			velDep = false
			print_debug("VisualTrail: Missing velOwner velocity owner, turing velocity dependence off.")
		else:
			assert(velOwner.get_property_list().any(func(p): return p.name == "velocity"), 
				("Velocity owner object of VisualTrail must have [Vector2 velocity] field.")
			)
		

func _physics_process(delta: float) -> void:
	if get_point_count() == 0 and not enabled:
		return

	# Update point lifetimes
	_update_point_times(delta)

	# Check if point needs to be added

	# Remove point if the point array is full
	while get_point_count() >= maxPoints:
		# Remove point
		remove_point(0)
		pTimes[runningIndex] = -1.
	
	# Remove points that are too old:
	_remove_old_points()

	# Add the point
	if enabled:
		if velDep:
			_update_vel_enabled()
			if velEnabled:
				add_timed_point(emitterPoint.global_position)
			else:
				if flushWhenSlow:
					_flush_all_points()
		else:
			add_timed_point(emitterPoint.global_position)
		

#endregion

#region Interface
func add_timed_point(point: Vector2) -> void:
	add_point(point)
	pTimes[runningIndex] = 0.
	runningIndex = _fix_running_index(runningIndex + 1)
#endregion

#region Private
func _update_point_times(delta: float) -> void:
	for i in range(maxPoints):
		if pTimes[i] >= 0.:
			pTimes[i] += delta

func _flush_all_points() -> void:
	if get_point_count() > 0:
		clear_points()
		pTimes.fill(-1.)
			

func _remove_old_points() -> int:
	if pLifetime < 0.:
		return 0
	var pRemoved: int = 0
	for i in range(maxPoints):
		if pTimes[i] >= pLifetime:
			remove_point(0)
			pTimes[i] = -1.
			pRemoved += 1
	return pRemoved

func _fix_running_index(index: int) -> int:
	var i: int = index
	while i < 0:
		i += maxPoints
	while i >= maxPoints:
		i -= maxPoints
	return i

func _update_vel_enabled() -> void:
	var ownerVelocity: Vector2 = velOwner.velocity
	velEnabled = ownerVelocity.length() >= minVel
#endregion
#endregion
