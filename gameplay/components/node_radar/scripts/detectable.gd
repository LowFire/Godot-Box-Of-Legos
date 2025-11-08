extends Area2D
class_name Detectable

## The node that owns this detectable, or in other words, the node that is "detected".
@export var owning_node: Node2D:
	get:
		return _owning_node
	set(p_val):
		_owning_node = p_val

var _owning_node: Node2D
