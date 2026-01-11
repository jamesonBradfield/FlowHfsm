@tool
class_name StateFloat extends Resource

## A float value that can be constant or read from the Blackboard.

enum Mode { CONSTANT, BLACKBOARD }

@export var mode: Mode = Mode.CONSTANT:
	set(v):
		mode = v
		notify_property_list_changed()

@export var constant_value: float = 0.0
@export var blackboard_key: String = ""

func _validate_property(property: Dictionary) -> void:
	if property.name == "constant_value" and mode != Mode.CONSTANT:
		property.usage = PROPERTY_USAGE_NONE
	if property.name == "blackboard_key" and mode != Mode.BLACKBOARD:
		property.usage = PROPERTY_USAGE_NONE

func get_value(blackboard: Blackboard, default: float = 0.0) -> float:
	match mode:
		Mode.CONSTANT:
			return constant_value
		Mode.BLACKBOARD:
			if blackboard and blackboard.has_value(blackboard_key):
				var v = blackboard.get_value(blackboard_key)
				if v is float or v is int:
					return float(v)
	return default
