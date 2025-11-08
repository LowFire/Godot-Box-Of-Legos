extends Area2D
class_name NodeRadar
## An object that uses an [Area2D] to detect any node that has a [Detectable] node attached to it.

## Emits any time the array of detected nodes is updated. This can either be when a detectable node
## enters the range of this [NodeRadar], leaves it, or it is freed or removed from the scene tree
## while in range of the radar. [param p_nodes] are the nodes currently detected.
signal detected_nodes_updated(p_nodes: Array[Node2D])

## A function predicate that can be used to filter out any nodes detected by the radar. Only nodes
## that pass the predicate function will be included as detected by the radar. If no predicate is
## specified, all detectable nodes are included.
var filter_function: Callable:
	get = _get_filter_function,
	set = _set_filter_function

var _filter_function: Callable = func(_p): return true
var _detected_nodes: Array[Node2D]


func _enter_tree() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)


func get_detected_nodes() -> Array[Node2D]:
	return _detected_nodes.duplicate()


func node_is_detected(p_node: Node2D) -> bool:
	return _detected_nodes.has(p_node)


func _get_filter_function() -> Callable:
	return _filter_function


func _set_filter_function(p_val: Callable) -> void:
	if not p_val:
		push_error("Cannot set filter function. Passed callable is null.")
		return
	
	_filter_function = p_val


func _on_area_entered(p_area: Area2D) -> void:
	if not p_area is Detectable:
		return
	
	var detectable := p_area as Detectable
	var owning_node = detectable.owning_node
	if not is_instance_valid(owning_node):
		push_warning("Owning node is not valid. Ignoring.")
		return
	
	assert(not _filter_function.is_null())
	var passed: bool = _filter_function.call(owning_node)
	if not passed:
		return
	
	owning_node.tree_exited.connect(_on_detected_node_exit_tree)
	_detected_nodes.append(owning_node)
	detected_nodes_updated.emit(_detected_nodes.duplicate())


func _on_area_exited(p_area: Area2D) -> void:
	if not p_area is Detectable:
		return
	var detectable := p_area as Detectable
	if not _detected_nodes.has(detectable.owning_node):
		return
	
	var owning_node: Node2D = detectable.owning_node
	owning_node.tree_exited.disconnect(_on_detected_node_exit_tree)
	_detected_nodes.erase(owning_node)
	detected_nodes_updated.emit(_detected_nodes.duplicate())


func _on_detected_node_exit_tree() -> void:
	# find the node that has exited and remove it.
	for node: Node2D in _detected_nodes:
		if not is_instance_valid(node): # sometimes it's due to the node being queue_freed
			_detected_nodes.erase(node)
			detected_nodes_updated.emit(_detected_nodes.duplicate())
			break
		
		if not node.is_inside_tree(): # not necessarily queue_freed
			node.tree_exited.disconnect(_on_detected_node_exit_tree)
			_detected_nodes.erase(node)
			detected_nodes_updated.emit(_detected_nodes.duplicate())
			break
