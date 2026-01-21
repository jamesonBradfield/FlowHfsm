@tool
class_name ConditionBoolCmp extends StateCondition

## Generic boolean comparison condition.
## Replaces custom conditions like IsGrounded, IsDead, HasKey, etc.
## Use this for: IsGrounded == true, IsDead == true, HasKey == false.
## Note: Can also use ConditionBoolCmp.reverse_result for inverted checks.

@export var value: ValueBool
@export var target_state: bool = true

func _evaluate(actor: Node, blackboard: Blackboard) -> bool:
	if not value:
		push_warning("ConditionBoolCmp: ValueBool resource must be assigned")
		return false

	return value.get_value(actor, blackboard) == target_state
