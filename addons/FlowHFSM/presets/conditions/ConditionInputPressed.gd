class_name ConditionInputPressed extends StateCondition

## Checks if an input action is pressed.
## Returns true if the input action in blackboard is true.

@export_group("Input Settings")
## Blackboard key for the input action.
## Example: "jump_pressed", "attack_pressed", "dodge_pressed"
@export var blackboard_key: String = "jump_pressed"

func _evaluate(actor: Node, blackboard: Dictionary) -> bool:
	var input_pressed: bool = blackboard.get(blackboard_key, false)
	return input_pressed
