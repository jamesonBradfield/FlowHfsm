@tool
class_name ConditionInput extends FlowCondition

## Checks if a specific input action is pressed.

@export var action: String = ""

func evaluate(_host: Node, data: Dictionary) -> bool:
	return bool(data.get("input/" + action, false))
