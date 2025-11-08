extends Node
class_name Interactable

## Handels interactions with a target node. Designed to be targeted by other [Interactor] instances.
## Interaction logic can be easily interchanged using [member interact_callable].

## Emitted when [method interact] is called. [param p_data] contains data about the interaction,
## if there is any. (Will be null otherwise.)
signal interacted(p_data: Variant)
## Emitted with this intractable is targeted by an interactor.
signal selected()
## Emitted when this interactable is no longer being targeted by an interactor.
signal deselected()

## A callable that defines the logic of how interactions with [member target] should happen.
var interact_callable: Callable:
	get:
		return _interact_callable
	set(p_val):
		_interact_callable = p_val

var _interact_callable: Callable
var _selected: bool


## Calls the interact function stored in [member interact_callable]. Also passes optional [param p_args],
## which are a set of aruments passed to [member interact_callable]
func interact(p_args: Array = []) -> Variant:
	if _interact_callable == null:
		push_error("Cannot interact. Interact callable is not set.")
		return
	if _interact_callable.is_null():
		push_error("Cannot interact. Interact callable is not valid.")
		return
	
	var ret: Variant = _interact_callable.callv(p_args)
	
	interacted.emit(ret)
	return ret


func is_selected() -> bool:
	return _selected


## Triggers this interactable to be "selected". Emits the [member selected] signal.
func select() -> void:
	_selected = true
	selected.emit()


## Triggers this interactable to be "deselected". Emits the [member deselcted] signal.
func deselect() -> void:
	_selected = false
	deselected.emit()
