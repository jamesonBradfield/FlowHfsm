class_name ConditionInput extends StateCondition

@export var action_name: String = "ui_accept"
@export var required_state: bool = true

func _evaluate(_actor: Node, blackboard: Dictionary) -> bool:
	# We assume PlayerController puts inputs into blackboard["inputs"]
	# Structure: blackboard = { "inputs": { "jump": true, "fire": false } }
	
	var inputs = blackboard.get("inputs", {})
	var is_pressed = inputs.get(action_name, false)
	
	return is_pressed == required_state
