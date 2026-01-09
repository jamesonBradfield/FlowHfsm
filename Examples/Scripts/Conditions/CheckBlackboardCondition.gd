class_name CheckBlackboardCondition extends StateCondition

@export var key: String = ""
@export var target_value: bool = true

func _evaluate(_actor: Node, blackboard: Dictionary) -> bool:
	return blackboard.get(key) == target_value
