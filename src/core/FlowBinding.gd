@tool
class_name FlowBinding extends Resource

## A binding that resolves a value from the actor or a custom resolver.
## Used by FlowDataMap to build the data context each frame.

enum Source { PATH, RESOLVER }

@export var source: Source = Source.PATH

## PATH mode: resolve a node/property relative to the actor.
## Example: ^"Camera3D:global_transform" or ^":move_input"
@export var path: NodePath = ^""

## RESOLVER mode: delegate to a custom script for complex logic.
@export var resolver: FlowResolver

## Resolves the value for this binding.
## @param actor: The owner of the state machine.
## @param context: Already-resolved entries (available for resolver chaining).
func get_value(actor: Node, context: Dictionary = {}) -> Variant:
	match source:
		Source.PATH:
			return _resolve_path(actor)
		Source.RESOLVER:
			if resolver:
				return resolver.resolve(actor, context)
	return null

func _resolve_path(actor: Node) -> Variant:
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
