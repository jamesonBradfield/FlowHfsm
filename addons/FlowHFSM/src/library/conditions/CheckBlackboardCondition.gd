class_name CheckBlackboardCondition extends FlowCondition

## Checks a value in the Blackboard.

@export var key: String = ""
@export var target_value: bool = true

func _evaluate(actor: Node, blackboard: FlowBlackboard) -> bool:
	if not blackboard:
		return false
	
	var actual = blackboard.get_value(key)
	
	# Handle cases where key doesn't exist (assume false/null)
	if actual == null:
		return false
		
	return actual == target_value
