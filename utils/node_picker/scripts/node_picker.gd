extends Node
class_name NodePicker
## Class that is used to pick from an array of nodes. Useful for mainly selecting spawn points,
## or to pick from any variety of node types if desired.

## Emits when all nodes tracked by this picker have been picked at least once.
signal all_nodes_picked()
## Emits when the picker is reset by caling [method reset].
signal resetted()

## The picking method determins how nodes are picked. [enum PickingMethod.FORWARD] selects nodes
## in order of front to back. [enum PickingMethod.REVERSE] picks nodes in order from back to front.
## [enum PickingMethod.RANDOM] picks nodes in a random order, but never picks the same one twice.
## [enum PickingMethod.RANDOM_INDISCRIMINATE] Does the same as [enum PickingMethod.RANDOM], except
## that it will not exclude nodes that were already picked (this means that [member end_reached]
## will never emit.)
enum PickingMethod { FORWARD, REVERSE, RANDOM, RANDOM_INDISCRIMINATE, }

## The pool of nodes that this [NodePicker] will pick from.
@export var nodes: Array[Node]:
	get = _get_nodes,
	set = _set_nodes

## What picking method to use when picking nodes. See [enum PickingMethod].
@export var picking_method: PickingMethod:
	get = _get_picking_method,
	set = _set_picking_method

var _nodes: Array[Node]
var _picking_method: PickingMethod
var _picked: Array[Node]
var _all_nodes_picked: bool


## Picks a node according to the [enum PickingMethod] and returns it. Will return [null] if all nodes
## have been picked aready. Call [method reset] to reset the picked nodes so that all nodes
## will be marked as unpicked. If this picker has no pool of nodes to pick from, it will return null.
func pick() -> Node:
	if _nodes.is_empty():
		return null
	if _all_nodes_picked:
		return null
	
	var ret: Node
	match _picking_method:
		PickingMethod.FORWARD:
			ret = _get_next_node_forward()
			_picked.append(ret)
		PickingMethod.REVERSE:
			ret = _get_next_node_reverse()
			_picked.append(ret)
		PickingMethod.RANDOM:
			ret = _get_next_node_random()
			_picked.append(ret)
		PickingMethod.RANDOM_INDISCRIMINATE:
			ret = _get_next_node_random_indiscriminate()
	
	if _picked.size() == _nodes.size():
		_all_nodes_picked = true
		all_nodes_picked.emit()
	
	return ret

## Retunes whether [param p_node] is contained in the pool of nodes that this [NodePicker] picks
## from.
func contains_node(p_node: Node) -> bool:
	return _nodes.has(p_node)

## Resets this [NodePicker], which means all the nodes in it's picking pool will be reset back to being
## unpicked.
func reset() -> void:
	_picked.clear()
	resetted.emit()

## Returns an array of all the nodes that have not been picked yet since the last reset.
func get_not_picked() -> Array[Node]:
	var ret: Array[Node]
	for node: Node in _nodes:
		if node in _picked:
			continue
		
		ret.append(node)
	
	return ret

## Returns if all nodes in the picking pool have been picked at least once.
func is_all_nodes_picked() -> bool:
	return _all_nodes_picked


## Returns an array of nodes that have been picked since the last reset.
func get_picked() -> Array[Node]:
	return _picked.duplicate()

## Returns if [param p_node] has already been picked. Will return false if [p_node] is not in the
## picking pool.
func is_picked(p_node: Node) -> bool:
	return _picked.has(p_node)


func _set_picking_method(p_val: PickingMethod) -> void:
	_picking_method = p_val
	reset()


func _get_picking_method() -> PickingMethod:
	return _picking_method


func _set_nodes(p_val: Array[Node]) -> void:
	_nodes = p_val.duplicate()
	for node in _nodes:
		node.tree_exited.connect(_on_node_tree_exited)
	reset()


func _get_nodes() -> Array[Node]:
	return _nodes.duplicate()


func _get_next_node_forward() -> Node:
	assert(_nodes.size() >= _picked.size(), "Picked array size should be smaller than the node array.")
	return _nodes[_picked.size()]


func _get_next_node_reverse() -> Node:
	assert(_nodes.size() >= _picked.size(), "Picked array size should be smaller than the node array.")
	return _nodes[_nodes.size() - _picked.size() - 1]


func _get_next_node_random() -> Node:
	var picking_pool: Array[Node] = _nodes.duplicate()
	for node: Node in _picked:
		assert(picking_pool.has(node))
		picking_pool.erase(node)
	
	var index := randi_range(0, picking_pool.size() - 1)
	return picking_pool[index]


func _get_next_node_random_indiscriminate() -> Node:
	var index := randi_range(0, _nodes.size() - 1)
	return _nodes[index]


func _on_node_tree_exited() -> void:
	# Find the node that exited
	for node in _nodes:
		if is_instance_valid(node) and node.is_inside_tree():
			continue
		
		_nodes.erase(node)
		
		if is_instance_valid(node): # The node is valid, but not in the scene tree.
			node.tree_exited.disconnect(_on_node_tree_exited)
		
		if _picked.has(node):
			_picked.erase(node)
