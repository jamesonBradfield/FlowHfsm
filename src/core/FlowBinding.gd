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
	var node_path := path.get_concatenated_names()
	
	if not node_path.is_empty():
		target = actor.get_node_or_null(NodePath(node_path))
		if not target:
			return null
			
	var sub_path := path.get_concatenated_subnames()
	if not sub_path.is_empty():
		return target.get_indexed(NodePath(sub_path))
		
	return target

## Sets the value on the actor based on the path.
func set_value(actor: Node, value: Variant) -> void:
	if path.is_empty():
		return
		
	var target: Node = actor
	var node_path := path.get_concatenated_names()
	
	if not node_path.is_empty():
		target = actor.get_node_or_null(NodePath(node_path))
		if not target:
			return
			
	var sub_path := path.get_concatenated_subnames()
	if not sub_path.is_empty():
		target.set_indexed(NodePath(sub_path), value)
