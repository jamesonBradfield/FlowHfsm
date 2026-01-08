class_name ConditionIsMoving extends StateCondition

## Checks if the character is moving.
## Returns true if input_direction in blackboard has magnitude > threshold.

@export_group("Threshold Settings")
## Minimum input magnitude to consider as "moving".
@export var input_threshold: float = 0.1
## Blackboard key to check for movement direction.
@export var blackboard_key: String = "input_direction"

func _evaluate(actor: Node, blackboard: Dictionary) -> bool:
	var move_dir: Vector3 = blackboard.get(blackboard_key, Vector3.ZERO)
	return move_dir.length() > input_threshold
