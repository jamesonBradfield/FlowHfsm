class_name ConditionMovement extends StateCondition

## Checks if there is any movement input (Vector2 length > threshold).

## The minimum input magnitude required to consider it "moving".
@export var threshold: float = 0.1

func _evaluate(_actor: Node, blackboard: Dictionary) -> bool:
	# Check for direct input if blackboard is missing it
	var input_dir = Vector2.ZERO
	if blackboard.has("input_dir"):
		input_dir = blackboard["input_dir"]
	else:
		input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		
	return input_dir.length_squared() > (threshold * threshold)
