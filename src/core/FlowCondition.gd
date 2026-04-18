@tool
class_name FlowCondition extends Resource

## THE ATOM
## Represents a single check like "Is Jump Pressed?" or "Is Health < 10".
## Returns true/false.
##
## Conditions receive a context dict (pushed from FlowDataMap)
## instead of pulling data from actor properties.

@export_group("Logic Modifiers")
## If true, this acts as a NOT gate, reversing the result of the condition.
@export var reverse_result: bool = false 

# Virtual Function - Override this!

## Internal evaluation function. Override this in subclasses.
## @param actor: The owner of the state machine.
## @param context: The data context pushed down from the actor's FlowDataMap.
func _evaluate(actor: Node, context: Dictionary[StringName, Variant] = {}) -> bool:
	return false

# Public Wrapper (Handles the "NOT" logic automatically)

## Evaluates the condition, applying the `reverse_result` modifier if set.
func evaluate(actor: Node, context: Dictionary[StringName, Variant] = {}) -> bool:
	var result: bool = _evaluate(actor, context)
	return not result if reverse_result else result
