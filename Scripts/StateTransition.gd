class_name StateTransition extends Resource

## THE GATE
## Defines a set of conditions (Atomic Trigger). 
## Used by a State to determine if it should activate (Incoming) or by the Parent to check children.

enum Operation { AND, OR }

@export_group("Configuration")
## How to combine the conditions (AND = all must be true, OR = at least one must be true).
@export var operation: Operation = Operation.AND 

@export_group("Conditions")
## The list of conditions that must be met for this transition to trigger.
@export var conditions: Array[StateCondition]

## Checks if the transition should be triggered.
## Evaluates all conditions based on the configured operation (AND/OR).
##
## @param actor: The owner of the state machine.
## @param blackboard: Shared data dictionary.
## @return: True if the transition conditions are met.
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
