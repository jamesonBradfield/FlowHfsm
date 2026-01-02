class_name ConditionMovement extends StateCondition

@export var threshold: float = 0.1

func _evaluate(_actor: Node, blackboard: Dictionary) -> bool:
	var input_dir = blackboard.get("input_dir", Vector2.ZERO)
	return input_dir.length_squared() > (threshold * threshold)
