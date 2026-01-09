class_name StateCondition extends Resource

## THE ATOM
## Represents a single check like "Is Jump Pressed?" or "Is Health < 10".
## Returns true/false.

@export_group("Logic Modifiers")
## If true, this acts as a NOT gate, reversing the result of the condition.
@export var reverse_result: bool = false 

# Virtual Function - Override this!

## Internal evaluation function. Override this in subclasses.
##
## @param actor: The owner of the state machine.
## @return: The raw result of the condition check.
func _evaluate(actor: Node) -> bool:
	return false

# Public Wrapper (Handles the "NOT" logic automatically)

## Evaluates the condition, applying the `reverse_result` modifier if set.
##
## @param actor: The owner of the state machine.
## @return: The final result of the condition.
func evaluate(actor: Node) -> bool:
	var result: bool = _evaluate(actor)
	return not result if reverse_result else result
