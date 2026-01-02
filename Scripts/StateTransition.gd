class_name StateTransition extends Resource

## THE GATE
## Connects the current state to a Target State if conditions are met.

enum Operation { AND, OR }

@export_group("Configuration")
@export var target_state: String = "" ## The name of the sibling/child node to switch to.
@export var operation: Operation = Operation.AND ## How to combine the conditions.

@export_group("Conditions")
@export var conditions: Array[StateCondition]

func is_triggered(actor: Node, blackboard: Dictionary) -> bool:
	# Safety check: If no conditions, never trigger (prevents infinite loops)
	if conditions.is_empty():
		return false

	match operation:
		Operation.AND:
			# ALL conditions must be true
			for condition in conditions:
				if not condition.evaluate(actor, blackboard):
					return false
			return true
			
		Operation.OR:
			# AT LEAST ONE condition must be true
			for condition in conditions:
				if condition.evaluate(actor, blackboard):
					return true
			return false
	
	return false
