class_name ConditionIsGrounded extends StateCondition

func _evaluate(actor: Node, _blackboard: Dictionary) -> bool:
	if actor is CharacterBody3D or actor is CharacterBody2D:
		return actor.is_on_floor()
	return true # Default to true if not a physics body to avoid locking
