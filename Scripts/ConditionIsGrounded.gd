class_name ConditionIsGrounded extends StateCondition

## Checks if the actor is on the ground (using CharacterBody2D/3D is_on_floor).

func _evaluate(actor: Node, _blackboard: Dictionary) -> bool:
	if actor is CharacterBody3D or actor is CharacterBody2D:
		return actor.is_on_floor()
	
	# Also check blackboard if physics state is cached there
	if _blackboard.has("is_on_floor"):
		return _blackboard["is_on_floor"]
		
	return false # Default to false - explicit is better than implicit for grounding
