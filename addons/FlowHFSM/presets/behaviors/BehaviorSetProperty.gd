@tool
class_name BehaviorSetProperty extends StateBehavior

## Generic property setter behavior.
## Sets arbitrary properties on any node in the scene without custom code.
## Replaces behaviors like Roll, Dash, and other property-modifying behaviors.

@export var node_path: NodePath = NodePath("..")
@export var property: String = ""
@export var value_float: ValueFloat
@export var value_bool: ValueBool

const ValueVector3 = preload("res://addons/FlowHFSM/runtime/values/ValueVector3.gd")

@export var value_vector3: ValueVector3

func enter(node: RecursiveState, actor: Node, blackboard: Blackboard) -> void:
	if property.is_empty():
		push_warning("BehaviorSetProperty: Property name is empty")
		return

	var target: Node = actor.get_node_or_null(node_path)
	if not target:
		push_warning("BehaviorSetProperty: Cannot find node at path: " + str(node_path))
		return

	# Try to set property based on available value resource
	if value_float:
		target.set(property, value_float.get_value(actor, blackboard))
	elif value_bool:
		target.set(property, value_bool.get_value(actor, blackboard))
	elif value_vector3:
		target.set(property, value_vector3.get_value(actor, blackboard))
	else:
		push_warning("BehaviorSetProperty: No value resource assigned")
