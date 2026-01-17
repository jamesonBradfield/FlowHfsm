@tool
class_name ConditionFloatCmp extends StateCondition

## Generic float comparison condition.
## Replaces custom conditions like IsMoving, HealthLow, DistanceThreshold, etc.
## Use this for: Speed > 0.1, Health < 50, Distance < 10.

enum Operator {
	GREATER,
	LESS,
	EQUAL,
	GREATER_EQUAL,
	LESS_EQUAL
}

@export var value_a: ValueFloat
@export var operator: Operator = Operator.GREATER
@export var value_b: ValueFloat

func _evaluate(actor: Node, blackboard: Blackboard) -> bool:
	if not value_a or not value_b:
		push_warning("ConditionFloatCmp: Both ValueFloat resources must be assigned")
		return false

	var a: float = value_a.get_value(actor, blackboard)
	var b: float = value_b.get_value(actor, blackboard)

	match operator:
		Operator.GREATER:
			return a > b
		Operator.LESS:
			return a < b
		Operator.EQUAL:
			return is_equal_approx(a, b)
		Operator.GREATER_EQUAL:
			return a >= b
		Operator.LESS_EQUAL:
			return a <= b

	return false
