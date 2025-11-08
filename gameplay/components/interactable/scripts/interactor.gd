extends Node
class_name Interactor
## Used to target and interact with other [Interactable] instances. Can either interact a single time
## or can continuously interact with it's target at a set rate. Can recieve data back from the
## targeted [Interactable] about each interaction.

## Emitted when an interaction is started with a call to [method start_interaction]
signal interaction_started()
## Emmitted when an interaction has ended with a call to [method end_interaction]
signal interaction_ended()
## Emitted when the target is interacted with, either after each interaction cycle or when
## [method interact_once] is called. Returns [param p_data], which optionally contains data
## about the interaction.
signal interacted(p_data: Variant)

## The targeted [Interactable], which has it's [method Interactable.interact] method called
## by this [Interacter]
@export var target: Interactable:
	get:
		return _target
	set(p_val):
		if is_instance_valid(_target):
			_target.deselect()
		
		_target = p_val
		
		if not is_instance_valid(_target) and _interacting:
			end_interaction() # Because we can't interact with an invalid target.
		
		if is_instance_valid(_target):
			_target.select()

## The interaction rate, measured in interactions per minute.
@export_range(1, 2000, 1, "prefix:interactions per minute") var interaction_rate: int:
	get:
		@warning_ignore("narrowing_conversion")
		return 60 / _interaction_time
	set(p_val):
		if p_val < 1:
			_interaction_time = 60.0
		elif  p_val > 2000:
			_interaction_time = 0.03
		else:
			_interaction_time = 60.0 / p_val

## An array of arguments that will be passed to [method Interactable.interact] when an interaction
## occurs.
@export var interaction_args: Array:
	get:
		return _interaction_args
	set(p_val):
		_interaction_args = p_val

var _interaction_time: float
var _current_time: float
var _target: Interactable
var _interacting: bool
var _interaction_args: Array


func _process(p_delta: float) -> void:
	_tick(p_delta)

## Interacts with [member target] once. Returns data about the interaction, if any.
func interact_once() -> Variant:
	if not is_instance_valid(_target):
		push_error("Cannot interact with an invalid target.")
		return
	
	var ret: Variant = _target.interact(_interaction_args)
	interacted.emit(ret)
	return ret

## Starts an interaction with [member target]. Interactions happen at [member interaction_rate].
## Interactions will continue until either [method end_interaction] is called or until 
## [member target] is set to null.
func start_interaction() -> void:
	if not is_instance_valid(_target):
		push_error("Cannot interact with an invalid target.")
		return
	
	_interacting = true
	interaction_started.emit()


## Ends an ongoing interaction with [member target]. Does nothing if no interaction is happening.
func end_interaction() -> void:
	if not _interacting:
		return
	
	_interacting = false
	interaction_ended.emit()


## Returns whether this interacter is currently interacting with [member target].
func is_interacting() -> bool:
	return _interacting


func _tick(p_delta: float) -> void:
	if not _interacting:
		return
	
	if not is_instance_valid(_target): # this could happen at any time if the target gets queue_freed()
		end_interaction()
		return
	
	_current_time -= p_delta
	if _current_time <= 0:
		_interact()
		_reset()


func _interact() -> void:
	assert(is_instance_valid(_target), "Target should be valid.")
	
	var data: Variant = _target.interact(_interaction_args)
	interacted.emit(data)


func _reset() -> void:
	_current_time = _interaction_time
