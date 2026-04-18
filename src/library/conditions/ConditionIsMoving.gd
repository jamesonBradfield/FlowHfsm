@tool
class_name ConditionIsMoving extends FlowCondition

## Checks if the character is moving.
## Checks "is_moving" property (bool) or "move_input" (Vector3) magnitude.

@export_group("Dependency Injection")
@export var is_moving_binding: FlowBinding
@export var move_input_binding: FlowBinding

func _init() -> void:
	if not is_moving_binding:
		is_moving_binding = FlowBinding.new()
		is_moving_binding.path = ^":is_moving"
	if not move_input_binding:
		move_input_binding = FlowBinding.new()
		move_input_binding.path = ^":move_input"

@export_group("Threshold Settings")
## Minimum input magnitude to consider as "moving".
@export var input_threshold: float = 0.1

func _evaluate(actor: Node) -> bool:
	# 1. Check explicit flag
	if is_moving_binding:
		var val = is_moving_binding.get_value(actor)
		if val is bool and val:
			return true
	
	# 2. Check Input Vector
	var move_dir: Vector3 = Vector3.ZERO
	if move_input_binding:
		var val = move_input_binding.get_value(actor)
		if val is Vector3:
			move_dir = val
		
	return move_dir.length_squared() > (input_threshold * input_threshold)
