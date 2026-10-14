extends Line2D
class_name VisualTrailSegment

#region Signals
signal empty(trailSegment: VisualTrailSegment)
#endregion

#region Exports
## Point lifetime, defines how long each trail point exists before being removed.
## Set to negative to disable point lifetime tracking
@export var pLifetime: float = 0.3

## Maximum amount of trail points, and a size of running index array
@export var maxPoints: int = 20
#endregion

#region State
## Array that hold lifetimes of points
var pTimes: Array[float] = []

## Running index for lifetime computations
var runningIndex: int = 0

## Finished flag. Indicates that the segment is finished
## and will not receive any new points from the controller
var finished: bool = false
#endregion

#region Methods
#region System
func _ready() -> void:
	top_level = true
	
	if maxPoints <= 1:
		print_debug("VisualTrailSegment: max points set as 1 or lower: changed to 2.")
		maxPoints = 2

	pTimes.resize(maxPoints)
	pTimes.fill(-1.)


func _physics_process(delta: float) -> void:
	if get_point_count() > 0:
		# Update point lifetimes
		_update_point_times(delta)

		# Remove points that are too old:
		_remove_old_points()

	if finished:
		if pLifetime <= 0. or get_point_count() == 0:
			empty.emit(self)
			set_physics_process(false)
			return
#endregion

#region Interface
func reset() -> void:
	clear_points()

	pTimes.resize(maxPoints)
	pTimes.fill(-1.0)

	runningIndex = 0
	finished = false
	set_physics_process(true)


func add_timed_point(point: Vector2) -> void:
	# Remove the excess point if necessary
	while get_point_count() >= maxPoints:
		remove_point(0)
		pTimes[runningIndex] = -1.

	add_point(point)
	pTimes[runningIndex] = 0.
	runningIndex = _fix_running_index(runningIndex + 1)


func finish() -> void:
	finished = true
#endregion

#region Private
func _update_point_times(delta: float) -> void:
	for i in range(maxPoints):
		if pTimes[i] >= 0.:
			pTimes[i] += delta


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
	return posmod(index, maxPoints)
#endregion
#endregion
