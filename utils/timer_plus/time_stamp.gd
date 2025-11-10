extends Resource
class_name TimeStamp

const MILLISECONDS_IN_AN_HOUR: int = 3600000
const MILLISECONDS_IN_A_MINUTE: int = 60000
const MILLISECONDS_IN_A_SECOND: int = 1000
const SECONDS_IN_A_HOUR: int = 3600
const SECONDS_IN_A_MINUTE: int = 60
const MINUTES_IN_AN_HOUR: int = 60

# This value should never be negative
var _milliseconds: int = 0
@export var milliseconds: int: get = get_milliseconds, set = set_milliseconds
@export var seconds: int: get = get_seconds, set = set_seconds
@export var minutes: int: get = get_minutes, set = set_minutes
@export var hours: int: get = get_hours, set = set_hours

## Sets the current time using the passed time stamp.
func set_time(p_copy: TimeStamp) -> void:
	set_time_milliseconds(p_copy.get_time_milliseconds())

## Elapese the time using the passed time stamp
func elapse(p_amount: TimeStamp) -> void:
	if is_timed_out():
		return
	
	elapse_milliseconds(p_amount.get_time_milliseconds())

## Elapse the current time by p_amount milliseconds.
func elapse_milliseconds(p_amount: int):
	if is_timed_out():
		return
	
	_milliseconds -= p_amount
	
	if _milliseconds < 0:
		_milliseconds = 0

##Elapse the current time by p_amount seconds
func elapse_seconds(p_amount: float) -> void:
	if is_timed_out():
		return
	
	var milliseconds: int = roundi(p_amount * MILLISECONDS_IN_A_SECOND)
	elapse_milliseconds(milliseconds)

##Elapse the current time by p_amount minutes
func elapse_minutes(p_amount: float) -> void:
	if is_timed_out():
		return
	
	var milliseconds: int = roundi(p_amount * MILLISECONDS_IN_A_MINUTE)
	elapse_milliseconds(milliseconds)

##Elapse the current time by p_amount hours
func elapse_hours(p_amount: float) -> void:
	if is_timed_out():
		return
	
	var milliseconds: int = roundi(p_amount * MILLISECONDS_IN_AN_HOUR)
	elapse_milliseconds(milliseconds)

## Returns the current time in milliseconds.
func get_time_milliseconds() -> int:
	return _milliseconds

## Returns the current time in seconds.
func get_time_seconds() -> float:
	var ret: float = float(_milliseconds) / MILLISECONDS_IN_A_SECOND
	return ret

## Returns the current time in minutes.
func get_time_minutes() -> float:
	var ret: float = float(_milliseconds) / MILLISECONDS_IN_A_MINUTE
	return ret

## Returns the current time in hours.
func get_time_hours() -> float:
	var ret: float = float(_milliseconds) / MILLISECONDS_IN_AN_HOUR
	return ret

## Returns the millisecond component of the time stamp.
func get_milliseconds() -> int:
	var total_hours: int = get_hours()
	var total_minutes: int = get_minutes()
	var total_seconds: int = get_seconds()
	var ret: int = (_milliseconds - (total_hours * MILLISECONDS_IN_AN_HOUR) -  \
	(total_minutes * MILLISECONDS_IN_A_MINUTE) - (total_seconds * MILLISECONDS_IN_A_SECOND))
	return ret

## Sets the millisecond component of the current time. Must be between 0 and 999 milliseconds.
func set_milliseconds(p_value: int) -> void:
	var milliseconds: int = p_value
	
	#sanitize input
	if milliseconds > MILLISECONDS_IN_A_SECOND - 1:
		milliseconds = 999
	if milliseconds < 0:
		milliseconds = 0
	
	#remove current milliseconds from the current time
	var current_milliseconds: int = get_milliseconds()
	_milliseconds -= current_milliseconds
	
	#add set milliseconds into the current time
	_milliseconds += milliseconds

## Returns only the second component of the current time
func get_seconds() -> int:
	var hours: int = get_hours()
	var minutes: int = get_minutes()
	@warning_ignore("integer_division")
	var ret: int = (_milliseconds - (hours * MILLISECONDS_IN_AN_HOUR) - \
	(minutes * MILLISECONDS_IN_A_MINUTE)) / MILLISECONDS_IN_A_SECOND
	return ret

## Sets the second component of the current time. Must be between 0 and 59.
func set_seconds(p_value: int) -> void:
	var seconds: int = p_value
	
	#sanitize input
	if seconds > SECONDS_IN_A_MINUTE - 1:
		seconds = 59
	if seconds < 0:
		seconds = 0
	
	#remove the seconds from the current time.
	var current_seconds: int = get_seconds()
	_milliseconds -= current_seconds * MILLISECONDS_IN_A_SECOND
	
	#Add set seconds into the current time.
	_milliseconds += seconds * MILLISECONDS_IN_A_SECOND

## Returns only the minute component of the current time
func get_minutes() -> int:
	#return _minutes
	
	var hours: int = get_hours()
	@warning_ignore("integer_division")
	var ret: int = (_milliseconds - (hours * MILLISECONDS_IN_AN_HOUR)) / \
	MILLISECONDS_IN_A_MINUTE
	return ret

func set_minutes(p_value: int) -> void:
	var minutes: int = p_value
	
	#sanitize input
	if minutes > MINUTES_IN_AN_HOUR - 1:
		minutes = 59
	if minutes < 0:
		minutes = 0
	
	#remove minutes from the current time
	var current_minutes: int = get_minutes()
	_milliseconds -= current_minutes * MILLISECONDS_IN_A_MINUTE
	
	#Add set minutes into the current time
	_milliseconds += minutes * MILLISECONDS_IN_A_MINUTE

## Returns only the hour component of the current time.
func get_hours() -> int:
	#return _hours
	
	@warning_ignore("integer_division")
	var ret: int = _milliseconds / MILLISECONDS_IN_AN_HOUR
	return ret

func set_hours(p_value: int) -> void:
	var hours: int = p_value
	
	#Sanitize input
	if hours < 0:
		hours = 0
	
	#remove hours from the current time
	var current_hours: int = get_hours()
	_milliseconds -= current_hours * MILLISECONDS_IN_AN_HOUR
	
	#Add set hours into the current time
	_milliseconds += hours * MILLISECONDS_IN_AN_HOUR

## Sets the time in milliseconds. Will set the time to 0 if given a negative value.
func set_time_milliseconds(p_value: int) -> void:
	_milliseconds = p_value
	if _milliseconds < 0:
		_milliseconds = 0

## Sets the time in seconds. Will set the time to 0 if given a negative value
func set_time_seconds(p_value: float) -> void:
	var milliseconds: int = floori(p_value * MILLISECONDS_IN_A_SECOND)
	set_time_milliseconds(milliseconds)

## Sets the minutes. Will set to 0 if given a negative value.
func set_time_minutes(p_value: float) -> void:
	var milliseconds: int = floori(p_value * MILLISECONDS_IN_A_MINUTE)
	set_time_milliseconds(milliseconds)

##Sets the hours. Will set to 0 if given a negative value.
func set_time_hours(p_value: float) -> void:
	var milliseconds: int = floori(p_value * MILLISECONDS_IN_AN_HOUR)
	set_time_milliseconds(milliseconds)

## Returns whether or not the timestamp is set to zero on everything.
## AKA, it has "timed out"
func is_timed_out() -> bool:
	return _milliseconds == 0 #and _seconds == 0 and _minutes == 0 and _hours == 0

## Returns whether or not the passed time stamp's current time is equal to
## this time stamp's current time.
func is_equal(p_compare: TimeStamp) -> bool:
	return _milliseconds == p_compare.get_time_milliseconds()

func _init(milliseconds: int = 0, seconds: int = 0, minutes: int = 0, hours: int = 0) -> void:
	set_milliseconds(milliseconds)
	set_seconds(seconds)
	set_minutes(minutes)
	set_hours(hours)
