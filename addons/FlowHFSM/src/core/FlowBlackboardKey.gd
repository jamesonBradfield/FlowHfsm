@tool
class_name FlowBlackboardKey extends Resource

## DEFINITION OF A BLACKBOARD ENTRY
## Enforces type safety and provides default values for Blackboard entries.

@export var key_name: String = ""
@export var key_type: Variant.Type = TYPE_NIL
@export var default_value: Variant = null

func _init(p_name: String = "", p_type: Variant.Type = TYPE_NIL, p_default: Variant = null) -> void:
	key_name = p_name
	key_type = p_type
	default_value = p_default
