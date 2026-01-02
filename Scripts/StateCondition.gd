class_name StateCondition extends Resource

## THE ATOM
## Represents a single check like "Is Jump Pressed?" or "Is Health < 10".
## Returns true/false.

@export_group("Logic Modifiers")
@export var reverse_result: bool = false ## If true, this acts as a NOT gate.

# Virtual Function - Override this!
func _evaluate(actor: Node, blackboard: Dictionary) -> bool:
	return false

# Public Wrapper (Handles the "NOT" logic automatically)
func evaluate(actor: Node, blackboard: Dictionary) -> bool:
	var result = _evaluate(actor, blackboard)
	return not result if reverse_result else result
