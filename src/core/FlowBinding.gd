@tool
class_name FlowBinding extends Resource

## A resource that defines a binding to a property on a node, relative to an actor.

## The path to the node and property, relative to the actor.
## Example: ^"Camera3D:global_transform" or ^":move_input" (for actor's property)
@export var path: NodePath = ^""

## Retrieves the value from the actor based on the path.
func get_value(actor: Node) -> Variant:
	if path.is_empty():
		return null
		
	var target: Node = actor
	
	# Resolve the node if the path contains node names
	if path.get_name_count() > 0:
		# Create a NodePath with only the node names
		var node_path_str = ""
		for i in range(path.get_name_count()):
			if i > 0:
				node_path_str += "/"
			node_path_str += path.get_name(i)
		
		target = actor.get_node_or_null(NodePath(node_path_str))
		if not target:
			return null
			
	# Resolve the property if the path contains subnames
	if path.get_subname_count() > 0:
		var subpath_str = ":"
		for i in range(path.get_subname_count()):
			if i > 0:
				subpath_str += ":"
			subpath_str += path.get_subname(i)
			
		return target.get_indexed(NodePath(subpath_str))
		
	return target

## Sets the value on the actor based on the path.
func set_value(actor: Node, value: Variant) -> void:
	if path.is_empty():
		return
		
	var target: Node = actor
	
	# Resolve the node if the path contains node names
	if path.get_name_count() > 0:
		var node_path_str = ""
		for i in range(path.get_name_count()):
			if i > 0:
				node_path_str += "/"
			node_path_str += path.get_name(i)
		
		target = actor.get_node_or_null(NodePath(node_path_str))
		if not target:
			return
			
	# Resolve the property if the path contains subnames
	if path.get_subname_count() > 0:
		var subpath_str = ":"
		for i in range(path.get_subname_count()):
			if i > 0:
				subpath_str += ":"
			subpath_str += path.get_subname(i)
			
		target.set_indexed(NodePath(subpath_str), value)
