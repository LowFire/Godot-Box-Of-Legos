extends Resource
class_name Effect

## Abstract class. Base for all effect types.

## Virtual method. Override this to determine how this effect will apply
## its afflictions to the target node.
func afflict(p_target: Node) -> void:
	pass
