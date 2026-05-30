@tool
class_name ConditionIsMoving extends FlowCondition

## Checks if any movement input is pressed.

@export var actions: Array[String] = ["move_left", "move_right", "move_up", "move_down"]

func evaluate(_host: Node, data: Dictionary) -> bool:
	for action in actions:
		if data.get("input/" + action, false):
			return true
	return false
