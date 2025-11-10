extends Node
class_name TimerPlus

signal timeout()
signal stopped(current_time: TimeStamp)
signal paused(current_time: TimeStamp)
signal started()
signal tick(time: TimeStamp)

## The set amount of time before the timer times out
@export var _wait_time: TimeStamp
## Whether or not the timer should stop when it times out. 
## If false, the timer will restart on timeout.
@export var _one_shot: bool = true
## The amount of time that must elapse before the timer ticks.
## The time stamp must not be zero
@export var _interval: TimeStamp

var _current_time: TimeStamp
var _stopped: bool = true
var _paused: bool = false
var _running: bool = false

## Starts the timer.
func start() -> void:
	if not _stopped and not _paused:
		return #no point in starting the timer if it's already started.
	
	if _stopped and not _current_time.is_equal(_wait_time):
		_current_time.set_time(_wait_time)
	
	_stopped = false
	_paused = false

## Pauses the timer at it's current time. Can be resumed by calling start().
func pause() -> void:
	if _paused:
		return
	
	_paused = true
	paused.emit(get_time_left())

## Stops the timer and resets it back to wait_time.
func stop() -> void:
	if _stopped:
		return
	
	_stopped = true
	_paused = false
	stopped.emit(get_time_left())

## Resets the timer
func reset() -> void:
	if not is_instance_valid(_current_time):
		return
	
	if is_instance_valid(_wait_time):
		_current_time.set_time(_wait_time)

## Returns if the timer is stopped.
func is_stopped() -> bool:
	return _stopped

func is_paused() -> bool:
	return _paused

## Returns if the timer only runs once.
func is_one_shot() -> bool:
	return _one_shot

## Sets if the timer is one shot, meaning, it stops when it times out.
func set_one_shot(p_one_shot: bool) -> void:
	_one_shot = p_one_shot

## Returns the set wait time of the timer. 
## This is NOT the time left on the timer. Use get_time_left() for that.
func get_wait_time() -> TimeStamp:
	if not is_instance_valid(_wait_time):
		return null
	
	var ret: TimeStamp = TimeStamp.new()
	ret.set_time(_wait_time)
	return ret

## Sets the wait time.
func set_wait_time(p_value: TimeStamp) -> void:
	_wait_time = p_value
	reset()

## Returns the time left on the timer.
func get_time_left() -> TimeStamp:
	if not is_instance_valid(_current_time):
		return null
	
	var ret: TimeStamp = TimeStamp.new()
	ret.set_time(_current_time)
	return ret

## Sets the tick interval of the timer. The timer will tick at intervals of the passed time stamp.
func set_tick_interval(p_value: TimeStamp) -> void:
	if not is_instance_valid(p_value): #_interval must be valid
		printerr("Cannot set time interval. Passed value was not valid.")
		return
	
	_interval = p_value

## Returns the set tick interval
func get_tick_interval() -> TimeStamp:
	var ret: TimeStamp = TimeStamp.new()
	ret.set_time(_interval)
	return ret

func _ready() -> void:
	if not is_instance_valid(_interval):
		_interval = TimeStamp.new()
		_interval.set_time_milliseconds(100)
	
	_current_time = TimeStamp.new()
	reset()

func _run() -> void:
	_running = true
	started.emit()
	
	while not _current_time.is_timed_out() and not _stopped and not _paused:
		tick.emit(get_time_left()) #NOTE: This potentialy could be a problem because get_time_left() creates a new TimeStamp object everytime it is called
		var interval_seconds: float = _interval.get_time_seconds()
		await get_tree().create_timer(interval_seconds).timeout
		
		if not _stopped and not _paused: #it's possible that either stop() or paused() was called while awaiting
			_current_time.elapse(_interval)
	
	if _current_time.is_timed_out():
		timeout.emit()
		
		if is_one_shot():
			stop()
		else:
			reset()
	
	_running = false

@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	# Its done this way to prevent _run() from calling itself recursively if the timer happens to loop.
	# This is to prevent the possibility a stack overflow.
	if not _stopped and not _paused and not _running:
		_run()
