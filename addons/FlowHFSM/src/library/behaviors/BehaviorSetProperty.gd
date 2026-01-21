@tool
class_name BehaviorSetProperty extends FlowBehavior

## Generic property setter behavior.
## Sets arbitrary properties on any node in the scene without custom code.

@export var node_path: NodePath = NodePath("..")
@export var property: String = ""

# Uses Global Class Names directly (No preloads needed)
@export var value_float: FlowValueFloat
@export var value_bool: FlowValueBool
@export var value_vector3: FlowValueVector3

func enter(_state: Node, actor: Node, blackboard: FlowBlackboard) -> void:
	if property.is_empty():
		push_warning("BehaviorSetProperty: Property name is empty")
		return

	var target: Node = actor.get_node_or_null(node_path)
	if not target:
		push_warning("BehaviorSetProperty: Cannot find node at path: " + str(node_path))
		return

	# Try to set property based on available value resource
	# We check strictly for non-null resources
	if value_float:
		target.set(property, value_float.get_value(actor, blackboard))
	elif value_bool:
		target.set(property, value_bool.get_value(actor, blackboard))
	elif value_vector3:
		target.set(property, value_vector3.get_value(actor, blackboard))
	else:
		push_warning("BehaviorSetProperty: No value resource assigned for property: " + property)
