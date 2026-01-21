@tool
class_name FlowAnimationDriver
extends Resource

## Bridges a Smart Value to an AnimationTree parameter.

const FlowValueFloat = preload("res://addons/FlowHFSM/src/core/values/ValueFloat.gd")
const FlowValueVector2 = preload("res://addons/FlowHFSM/src/core/values/ValueVector2.gd")
const FlowValueBool = preload("res://addons/FlowHFSM/src/core/values/ValueBool.gd")

enum ValueType { FLOAT, VECTOR2, BOOL }

@export var parameter_path: String = "parameters/BlendSpace/blend_position"
@export var type: ValueType = ValueType.FLOAT:
	set(v):
		type = v
		notify_property_list_changed()

@export_group("Value Sources")
@export var value_float: FlowValueFloat = FlowValueFloat.new()
@export var value_vector2: FlowValueVector2 = FlowValueVector2.new()
@export var value_bool: FlowValueBool = FlowValueBool.new()

func _validate_property(property: Dictionary) -> void:
	if property.name == "value_float" and type != ValueType.FLOAT:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "value_vector2" and type != ValueType.VECTOR2:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "value_bool" and type != ValueType.BOOL:
		property.usage = PROPERTY_USAGE_NONE

func apply(actor: Node, blackboard: Object, anim_tree: AnimationTree) -> void:
	if not anim_tree: return
	
	var val: Variant
	match type:
		ValueType.FLOAT:
			if value_float: val = value_float.get_value(actor, blackboard)
		ValueType.VECTOR2:
			if value_vector2: val = value_vector2.get_value(actor, blackboard)
		ValueType.BOOL:
			if value_bool: val = value_bool.get_value(actor, blackboard)
			
	if val != null:
		anim_tree.set(parameter_path, val)
