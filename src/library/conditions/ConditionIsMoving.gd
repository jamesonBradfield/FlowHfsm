@tool
class_name ConditionIsMoving extends FlowCondition

## Checks if the character is moving.
## Reads "is_moving" (bool) or "move_input" (Vector3) from context.

@export_group("Context Keys")
@export var is_moving_key: StringName = &"is_moving"
@export var move_input_key: StringName = &"move_input"

@export_group("Threshold Settings")
@export var input_threshold: float = 0.1

func _evaluate(actor: Node, context: Dictionary[StringName, Variant] = {}) -> bool:
	# 1. Check explicit flag
	if context.has(is_moving_key):
		var val = context[is_moving_key]
		if val is bool and val:
			return true
	
	# 2. Check Input Vector
	var move_dir: Vector3 = Vector3.ZERO
	if context.has(move_input_key):
		var val = context[move_input_key]
		if val is Vector3:
			move_dir = val
		
	return move_dir.length_squared() > (input_threshold * input_threshold)
