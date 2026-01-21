@tool
class_name ValueFloat
extends Resource

enum Mode {
	CONSTANT,
	BLACKBOARD,
	PROPERTY
}

@export var mode: Mode = Mode.CONSTANT:
	set(v):
		mode = v
		notify_property_list_changed()

@export var value: float = 0.0
@export var blackboard_key: String = ""
@export var node_path: NodePath = NodePath("")
@export var property_name: String = ""

var _cached_node: Node

func _validate_property(property: Dictionary) -> void:
	if property.name == "value" and mode != Mode.CONSTANT:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "blackboard_key" and mode != Mode.BLACKBOARD:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "node_path" and mode != Mode.PROPERTY:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "property_name" and mode != Mode.PROPERTY:
		property.usage = PROPERTY_USAGE_NONE

## Returns the float value based on the current mode.
## [param actor] is the node executing the behavior (context).
## [param blackboard] is the shared blackboard for the state machine.
func get_value(actor: Node, blackboard: Object) -> float:
	match mode:
		Mode.CONSTANT:
			return value
		Mode.BLACKBOARD:
			if blackboard and blackboard.has_method("get_value"):
				var result = blackboard.get_value(blackboard_key)
				if result is float or result is int:
					return float(result)
			return 0.0
		Mode.PROPERTY:
			if not actor or node_path.is_empty() or property_name.is_empty():
				return 0.0
			
			if not is_instance_valid(_cached_node):
				_cached_node = actor.get_node_or_null(node_path)
				if not _cached_node:
					return 0.0
			
			var result = _cached_node.get(property_name)
			if result is float or result is int:
				return float(result)
			return 0.0
	
	return 0.0
