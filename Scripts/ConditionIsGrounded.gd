class_name ConditionIsGrounded extends StateCondition

## Checks if the character is on the ground.
## Returns true if the actor is a CharacterBody3D and is_on_floor() is true.

func _evaluate(actor: Node, blackboard: Dictionary) -> bool:
	var body: CharacterBody3D = actor as CharacterBody3D
	if not body:
		push_warning("ConditionIsGrounded: Actor is not a CharacterBody3D")
		return false

	return body.is_on_floor()
