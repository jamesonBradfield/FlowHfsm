@tool
class_name ConditionCheck extends FlowCondition

## Generic condition. Checks any key in the shared data dict for truthiness.

@export var data_key: String = ""
@export var invert: bool = false

func evaluate(_host: Node, data: Dictionary) -> bool:
	var result = bool(data.get(data_key, false))
	return not result if invert else result
