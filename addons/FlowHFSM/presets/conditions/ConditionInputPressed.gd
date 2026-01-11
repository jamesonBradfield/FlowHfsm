@tool
class_name ConditionInputPressed extends StateCondition

## Checks if an input action is pressed.
## Can check a property on PlayerController OR query Input map directly.

enum Mode { PROPERTY, ACTION }

@export var mode: Mode = Mode.PROPERTY:
	set(v):
		mode = v
		notify_property_list_changed()

## Property name on the PlayerController (e.g. "jump_pressed").
@export var input_property: String = "jump_pressed"

## Input Action name (e.g. "ui_accept").
@export var action_name: String = "ui_accept"
## If true, checks is_action_just_pressed().
@export var just_pressed: bool = false

func _validate_property(property: Dictionary) -> void:
	if property.name == "input_property" and mode != Mode.PROPERTY:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "action_name" and mode != Mode.ACTION:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "just_pressed" and mode != Mode.ACTION:
		property.usage = PROPERTY_USAGE_NONE

func _evaluate(actor: Node, _blackboard: Blackboard) -> bool:
	match mode:
		Mode.PROPERTY:
			# Try to find the controller
			var controller = actor.get_node_or_null("PlayerController")
			if controller:
				var val = controller.get(input_property)
				if val == null: return false
				return val
				
			# Fallback: Check if actor itself has the property
			if actor:
				var val = actor.get(input_property)
				if val == null: return false
				return val
			return false
			
		Mode.ACTION:
			if just_pressed:
				return Input.is_action_just_pressed(action_name)
			else:
				return Input.is_action_pressed(action_name)
				
	return false
